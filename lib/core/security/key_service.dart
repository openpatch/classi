import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

const String securityMetadataSuffix = '.security.json';
const String integrityManifestSuffix = '.integrity.json';

class KeyService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    wOptions: WindowsOptions(),
  );

  static const String _legacyStorageKey = 'db_passphrase';
  static const String _biometricPassphrasePrefix = 'biometric.passphrase.';
  static const int _defaultIterations = 310000;
  static const int _defaultKeyBytes = 32;
  static const int _saltBytes = 16;
  static const int _nonceBytes = 12;
  static const String _recoveryAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<bool> hasSecuritySetup(File dbFile) => _metadataFile(dbFile).exists();

  Future<bool> hasRecoveryKey(File dbFile) async {
    final metadata = await _readMetadata(dbFile);
    return metadata?.supportsRecovery ?? false;
  }

  Future<String?> getLegacyPassphrase() =>
      _storage.read(key: _legacyStorageKey);

  Future<void> clearLegacyPassphrase() =>
      _storage.delete(key: _legacyStorageKey);

  String _biometricPassphraseKey(File dbFile) =>
      '$_biometricPassphrasePrefix${dbFile.path}';

  /// Stores [passphrase] in secure storage so that a successful biometric
  /// authentication can retrieve it and unlock the database without re-typing.
  Future<void> saveBiometricPassphrase(File dbFile, String passphrase) =>
      _storage.write(
        key: _biometricPassphraseKey(dbFile),
        value: passphrase,
      );

  /// Returns the passphrase previously saved for biometric unlock, or `null`
  /// when none has been stored.
  Future<String?> getBiometricPassphrase(File dbFile) =>
      _storage.read(key: _biometricPassphraseKey(dbFile));

  /// Removes the stored biometric passphrase for [dbFile].
  Future<void> clearBiometricPassphrase(File dbFile) =>
      _storage.delete(key: _biometricPassphraseKey(dbFile));

  static const String _webDavPasswordKey = 'backup.webdav_password';

  /// Returns the stored WebDAV password, or `null` if none has been set.
  Future<String?> getWebDavPassword() =>
      _storage.read(key: _webDavPasswordKey);

  /// Stores the WebDAV password in secure storage.
  Future<void> setWebDavPassword(String password) =>
      _storage.write(key: _webDavPasswordKey, value: password);

  /// Removes the stored WebDAV password.
  Future<void> clearWebDavPassword() =>
      _storage.delete(key: _webDavPasswordKey);

  Future<SecurityBootstrapResult> bootstrapSecurity({
    required File dbFile,
    required String passphrase,
    bool includeRecoveryKey = true,
    int iterations = _defaultIterations,
    int keyBytes = _defaultKeyBytes,
    int saltBytes = _saltBytes,
  }) async {
    final metadataFile = _metadataFile(dbFile);
    if (await metadataFile.exists()) {
      return const SecurityBootstrapResult();
    }

    await metadataFile.parent.create(recursive: true);
    final package = includeRecoveryKey
        ? await SecurityBootstrapPackage.createRecoverable(
            passphrase: passphrase,
            iterations: iterations,
            keyBytes: keyBytes,
            saltBytes: saltBytes,
          )
        : await SecurityBootstrapPackage.createLegacy(
            passphrase: passphrase,
            iterations: iterations,
            keyBytes: keyBytes,
            saltBytes: saltBytes,
          );
    await metadataFile.writeAsString(
      jsonEncode(package.metadata.toJson()),
      flush: true,
    );
    return SecurityBootstrapResult(recoveryKey: package.recoveryKey);
  }

  Future<bool> verifyPassphrase({
    required File dbFile,
    required String passphrase,
  }) async {
    final metadata = await _readMetadata(dbFile);
    if (metadata == null) {
      return false;
    }

    if (!metadata.supportsRecovery) {
      final derivedVerifier = await _deriveKeyBytes(
        secret: passphrase,
        salt: metadata.verifierSalt!,
        iterations: metadata.iterations,
        keyBytes: metadata.keyBytes,
      );
      return _constantTimeEquals(derivedVerifier, metadata.verifierBytes!);
    }

    final derivedVerifier = await _deriveKeyBytes(
      secret: passphrase,
      salt: metadata.passphraseSalt!,
      iterations: metadata.iterations,
      keyBytes: metadata.keyBytes,
    );
    return _constantTimeEquals(derivedVerifier, metadata.passphraseVerifier!);
  }

  Future<bool> verifyRecoveryKey({
    required File dbFile,
    required String recoveryKey,
  }) async {
    final metadata = await _readMetadata(dbFile);
    if (metadata == null || !metadata.supportsRecovery) {
      return false;
    }

    final normalizedKey = normalizeRecoveryKey(recoveryKey);
    final derivedVerifier = await _deriveKeyBytes(
      secret: normalizedKey,
      salt: metadata.recoverySalt!,
      iterations: metadata.iterations,
      keyBytes: metadata.keyBytes,
    );
    return _constantTimeEquals(derivedVerifier, metadata.recoveryVerifier!);
  }

  Future<String> deriveDatabaseKey({
    required File dbFile,
    required String passphrase,
  }) async {
    final metadata = await _requireMetadata(dbFile);
    if (!metadata.supportsRecovery) {
      final bytes = await _deriveKeyBytes(
        secret: passphrase,
        salt: metadata.databaseSalt!,
        iterations: metadata.iterations,
        keyBytes: metadata.keyBytes,
      );
      return base64Encode(bytes);
    }

    return base64Encode(
      await _unwrapDatabaseKeyWithPassphrase(
        metadata: metadata,
        passphrase: passphrase,
      ),
    );
  }

  Future<String> deriveDatabaseKeyWithRecoveryKey({
    required File dbFile,
    required String recoveryKey,
  }) async {
    final metadata = await _requireMetadata(dbFile);
    if (!metadata.supportsRecovery) {
      throw StateError('Recovery keys are not available for this database.');
    }

    return base64Encode(
      await _unwrapDatabaseKeyWithRecoveryKey(
        metadata: metadata,
        recoveryKey: recoveryKey,
      ),
    );
  }

  Future<String> rotateSecurity({
    required File dbFile,
    required String currentPassphrase,
    required String newPassphrase,
  }) async {
    final metadata = await _requireMetadata(dbFile);
    if (!metadata.supportsRecovery) {
      final nextMetadata = await SecurityMetadata.createLegacy(
        passphrase: newPassphrase,
        iterations: _defaultIterations,
        keyBytes: _defaultKeyBytes,
        saltBytes: _saltBytes,
      );
      await _metadataFile(
        dbFile,
      ).writeAsString(jsonEncode(nextMetadata.toJson()), flush: true);
      return base64Encode(
        await _deriveKeyBytes(
          secret: newPassphrase,
          salt: nextMetadata.databaseSalt!,
          iterations: nextMetadata.iterations,
          keyBytes: nextMetadata.keyBytes,
        ),
      );
    }

    final databaseKey = await _unwrapDatabaseKeyWithPassphrase(
      metadata: metadata,
      passphrase: currentPassphrase,
    );
    final nextMetadata = await metadata.copyWithNewPassphrase(
      newPassphrase: newPassphrase,
      databaseKey: databaseKey,
    );
    await _metadataFile(
      dbFile,
    ).writeAsString(jsonEncode(nextMetadata.toJson()), flush: true);
    return base64Encode(databaseKey);
  }

  Future<String?> recoverPassphrase({
    required File dbFile,
    required String recoveryKey,
    required String newPassphrase,
  }) async {
    final metadata = await _requireMetadata(dbFile);
    if (!metadata.supportsRecovery) {
      return null;
    }

    final databaseKey = await _unwrapDatabaseKeyWithRecoveryKey(
      metadata: metadata,
      recoveryKey: recoveryKey,
    );
    final nextMetadata = await metadata.copyWithNewPassphrase(
      newPassphrase: newPassphrase,
      databaseKey: databaseKey,
    );
    await _metadataFile(
      dbFile,
    ).writeAsString(jsonEncode(nextMetadata.toJson()), flush: true);
    return base64Encode(databaseKey);
  }

  Future<bool> validateIntegrity({
    required File dbFile,
    String? passphrase,
    String? recoveryKey,
    required bool allowRepair,
  }) async {
    final manifestFile = _integrityManifestFile(dbFile);
    if (!await manifestFile.exists()) {
      return true;
    }

    final manifest = await _readManifest(dbFile);
    if (manifest == null) {
      return allowRepair;
    }

    final currentHashes = await _computeArtifactHashes(
      dbFile: dbFile,
      passphrase: passphrase,
      recoveryKey: recoveryKey,
    );
    final matches = mapEquals(
      _normalizeManifestHashes(manifest.fileHashes),
      currentHashes,
    );
    return matches || allowRepair;
  }

  Future<void> writeIntegrityManifest({
    required File dbFile,
    String? passphrase,
    String? recoveryKey,
  }) async {
    final manifest = IntegrityManifest(
      fileHashes: await _computeArtifactHashes(
        dbFile: dbFile,
        passphrase: passphrase,
        recoveryKey: recoveryKey,
      ),
      updatedAt: DateTime.now().toUtc(),
    );
    await _integrityManifestFile(
      dbFile,
    ).writeAsString(jsonEncode(manifest.toJson()), flush: true);
  }

  Future<List<String>> securityArtifactPaths(File dbFile) async {
    final metadataFile = _metadataFile(dbFile);
    final manifestFile = _integrityManifestFile(dbFile);
    return [
      dbFile.path,
      '${dbFile.path}-wal',
      '${dbFile.path}-shm',
      metadataFile.path,
      manifestFile.path,
    ];
  }

  File metadataFileFor(File dbFile) => _metadataFile(dbFile);

  File integrityManifestFileFor(File dbFile) => _integrityManifestFile(dbFile);

  String normalizeRecoveryKey(String recoveryKey) {
    return recoveryKey.toUpperCase().replaceAll(RegExp(r'[^A-Z2-9]'), '');
  }

  Future<Map<String, String>> _computeArtifactHashes({
    required File dbFile,
    String? passphrase,
    String? recoveryKey,
  }) async {
    final integrityKey = await _resolveIntegrityKey(
      dbFile: dbFile,
      passphrase: passphrase,
      recoveryKey: recoveryKey,
    );
    final hashFiles = <File>[dbFile, _metadataFile(dbFile)];
    final hashes = <String, String>{};
    for (final file in hashFiles) {
      if (!await file.exists()) {
        continue;
      }
      hashes[p.basename(file.path)] = await _hmacFile(file, integrityKey);
    }
    return hashes;
  }

  Future<List<int>> _resolveIntegrityKey({
    required File dbFile,
    String? passphrase,
    String? recoveryKey,
  }) async {
    final metadata = await _requireMetadata(dbFile);
    if (!metadata.supportsRecovery) {
      if (passphrase == null) {
        throw StateError('A passphrase is required for integrity checks.');
      }
      return _deriveKeyBytes(
        secret: passphrase,
        salt: metadata.integritySalt!,
        iterations: metadata.iterations,
        keyBytes: metadata.keyBytes,
      );
    }

    final databaseKey = passphrase != null
        ? await _unwrapDatabaseKeyWithPassphrase(
            metadata: metadata,
            passphrase: passphrase,
          )
        : await _unwrapDatabaseKeyWithRecoveryKey(
            metadata: metadata,
            recoveryKey: recoveryKey ?? '',
          );
    return _deriveIntegrityKeyFromDatabaseKey(databaseKey);
  }

  Future<List<int>> _deriveIntegrityKeyFromDatabaseKey(
    List<int> databaseKey,
  ) async {
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode('classi-integrity'),
      secretKey: SecretKey(databaseKey),
    );
    return mac.bytes;
  }

  Future<String> _hmacFile(File file, List<int> integrityKey) async {
    final bytes = await file.readAsBytes();
    final mac = await Hmac.sha256().calculateMac(
      bytes,
      secretKey: SecretKey(integrityKey),
    );
    return base64Encode(mac.bytes);
  }

  Map<String, String> _normalizeManifestHashes(Map<String, String> hashes) {
    return Map<String, String>.fromEntries(
      hashes.entries.where(
        (entry) => !entry.key.endsWith('-wal') && !entry.key.endsWith('-shm'),
      ),
    );
  }

  Future<SecurityMetadata?> _readMetadata(File dbFile) async {
    final file = _metadataFile(dbFile);
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    return SecurityMetadata.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<SecurityMetadata> _requireMetadata(File dbFile) async {
    final metadata = await _readMetadata(dbFile);
    if (metadata == null) {
      throw StateError('Security metadata is missing.');
    }
    return metadata;
  }

  Future<IntegrityManifest?> _readManifest(File dbFile) async {
    final file = _integrityManifestFile(dbFile);
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    return IntegrityManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<int>> _deriveKeyBytes({
    required String secret,
    required List<int> salt,
    required int iterations,
    required int keyBytes,
  }) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: keyBytes * 8,
    );
    final secretKey = await algorithm.deriveKeyFromPassword(
      password: secret,
      nonce: salt,
    );
    return secretKey.extractBytes();
  }

  Future<_WrappedSecret> _wrapSecret({
    required List<int> payload,
    required String secret,
    required List<int> salt,
    required int iterations,
    required int keyBytes,
  }) async {
    final wrappingKey = await _deriveKeyBytes(
      secret: secret,
      salt: salt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    final secretBox = await AesGcm.with256bits().encrypt(
      payload,
      secretKey: SecretKey(wrappingKey),
      nonce: _randomBytes(_nonceBytes),
    );
    return _WrappedSecret(
      cipherText: secretBox.cipherText,
      nonce: secretBox.nonce,
      mac: secretBox.mac.bytes,
    );
  }

  Future<List<int>> _unwrapSecret({
    required _WrappedSecret wrappedSecret,
    required String secret,
    required List<int> salt,
    required int iterations,
    required int keyBytes,
  }) async {
    final wrappingKey = await _deriveKeyBytes(
      secret: secret,
      salt: salt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    return AesGcm.with256bits().decrypt(
      SecretBox(
        wrappedSecret.cipherText,
        nonce: wrappedSecret.nonce,
        mac: Mac(wrappedSecret.mac),
      ),
      secretKey: SecretKey(wrappingKey),
    );
  }

  Future<List<int>> _unwrapDatabaseKeyWithPassphrase({
    required SecurityMetadata metadata,
    required String passphrase,
  }) async {
    return _unwrapSecret(
      wrappedSecret: _WrappedSecret(
        cipherText: metadata.passphraseWrappedKey!,
        nonce: metadata.passphraseNonce!,
        mac: metadata.passphraseMac!,
      ),
      secret: passphrase,
      salt: metadata.passphraseSalt!,
      iterations: metadata.iterations,
      keyBytes: metadata.keyBytes,
    );
  }

  Future<List<int>> _unwrapDatabaseKeyWithRecoveryKey({
    required SecurityMetadata metadata,
    required String recoveryKey,
  }) async {
    return _unwrapSecret(
      wrappedSecret: _WrappedSecret(
        cipherText: metadata.recoveryWrappedKey!,
        nonce: metadata.recoveryNonce!,
        mac: metadata.recoveryMac!,
      ),
      secret: normalizeRecoveryKey(recoveryKey),
      salt: metadata.recoverySalt!,
      iterations: metadata.iterations,
      keyBytes: metadata.keyBytes,
    );
  }

  String _generateRecoveryKey() {
    final random = Random.secure();
    final chars = List<String>.generate(
      32,
      (_) => _recoveryAlphabet[random.nextInt(_recoveryAlphabet.length)],
    );
    final groups = <String>[];
    for (var index = 0; index < chars.length; index += 4) {
      groups.add(chars.skip(index).take(4).join());
    }
    return groups.join('-');
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left[index] ^ right[index];
    }
    return result == 0;
  }

  File _metadataFile(File dbFile) =>
      File('${dbFile.path}$securityMetadataSuffix');

  File _integrityManifestFile(File dbFile) =>
      File('${dbFile.path}$integrityManifestSuffix');
}

class SecurityBootstrapResult {
  const SecurityBootstrapResult({this.recoveryKey});

  final String? recoveryKey;
}

class SecurityBootstrapPackage {
  const SecurityBootstrapPackage({required this.metadata, this.recoveryKey});

  final SecurityMetadata metadata;
  final String? recoveryKey;

  static Future<SecurityBootstrapPackage> createRecoverable({
    required String passphrase,
    required int iterations,
    required int keyBytes,
    required int saltBytes,
  }) async {
    final keyService = KeyService();
    final databaseKey = keyService._randomBytes(keyBytes);
    final recoveryKey = keyService._generateRecoveryKey();
    final passphraseSalt = keyService._randomBytes(saltBytes);
    final recoverySalt = keyService._randomBytes(saltBytes);
    final passphraseVerifier = await keyService._deriveKeyBytes(
      secret: passphrase,
      salt: passphraseSalt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    final recoveryVerifier = await keyService._deriveKeyBytes(
      secret: keyService.normalizeRecoveryKey(recoveryKey),
      salt: recoverySalt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    final passphraseWrapped = await keyService._wrapSecret(
      payload: databaseKey,
      secret: passphrase,
      salt: passphraseSalt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    final recoveryWrapped = await keyService._wrapSecret(
      payload: databaseKey,
      secret: keyService.normalizeRecoveryKey(recoveryKey),
      salt: recoverySalt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    return SecurityBootstrapPackage(
      metadata: SecurityMetadata(
        version: 2,
        iterations: iterations,
        keyBytes: keyBytes,
        passphraseSalt: passphraseSalt,
        passphraseVerifier: passphraseVerifier,
        passphraseWrappedKey: passphraseWrapped.cipherText,
        passphraseNonce: passphraseWrapped.nonce,
        passphraseMac: passphraseWrapped.mac,
        recoverySalt: recoverySalt,
        recoveryVerifier: recoveryVerifier,
        recoveryWrappedKey: recoveryWrapped.cipherText,
        recoveryNonce: recoveryWrapped.nonce,
        recoveryMac: recoveryWrapped.mac,
      ),
      recoveryKey: recoveryKey,
    );
  }

  static Future<SecurityBootstrapPackage> createLegacy({
    required String passphrase,
    required int iterations,
    required int keyBytes,
    required int saltBytes,
  }) async {
    return SecurityBootstrapPackage(
      metadata: await SecurityMetadata.createLegacy(
        passphrase: passphrase,
        iterations: iterations,
        keyBytes: keyBytes,
        saltBytes: saltBytes,
      ),
    );
  }
}

class SecurityMetadata {
  SecurityMetadata({
    required this.version,
    required this.iterations,
    required this.keyBytes,
    this.databaseSalt,
    this.integritySalt,
    this.verifierSalt,
    this.verifierBytes,
    this.passphraseSalt,
    this.passphraseVerifier,
    this.passphraseWrappedKey,
    this.passphraseNonce,
    this.passphraseMac,
    this.recoverySalt,
    this.recoveryVerifier,
    this.recoveryWrappedKey,
    this.recoveryNonce,
    this.recoveryMac,
  });

  final int version;
  final int iterations;
  final int keyBytes;
  final List<int>? databaseSalt;
  final List<int>? integritySalt;
  final List<int>? verifierSalt;
  final List<int>? verifierBytes;
  final List<int>? passphraseSalt;
  final List<int>? passphraseVerifier;
  final List<int>? passphraseWrappedKey;
  final List<int>? passphraseNonce;
  final List<int>? passphraseMac;
  final List<int>? recoverySalt;
  final List<int>? recoveryVerifier;
  final List<int>? recoveryWrappedKey;
  final List<int>? recoveryNonce;
  final List<int>? recoveryMac;

  bool get supportsRecovery =>
      version >= 2 &&
      passphraseSalt != null &&
      passphraseVerifier != null &&
      passphraseWrappedKey != null &&
      passphraseNonce != null &&
      passphraseMac != null &&
      recoverySalt != null &&
      recoveryVerifier != null &&
      recoveryWrappedKey != null &&
      recoveryNonce != null &&
      recoveryMac != null;

  static Future<SecurityMetadata> createLegacy({
    required String passphrase,
    required int iterations,
    required int keyBytes,
    required int saltBytes,
  }) async {
    final keyService = KeyService();
    final random = Random.secure();
    final databaseSalt = List<int>.generate(
      saltBytes,
      (_) => random.nextInt(256),
    );
    final integritySalt = List<int>.generate(
      saltBytes,
      (_) => random.nextInt(256),
    );
    final verifierSalt = List<int>.generate(
      saltBytes,
      (_) => random.nextInt(256),
    );
    final verifierBytes = await keyService._deriveKeyBytes(
      secret: passphrase,
      salt: verifierSalt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    return SecurityMetadata(
      version: 1,
      iterations: iterations,
      keyBytes: keyBytes,
      databaseSalt: databaseSalt,
      integritySalt: integritySalt,
      verifierSalt: verifierSalt,
      verifierBytes: verifierBytes,
    );
  }

  Future<SecurityMetadata> copyWithNewPassphrase({
    required String newPassphrase,
    required List<int> databaseKey,
  }) async {
    final keyService = KeyService();
    final nextPassphraseSalt = keyService._randomBytes(KeyService._saltBytes);
    final nextPassphraseVerifier = await keyService._deriveKeyBytes(
      secret: newPassphrase,
      salt: nextPassphraseSalt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    final nextPassphraseWrapped = await keyService._wrapSecret(
      payload: databaseKey,
      secret: newPassphrase,
      salt: nextPassphraseSalt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
    return SecurityMetadata(
      version: version,
      iterations: iterations,
      keyBytes: keyBytes,
      passphraseSalt: nextPassphraseSalt,
      passphraseVerifier: nextPassphraseVerifier,
      passphraseWrappedKey: nextPassphraseWrapped.cipherText,
      passphraseNonce: nextPassphraseWrapped.nonce,
      passphraseMac: nextPassphraseWrapped.mac,
      recoverySalt: recoverySalt,
      recoveryVerifier: recoveryVerifier,
      recoveryWrappedKey: recoveryWrappedKey,
      recoveryNonce: recoveryNonce,
      recoveryMac: recoveryMac,
    );
  }

  factory SecurityMetadata.fromJson(Map<String, dynamic> json) {
    return SecurityMetadata(
      version: json['version'] as int,
      iterations: json['iterations'] as int,
      keyBytes: json['keyBytes'] as int,
      databaseSalt: _decodeOptional(json['databaseSalt']),
      integritySalt: _decodeOptional(json['integritySalt']),
      verifierSalt: _decodeOptional(json['verifierSalt']),
      verifierBytes: _decodeOptional(json['verifier']),
      passphraseSalt: _decodeOptional(json['passphraseSalt']),
      passphraseVerifier: _decodeOptional(json['passphraseVerifier']),
      passphraseWrappedKey: _decodeOptional(json['passphraseWrappedKey']),
      passphraseNonce: _decodeOptional(json['passphraseNonce']),
      passphraseMac: _decodeOptional(json['passphraseMac']),
      recoverySalt: _decodeOptional(json['recoverySalt']),
      recoveryVerifier: _decodeOptional(json['recoveryVerifier']),
      recoveryWrappedKey: _decodeOptional(json['recoveryWrappedKey']),
      recoveryNonce: _decodeOptional(json['recoveryNonce']),
      recoveryMac: _decodeOptional(json['recoveryMac']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'iterations': iterations,
      'keyBytes': keyBytes,
      if (databaseSalt != null) 'databaseSalt': base64Encode(databaseSalt!),
      if (integritySalt != null) 'integritySalt': base64Encode(integritySalt!),
      if (verifierSalt != null) 'verifierSalt': base64Encode(verifierSalt!),
      if (verifierBytes != null) 'verifier': base64Encode(verifierBytes!),
      if (passphraseSalt != null)
        'passphraseSalt': base64Encode(passphraseSalt!),
      if (passphraseVerifier != null)
        'passphraseVerifier': base64Encode(passphraseVerifier!),
      if (passphraseWrappedKey != null)
        'passphraseWrappedKey': base64Encode(passphraseWrappedKey!),
      if (passphraseNonce != null)
        'passphraseNonce': base64Encode(passphraseNonce!),
      if (passphraseMac != null) 'passphraseMac': base64Encode(passphraseMac!),
      if (recoverySalt != null) 'recoverySalt': base64Encode(recoverySalt!),
      if (recoveryVerifier != null)
        'recoveryVerifier': base64Encode(recoveryVerifier!),
      if (recoveryWrappedKey != null)
        'recoveryWrappedKey': base64Encode(recoveryWrappedKey!),
      if (recoveryNonce != null) 'recoveryNonce': base64Encode(recoveryNonce!),
      if (recoveryMac != null) 'recoveryMac': base64Encode(recoveryMac!),
    };
  }

  static List<int>? _decodeOptional(Object? value) {
    if (value == null) {
      return null;
    }
    return base64Decode(value as String);
  }
}

class IntegrityManifest {
  IntegrityManifest({required this.fileHashes, required this.updatedAt});

  final Map<String, String> fileHashes;
  final DateTime updatedAt;

  factory IntegrityManifest.fromJson(Map<String, dynamic> json) {
    final fileHashes = <String, String>{};
    final rawHashes = json['fileHashes'] as Map<String, dynamic>;
    for (final entry in rawHashes.entries) {
      fileHashes[entry.key] = entry.value as String;
    }
    return IntegrityManifest(
      fileHashes: fileHashes,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'fileHashes': fileHashes, 'updatedAt': updatedAt.toIso8601String()};
  }
}

class _WrappedSecret {
  const _WrappedSecret({
    required this.cipherText,
    required this.nonce,
    required this.mac,
  });

  final List<int> cipherText;
  final List<int> nonce;
  final List<int> mac;
}
