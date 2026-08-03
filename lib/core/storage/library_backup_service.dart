import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'database_path_service.dart';

const String classiBackupExtension = '.classi-backup';
const String _backupManifestFileName = 'backup.json';
const int _backupFormatVersion = 1;
const String _canonicalDatabaseFileName = 'data.db';

class WebDavBackupEntry {
  const WebDavBackupEntry({
    required this.fileName,
    required this.libraryName,
    required this.remotePath,
    this.modifiedAt,
    this.sizeBytes,
    this.deviceId,
    this.deviceName,
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
}

/// Device attribution read from a backup's `.meta.json` sidecar.
class WebDavBackupDeviceInfo {
  const WebDavBackupDeviceInfo({this.deviceId, this.deviceName});

  final String? deviceId;
  final String? deviceName;
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
          if (deviceId != null) 'deviceId': deviceId,
          if (deviceName != null) 'deviceName': deviceName,
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
  Future<void> restoreBackupFromBytes({
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
  }

  /// Builds a backup archive in memory and uploads it atomically to the
  /// WebDAV server.
  ///
  /// The upload goes to a `.tmp` file first, then the existing backup (if any)
  /// is archived as a timestamped copy, and the `.tmp` file is renamed to the
  /// canonical backup name. Older archived versions beyond [maxVersions] are
  /// pruned.
  ///
  /// Returns the UTC [DateTime] embedded as `exportedAt` in the manifest.
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
  }) async {
    final exportedAt = DateTime.now().toUtc();
    final bytes = await buildBackupArchive(
      sourceDatabasePath,
      exportedAt: exportedAt,
      deviceId: deviceId,
      deviceName: deviceName,
    );
    final canonicalName = backupFileNameForDatabasePath(sourceDatabasePath);
    final canonicalPath = _joinServerPath(serverPath, canonicalName);
    final tmpPath = '$canonicalPath.tmp';
    developer.log(
      'exportBackupToWebDav: uploading to $tmpPath (${bytes.length} bytes)',
      name: 'classi.backup',
    );
    await client.mkdirAll(serverPath);
    await client.write(tmpPath, bytes);
    await _writeMetaSidecar(
      client: client,
      backupPath: tmpPath,
      deviceId: deviceId,
      deviceName: deviceName,
      exportedAt: exportedAt,
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
      final stamp = mTime.toUtc().toIso8601String().replaceAll(':', '').replaceAll('-', '').split('.').first;
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

  static String libraryNameForBackupFile(String backupFilePath) {
    final stem = _libraryNameForPath(backupFilePath);
    // Archived files look like "name_20260506T143200Z". Strip the timestamp.
    final timestampPattern = RegExp(r'_\d{8}T\d{6}Z$');
    return stem.replaceFirst(timestampPattern, '');
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

  /// Uploads the device-attribution sidecar for [backupPath]. Best-effort:
  /// device attribution is metadata for display purposes only, so a failure
  /// here must never break the backup export itself.
  Future<void> _writeMetaSidecar({
    required webdav.Client client,
    required String backupPath,
    required String? deviceId,
    required String? deviceName,
    required DateTime exportedAt,
  }) async {
    try {
      final metaBytes = utf8.encode(
        jsonEncode({
          if (deviceId != null) 'deviceId': deviceId,
          if (deviceName != null) 'deviceName': deviceName,
          'exportedAt': exportedAt.toIso8601String(),
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
      );
    } catch (_) {
      return const WebDavBackupDeviceInfo();
    }
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
