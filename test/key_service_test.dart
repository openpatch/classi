import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clari/core/security/key_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late File dbFile;
  late KeyService keyService;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('clari-key-service');
    dbFile = File('${tempDirectory.path}/clari.db');
    await dbFile.writeAsString('seed');
    keyService = KeyService();
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('bootstrapSecurity stores metadata, passphrase, and recovery key', () async {
    final bootstrapResult = await keyService.bootstrapSecurity(
      dbFile: dbFile,
      passphrase: 'correct horse battery staple',
      iterations: 1000,
    );

    expect(await keyService.hasSecuritySetup(dbFile), isTrue);
    expect(await keyService.hasRecoveryKey(dbFile), isTrue);
    expect(bootstrapResult.recoveryKey, isNotNull);
    expect(
      await keyService.verifyPassphrase(
        dbFile: dbFile,
        passphrase: 'correct horse battery staple',
      ),
      isTrue,
    );
    expect(
      await keyService.verifyRecoveryKey(
        dbFile: dbFile,
        recoveryKey: bootstrapResult.recoveryKey!,
      ),
      isTrue,
    );
  });

  test('deriveDatabaseKey is stable for passphrase and recovery key', () async {
    final bootstrapResult = await keyService.bootstrapSecurity(
      dbFile: dbFile,
      passphrase: 'lesson-notes-secret',
      iterations: 1000,
    );

    final fromPassphrase = await keyService.deriveDatabaseKey(
      dbFile: dbFile,
      passphrase: 'lesson-notes-secret',
    );
    final fromRecoveryKey = await keyService.deriveDatabaseKeyWithRecoveryKey(
      dbFile: dbFile,
      recoveryKey: bootstrapResult.recoveryKey!,
    );

    expect(fromPassphrase, equals(fromRecoveryKey));
  });

  test('recoverPassphrase lets a new passphrase unlock the same database key', () async {
    final bootstrapResult = await keyService.bootstrapSecurity(
      dbFile: dbFile,
      passphrase: 'old-passphrase',
      iterations: 1000,
    );

    final previousDatabaseKey = await keyService.deriveDatabaseKey(
      dbFile: dbFile,
      passphrase: 'old-passphrase',
    );

    final recoveredDatabaseKey = await keyService.recoverPassphrase(
      dbFile: dbFile,
      recoveryKey: bootstrapResult.recoveryKey!,
      newPassphrase: 'new-passphrase',
    );

    expect(recoveredDatabaseKey, equals(previousDatabaseKey));
    expect(
      await keyService.verifyPassphrase(
        dbFile: dbFile,
        passphrase: 'new-passphrase',
      ),
      isTrue,
    );
    expect(
      await keyService.deriveDatabaseKey(
        dbFile: dbFile,
        passphrase: 'new-passphrase',
      ),
      equals(previousDatabaseKey),
    );
  });

  test('integrity manifest detects changed files', () async {
    await keyService.bootstrapSecurity(
      dbFile: dbFile,
      passphrase: 'sync-secret',
      iterations: 1000,
    );
    await keyService.writeIntegrityManifest(
      dbFile: dbFile,
      passphrase: 'sync-secret',
    );

    expect(
      await keyService.validateIntegrity(
        dbFile: dbFile,
        passphrase: 'sync-secret',
        allowRepair: false,
      ),
      isTrue,
    );

    await dbFile.writeAsString('changed');

    expect(
      await keyService.validateIntegrity(
        dbFile: dbFile,
        passphrase: 'sync-secret',
        allowRepair: false,
      ),
      isFalse,
    );
  });
}
