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
  });

  final String fileName;
  final String libraryName;
  final String remotePath;
  final DateTime? modifiedAt;
  final int? sizeBytes;
}

class LibraryBackupService {
  /// Builds a `.classi-backup` ZIP archive from the current database files
  /// and returns the raw bytes.
  Future<Uint8List> buildBackupArchive(String sourceDatabasePath) async {
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
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
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

  /// Builds a backup archive in memory and uploads it to the WebDAV server.
  Future<void> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
  }) async {
    final bytes = await buildBackupArchive(sourceDatabasePath);
    final remotePath = remoteBackupPath(serverPath, sourceDatabasePath);
    developer.log(
      'exportBackupToWebDav: remotePath=$remotePath size=${bytes.length}',
      name: 'classi.backup',
    );
    await client.mkdirAll(serverPath);
    await client.write(remotePath, bytes);
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

  /// Lists backup archives available on the WebDAV server path.
  Future<List<WebDavBackupEntry>> listRemoteBackups({
    required webdav.Client client,
    required String serverPath,
  }) async {
    final files = await client.readDir(serverPath);
    final backups = <WebDavBackupEntry>[];

    for (final file in files) {
      if (file.isDir == true) {
        continue;
      }

      final fileName = file.name ?? p.basename(file.path ?? '');
      if (fileName.isEmpty || !isBackupFilePath(fileName)) {
        continue;
      }

      backups.add(
        WebDavBackupEntry(
          fileName: fileName,
          libraryName: libraryNameForBackupFile(fileName),
          remotePath: _joinServerPath(serverPath, fileName),
          modifiedAt: file.mTime,
          sizeBytes: file.size,
        ),
      );
    }

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

  static String libraryNameForBackupFile(String backupFilePath) =>
      _libraryNameForPath(backupFilePath);

  static bool isBackupFilePath(String path) =>
      p.basename(path).toLowerCase().endsWith(classiBackupExtension);

  static String _joinServerPath(String dir, String fileName) {
    final normalized = dir.endsWith('/') ? dir : '$dir/';
    return '$normalized$fileName';
  }

  static String _libraryNameForPath(String path) =>
      p.basenameWithoutExtension(p.normalize(path));

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
