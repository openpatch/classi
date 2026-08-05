import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'database_path_service.dart';

const String classiBackupExtension = '.classi-backup';
const String _backupManifestFileName = 'backup.json';
const int _backupFormatVersion = 1;
const String _canonicalDatabaseFileName = 'data.db';
const String _syncLockFileName = '.classi-sync.lock';
const Duration _syncLockLease = Duration(minutes: 2);
const int _syncLockVerifyJitterMs = 300;

/// Thrown by [LibraryBackupService.exportBackupToWebDav] when another device
/// currently holds the sync lock for the target folder.
///
/// This is expected, transient contention — not a corruption or connection
/// failure — so callers should surface it as "try again in a moment" rather
/// than a generic export error.
class WebDavSyncBusyException implements Exception {
  const WebDavSyncBusyException(this.message);

  final String message;

  @override
  String toString() => 'WebDavSyncBusyException: $message';
}

/// Thrown by [LibraryBackupService.exportBackupToWebDav] when the remote
/// backup has moved on to a revision this device never saw — i.e. another
/// device pushed a change since this device last synced.
///
/// The canonical backup is left untouched; this device's changes are
/// uploaded as a separate `_CONFLICT_` copy instead, so nothing is lost on
/// either side. The user needs to reconcile the two manually (the conflict
/// copy shows up alongside the canonical one in the backup list).
class WebDavSyncConflictException implements Exception {
  const WebDavSyncConflictException({
    required this.message,
    this.conflictingDeviceName,
  });

  final String message;

  /// The device that produced the remote revision this export conflicts
  /// with, if known.
  final String? conflictingDeviceName;

  @override
  String toString() => 'WebDavSyncConflictException: $message';
}

class WebDavBackupEntry {
  const WebDavBackupEntry({
    required this.fileName,
    required this.libraryName,
    required this.remotePath,
    this.modifiedAt,
    this.sizeBytes,
    this.deviceId,
    this.deviceName,
    this.revision,
  });

  final String fileName;
  final String libraryName;
  final String remotePath;
  final DateTime? modifiedAt;
  final int? sizeBytes;

  /// The device that uploaded this backup, if known. `null` for backups
  /// exported before device attribution was introduced, or when the sidecar
  /// metadata file could not be read.
  final String? deviceId;
  final String? deviceName;

  /// This backup's own revision token from its sidecar, if known. Used to
  /// reconcile a sync conflict (see [WebDavSyncConflictException]) by
  /// telling the exporter which remote revision it is now superseding.
  final String? revision;

  /// Whether this is a `_CONFLICT_` copy uploaded when a device's export
  /// found the canonical backup had moved on to a revision it never saw.
  bool get isConflict =>
      LibraryBackupService._conflictTimestampPattern.hasMatch(
        p.basenameWithoutExtension(fileName),
      );
}

/// Metadata read from a backup's `.meta.json` sidecar: which device
/// produced it and its place in the revision chain (see
/// [LibraryBackupService.exportBackupToWebDav]'s conflict detection).
class WebDavBackupDeviceInfo {
  const WebDavBackupDeviceInfo({
    this.deviceId,
    this.deviceName,
    this.revision,
  });

  final String? deviceId;
  final String? deviceName;

  /// This backup's own revision token, or `null` for backups exported
  /// before revision tracking existed.
  final String? revision;
}

class LibraryBackupService {
  /// Builds a `.classi-backup` ZIP archive from the current database files
  /// and returns the raw bytes.
  ///
  /// [exportedAt] sets the `exportedAt` timestamp in the manifest. Defaults
  /// to the current UTC time when not provided.
  Future<Uint8List> buildBackupArchive(
    String sourceDatabasePath, {
    DateTime? exportedAt,
    String? deviceId,
    String? deviceName,
    String? revision,
    String? parentRevision,
  }) async {
    final normalizedSourcePath = p.normalize(sourceDatabasePath);
    developer.log(
      'buildBackupArchive: path=$normalizedSourcePath',
      name: 'classi.backup',
    );
    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        _backupManifestFileName,
        jsonEncode({
          'formatVersion': _backupFormatVersion,
          'libraryName': _libraryNameForPath(normalizedSourcePath),
          'exportedAt': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
          'deviceId': ?deviceId,
          'deviceName': ?deviceName,
          'revision': ?revision,
          'parentRevision': ?parentRevision,
        }),
      ),
    );

    for (final entry in _artifactEntryNamesFor(normalizedSourcePath).entries) {
      final sourceFile = File(entry.key);
      if (!await sourceFile.exists()) {
        developer.log(
          'buildBackupArchive: skipping missing file ${entry.key}',
          name: 'classi.backup',
        );
        continue;
      }
      final bytes = await sourceFile.readAsBytes();
      developer.log(
        'buildBackupArchive: adding ${entry.value} (${bytes.length} bytes)',
        name: 'classi.backup',
      );
      archive.addFile(ArchiveFile(entry.value, bytes.length, bytes));
    }

    final encoded = Uint8List.fromList(ZipEncoder().encode(archive));
    developer.log(
      'buildBackupArchive: archive size=${encoded.length} bytes',
      name: 'classi.backup',
    );
    return encoded;
  }

  /// Restores a backup archive from [bytes] into [destinationDatabasePath].
  ///
  /// Returns the restored backup's `revision` token from its manifest, or
  /// `null` for a backup exported before revision tracking existed. Callers
  /// should record this as the new "last known revision" for the library so
  /// the next export can detect whether the remote moved on in the
  /// meantime.
  Future<String?> restoreBackupFromBytes({
    required Uint8List bytes,
    required String destinationDatabasePath,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile(_backupManifestFileName);
    if (manifestFile == null) throw StateError('Backup manifest missing.');

    final manifestBytes = manifestFile.content as List<int>;
    final manifestJson =
        jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
    if (manifestJson['formatVersion'] != _backupFormatVersion) {
      throw StateError('Unsupported backup format.');
    }

    if (DatabasePathService.isPackagePath(destinationDatabasePath)) {
      final destinationDirectory = Directory(destinationDatabasePath);
      if (await destinationDirectory.exists()) {
        await destinationDirectory.delete(recursive: true);
      }
      await destinationDirectory.create(recursive: true);
    } else {
      for (final artifactPath in DatabasePathService.artifactPathsFor(
        destinationDatabasePath,
      )) {
        final file = File(artifactPath);
        if (await file.exists()) await file.delete();
      }
    }

    final destinationByEntryName = {
      for (final entry in _artifactEntryNamesFor(
        destinationDatabasePath,
      ).entries)
        entry.value: entry.key,
    };

    var restoredDatabase = false;
    var restoredSecurityMetadata = false;

    for (final file in archive.files) {
      if (!file.isFile || file.name == _backupManifestFileName) continue;

      final destinationPath = destinationByEntryName[file.name];
      if (destinationPath == null) continue;

      final fileBytes = file.content as List<int>;
      final destinationFile = File(destinationPath);
      await destinationFile.parent.create(recursive: true);
      await destinationFile.writeAsBytes(fileBytes, flush: true);

      if (file.name == _canonicalDatabaseFileName) restoredDatabase = true;
      if (file.name.endsWith('.security.json')) restoredSecurityMetadata = true;
    }

    if (!restoredDatabase || !restoredSecurityMetadata) {
      throw StateError('Backup archive is incomplete.');
    }

    return manifestJson['revision'] as String?;
  }

  /// Builds a backup archive in memory and uploads it atomically to the
  /// WebDAV server.
  ///
  /// The upload goes to a `.tmp` file first, then the existing backup (if any)
  /// is archived as a timestamped copy, and the `.tmp` file is renamed to the
  /// canonical backup name. Older archived versions beyond [maxVersions] are
  /// pruned. The whole sequence runs under a best-effort sync lock (see
  /// [_trySyncLockAcquire]) so two devices exporting at the same moment don't
  /// interleave their archive/rename/prune steps.
  ///
  /// [parentRevision] should be the revision this device last saw for this
  /// library (its own last export, or whatever it last restored) — pass
  /// `null` if this device has never synced this library before. If the
  /// remote's current revision doesn't match, another device pushed a
  /// change this device never saw: rather than silently overwriting it,
  /// this uploads the local changes as a separate `_CONFLICT_` copy and
  /// throws [WebDavSyncConflictException], leaving the canonical backup
  /// untouched.
  ///
  /// Throws [WebDavSyncBusyException] if another device currently holds the
  /// sync lock.
  ///
  /// Returns the UTC [DateTime] embedded as `exportedAt` in the manifest.
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
    String? parentRevision,
  }) async {
    await client.mkdirAll(serverPath);

    final lockOwnerId = deviceId ?? _fallbackSyncLockOwnerId();
    final lockAcquired = await _trySyncLockAcquire(
      client: client,
      serverPath: serverPath,
      ownerId: lockOwnerId,
    );
    if (!lockAcquired) {
      throw const WebDavSyncBusyException(
        'Another device is syncing this library right now.',
      );
    }

    try {
      final canonicalName = backupFileNameForDatabasePath(sourceDatabasePath);
      final canonicalPath = _joinServerPath(serverPath, canonicalName);

      // Detect whether the remote moved on to a revision we never saw.
      // A remote with no revision at all (nothing uploaded yet, or an old
      // backup that predates revision tracking) is not a conflict — there's
      // nothing to compare against, so fail open rather than block export
      // forever on a pre-existing legacy backup.
      final existingRemote = await _readMetaSidecar(
        client: client,
        backupPath: canonicalPath,
      );
      final remoteRevision = existingRemote.revision;
      if (remoteRevision != null && remoteRevision != parentRevision) {
        final exportedAt = DateTime.now().toUtc();
        final revision = _randomToken();
        final bytes = await buildBackupArchive(
          sourceDatabasePath,
          exportedAt: exportedAt,
          deviceId: deviceId,
          deviceName: deviceName,
          revision: revision,
          parentRevision: parentRevision,
        );
        final stem = p.basenameWithoutExtension(canonicalName);
        final conflictName =
            '${stem}_CONFLICT_${_timestampStamp(exportedAt)}$classiBackupExtension';
        final conflictPath = _joinServerPath(serverPath, conflictName);
        developer.log(
          'exportBackupToWebDav: conflict detected, uploading as $conflictName',
          name: 'classi.backup',
        );
        await client.write(conflictPath, bytes);
        await _writeMetaSidecar(
          client: client,
          backupPath: conflictPath,
          deviceId: deviceId,
          deviceName: deviceName,
          exportedAt: exportedAt,
          revision: revision,
          parentRevision: parentRevision,
        );
        throw WebDavSyncConflictException(
          message:
              'Another device changed this library since this device last '
              'synced. Saved local changes as a separate copy instead of '
              'overwriting the newer backup.',
          conflictingDeviceName: existingRemote.deviceName,
        );
      }

      final exportedAt = DateTime.now().toUtc();
      final revision = _randomToken();
      final bytes = await buildBackupArchive(
        sourceDatabasePath,
        exportedAt: exportedAt,
        deviceId: deviceId,
        deviceName: deviceName,
        revision: revision,
        parentRevision: parentRevision,
      );
      final tmpPath = '$canonicalPath.tmp';
      developer.log(
        'exportBackupToWebDav: uploading to $tmpPath (${bytes.length} bytes)',
        name: 'classi.backup',
      );
      await client.write(tmpPath, bytes);
      await _writeMetaSidecar(
        client: client,
        backupPath: tmpPath,
        deviceId: deviceId,
        deviceName: deviceName,
        exportedAt: exportedAt,
        revision: revision,
        parentRevision: parentRevision,
      );

      // Archive the current canonical backup before replacing it.
      await _archiveExistingBackup(
        client: client,
        serverPath: serverPath,
        canonicalName: canonicalName,
        canonicalPath: canonicalPath,
      );

      // Atomically promote the tmp file to the canonical name.
      developer.log(
        'exportBackupToWebDav: renaming $tmpPath → $canonicalPath',
        name: 'classi.backup',
      );
      await client.rename(tmpPath, canonicalPath, true);
      await _renameMetaSidecar(
        client: client,
        fromBackupPath: tmpPath,
        toBackupPath: canonicalPath,
      );

      // Prune old archived versions.
      await _pruneArchivedVersions(
        client: client,
        serverPath: serverPath,
        canonicalName: canonicalName,
        maxVersions: maxVersions,
      );

      developer.log('exportBackupToWebDav: done', name: 'classi.backup');
      return exportedAt;
    } finally {
      await _syncLockRelease(
        client: client,
        serverPath: serverPath,
        ownerId: lockOwnerId,
      );
    }
  }

  Future<void> _archiveExistingBackup({
    required webdav.Client client,
    required String serverPath,
    required String canonicalName,
    required String canonicalPath,
  }) async {
    try {
      final props = await client.readProps(canonicalPath);
      final mTime = props.mTime;
      if (mTime == null) return;
      final stamp = _timestampStamp(mTime);
      final stem = p.basenameWithoutExtension(canonicalName);
      final archivedName = '${stem}_$stamp$classiBackupExtension';
      final archivedPath = _joinServerPath(serverPath, archivedName);
      developer.log(
        'exportBackupToWebDav: archiving existing backup as $archivedName',
        name: 'classi.backup',
      );
      await client.rename(canonicalPath, archivedPath, true);
      await _renameMetaSidecar(
        client: client,
        fromBackupPath: canonicalPath,
        toBackupPath: archivedPath,
      );
    } catch (_) {
      // No existing file or server does not support rename — proceed.
    }
  }

  Future<void> _pruneArchivedVersions({
    required webdav.Client client,
    required String serverPath,
    required String canonicalName,
    required int maxVersions,
  }) async {
    if (maxVersions <= 1) return;
    try {
      final stem = p.basenameWithoutExtension(canonicalName);
      final files = await client.readDir(serverPath);
      final archived = files
          .where((f) {
            final name = f.name ?? p.basename(f.path ?? '');
            return name.startsWith('${stem}_') &&
                name.toLowerCase().endsWith(classiBackupExtension);
          })
          .toList();

      // Sort oldest first (by mTime ascending).
      archived.sort((a, b) {
        final at = a.mTime;
        final bt = b.mTime;
        if (at == null && bt == null) return 0;
        if (at == null) return -1;
        if (bt == null) return 1;
        return at.compareTo(bt);
      });

      // Keep the newest (maxVersions - 1) archived copies (the canonical
      // counts as one version).
      final keepCount = maxVersions - 1;
      if (archived.length > keepCount) {
        final toDelete = archived.sublist(0, archived.length - keepCount);
        for (final file in toDelete) {
          final name = file.name ?? p.basename(file.path ?? '');
          developer.log(
            'exportBackupToWebDav: pruning $name',
            name: 'classi.backup',
          );
          try {
            await client.remove(_joinServerPath(serverPath, name));
          } catch (_) {}
          try {
            await client.remove(
              _metaSidecarPath(_joinServerPath(serverPath, name)),
            );
          } catch (_) {}
        }
      }
    } catch (_) {
      // Pruning is best-effort.
    }
  }

  /// Downloads the backup at [remotePath] and returns its raw bytes.
  Future<Uint8List> downloadBackupFromWebDav({
    required webdav.Client client,
    required String remotePath,
  }) async {
    final bytes = await client.read(remotePath);
    return Uint8List.fromList(bytes);
  }

  /// Returns the last-modified time of the backup file on the WebDAV server,
  /// or `null` if the file does not exist or cannot be reached.
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async {
    try {
      final remotePath = _joinServerPath(serverPath, backupFileName);
      final props = await client.readProps(remotePath);
      return props.mTime;
    } catch (_) {
      return null;
    }
  }

  /// Reads the device attribution sidecar for the backup at [remotePath],
  /// or an empty [WebDavBackupDeviceInfo] if none exists or it cannot be
  /// read (e.g. an older backup exported before device attribution existed).
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) => _readMetaSidecar(client: client, backupPath: remotePath);

  /// Lists backup archives available on the WebDAV server path.
  ///
  /// Both canonical (`name.classi-backup`) and archived
  /// (`name_TIMESTAMP.classi-backup`) files are returned and sorted newest
  /// first.
  Future<List<WebDavBackupEntry>> listRemoteBackups({
    required webdav.Client client,
    required String serverPath,
  }) async {
    final files = await client.readDir(serverPath);
    final candidates =
        <({String fileName, DateTime? modifiedAt, int? sizeBytes})>[];

    for (final file in files) {
      if (file.isDir == true) {
        continue;
      }

      final fileName = file.name ?? p.basename(file.path ?? '');
      if (fileName.isEmpty || !isBackupFilePath(fileName)) {
        continue;
      }

      candidates.add((
        fileName: fileName,
        modifiedAt: file.mTime,
        sizeBytes: file.size,
      ));
    }

    final remotePaths = [
      for (final candidate in candidates)
        _joinServerPath(serverPath, candidate.fileName),
    ];
    final deviceInfos = await Future.wait([
      for (final remotePath in remotePaths)
        _readMetaSidecar(client: client, backupPath: remotePath),
    ]);

    final backups = <WebDavBackupEntry>[
      for (var index = 0; index < candidates.length; index++)
        WebDavBackupEntry(
          fileName: candidates[index].fileName,
          libraryName: libraryNameForBackupFile(candidates[index].fileName),
          remotePath: remotePaths[index],
          modifiedAt: candidates[index].modifiedAt,
          sizeBytes: candidates[index].sizeBytes,
          deviceId: deviceInfos[index].deviceId,
          deviceName: deviceInfos[index].deviceName,
          revision: deviceInfos[index].revision,
        ),
    ];

    backups.sort((left, right) {
      final leftModified = left.modifiedAt;
      final rightModified = right.modifiedAt;
      if (leftModified != null && rightModified != null) {
        final byModified = rightModified.compareTo(leftModified);
        if (byModified != 0) {
          return byModified;
        }
      } else if (rightModified != null) {
        return 1;
      } else if (leftModified != null) {
        return -1;
      }

      return left.libraryName.toLowerCase().compareTo(
        right.libraryName.toLowerCase(),
      );
    });

    return backups;
  }

  /// Builds the full remote path for a backup from [serverPath] and [databasePath].
  static String remoteBackupPath(String serverPath, String databasePath) =>
      _joinServerPath(serverPath, backupFileNameForDatabasePath(databasePath));

  static String backupFileNameForDatabasePath(String databasePath) =>
      '${_libraryNameForPath(databasePath)}$classiBackupExtension';

  /// Matches the `_CONFLICT_<timestamp>` suffix appended to the canonical
  /// library name for conflict copies, e.g. `MyClass_CONFLICT_20260507T080000Z`.
  static final RegExp _conflictTimestampPattern = RegExp(
    r'_CONFLICT_\d{8}T\d{6}Z$',
  );

  /// Matches the `_<timestamp>` suffix appended to the canonical library name
  /// for archived copies, e.g. `MyClass_20260506T143200Z`.
  static final RegExp _archivedTimestampPattern = RegExp(r'_\d{8}T\d{6}Z$');

  static String libraryNameForBackupFile(String backupFilePath) {
    final stem = _libraryNameForPath(backupFilePath);
    final withoutConflictSuffix = stem.replaceFirst(
      _conflictTimestampPattern,
      '',
    );
    if (withoutConflictSuffix != stem) {
      return withoutConflictSuffix;
    }
    return stem.replaceFirst(_archivedTimestampPattern, '');
  }

  static bool isBackupFilePath(String path) =>
      p.basename(path).toLowerCase().endsWith(classiBackupExtension);

  static String _joinServerPath(String dir, String fileName) {
    final normalized = dir.endsWith('/') ? dir : '$dir/';
    return '$normalized$fileName';
  }

  static String _libraryNameForPath(String path) =>
      p.basenameWithoutExtension(p.normalize(path));

  static String _metaSidecarPath(String backupPath) => '$backupPath.meta.json';

  /// Formats [dt] as the compact UTC timestamp used in archived/conflict
  /// backup file names, e.g. `20260507T080000Z`.
  static String _timestampStamp(DateTime dt) => dt
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('-', '')
      .split('.')
      .first;

  /// Uploads the attribution/revision sidecar for [backupPath]. Best-effort:
  /// this metadata is for display and conflict detection, so a failure here
  /// must never break the backup export itself.
  Future<void> _writeMetaSidecar({
    required webdav.Client client,
    required String backupPath,
    required String? deviceId,
    required String? deviceName,
    required DateTime exportedAt,
    String? revision,
    String? parentRevision,
  }) async {
    try {
      final metaBytes = utf8.encode(
        jsonEncode({
          'deviceId': ?deviceId,
          'deviceName': ?deviceName,
          'exportedAt': exportedAt.toIso8601String(),
          'revision': ?revision,
          'parentRevision': ?parentRevision,
        }),
      );
      await client.write(_metaSidecarPath(backupPath), metaBytes);
    } catch (_) {
      // Best-effort; the backup itself already succeeded.
    }
  }

  /// Renames the device-attribution sidecar alongside a backup rename.
  /// Best-effort: an older backup may not have a sidecar to rename.
  Future<void> _renameMetaSidecar({
    required webdav.Client client,
    required String fromBackupPath,
    required String toBackupPath,
  }) async {
    try {
      await client.rename(
        _metaSidecarPath(fromBackupPath),
        _metaSidecarPath(toBackupPath),
        true,
      );
    } catch (_) {
      // No sidecar to rename — proceed.
    }
  }

  Future<WebDavBackupDeviceInfo> _readMetaSidecar({
    required webdav.Client client,
    required String backupPath,
  }) async {
    try {
      final metaBytes = await client.read(_metaSidecarPath(backupPath));
      final metaJson =
          jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;
      return WebDavBackupDeviceInfo(
        deviceId: metaJson['deviceId'] as String?,
        deviceName: metaJson['deviceName'] as String?,
        revision: metaJson['revision'] as String?,
      );
    } catch (_) {
      return const WebDavBackupDeviceInfo();
    }
  }

  // --- Sync lock -------------------------------------------------------
  //
  // WebDAV servers vary in their support for the native LOCK/UNLOCK methods
  // (RFC 4918), so rather than depend on that this uses a plain lock file
  // any WebDAV server can store: `<serverPath>/.classi-sync.lock`, holding
  // `{deviceId, acquiredAt}` as JSON.
  //
  // Acquisition is "write, then read back and check we're still the
  // recorded owner" rather than a true atomic compare-and-swap — this is a
  // best-effort, advisory lock, not a hard guarantee. It's good enough to
  // catch the common case (two devices syncing within moments of each
  // other) without depending on WebDAV features not every server offers.
  // A lease (see [_syncLockLease]) makes a lock left behind by a crashed or
  // killed app expire automatically rather than wedging the folder forever.

  static String _syncLockPath(String serverPath) =>
      _joinServerPath(serverPath, _syncLockFileName);

  /// Whether a lock acquired at [acquiredAt] has outlived its lease and
  /// should be treated as abandoned. Exposed for testing the time math
  /// without needing a WebDAV round-trip.
  static bool isSyncLockExpired(DateTime acquiredAt, {DateTime? now}) =>
      (now ?? DateTime.now().toUtc()).difference(acquiredAt) > _syncLockLease;

  Future<bool> _trySyncLockAcquire({
    required webdav.Client client,
    required String serverPath,
    required String ownerId,
  }) async {
    final lockPath = _syncLockPath(serverPath);

    final existing = await _readSyncLock(client: client, lockPath: lockPath);
    if (existing != null &&
        existing.deviceId != ownerId &&
        !isSyncLockExpired(existing.acquiredAt)) {
      return false;
    }

    await client.write(
      lockPath,
      utf8.encode(
        jsonEncode({
          'deviceId': ownerId,
          'acquiredAt': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
    );

    // Give a concurrent writer a moment to finish its own write, then check
    // whether we're actually the one left recorded as the owner.
    await Future<void>.delayed(
      Duration(milliseconds: Random().nextInt(_syncLockVerifyJitterMs)),
    );
    final afterWrite = await _readSyncLock(client: client, lockPath: lockPath);
    return afterWrite?.deviceId == ownerId;
  }

  /// Releases the sync lock, but only if [ownerId] still holds it — never
  /// removes a lock another device has since (legitimately) acquired.
  Future<void> _syncLockRelease({
    required webdav.Client client,
    required String serverPath,
    required String ownerId,
  }) async {
    final lockPath = _syncLockPath(serverPath);
    final existing = await _readSyncLock(client: client, lockPath: lockPath);
    if (existing == null || existing.deviceId != ownerId) return;

    try {
      await client.remove(lockPath);
    } catch (_) {
      // Best-effort; the lease will expire it regardless.
    }
  }

  Future<({String deviceId, DateTime acquiredAt})?> _readSyncLock({
    required webdav.Client client,
    required String lockPath,
  }) async {
    try {
      final bytes = await client.read(lockPath);
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final deviceId = json['deviceId'] as String?;
      final acquiredAt = DateTime.tryParse(
        json['acquiredAt'] as String? ?? '',
      );
      if (deviceId == null || acquiredAt == null) return null;
      return (deviceId: deviceId, acquiredAt: acquiredAt);
    } catch (_) {
      return null;
    }
  }

  String _fallbackSyncLockOwnerId() => _randomToken();

  /// A short random opaque hex token, used for the sync lock's fallback
  /// owner id and for revision tokens.
  String _randomToken() {
    final random = Random.secure();
    return List<int>.generate(
      8,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  Map<String, String> _artifactEntryNamesFor(String databasePath) {
    final databaseFilePath = DatabasePathService.databaseFilePathFor(
      databasePath,
    );
    return {
      for (final artifactPath in DatabasePathService.artifactPathsFor(
        databasePath,
      ))
        artifactPath:
            '$_canonicalDatabaseFileName${artifactPath.substring(databaseFilePath.length)}',
    };
  }
}
