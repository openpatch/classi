import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'database_path_service.dart';

const String classiBackupExtension = '.classi-backup';
const String _backupManifestFileName = 'backup.json';
const int _backupFormatVersion = 1;
const String _canonicalDatabaseFileName = 'data.db';

class LibraryBackupService {
  Future<String> exportBackup({
    required String sourceDatabasePath,
    required String destinationFolderPath,
  }) async {
    final normalizedSourcePath = p.normalize(sourceDatabasePath);
    final outputFile = File(
      p.join(
        destinationFolderPath,
        backupFileNameForDatabasePath(normalizedSourcePath),
      ),
    );
    await outputFile.parent.create(recursive: true);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

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
        continue;
      }
      final bytes = await sourceFile.readAsBytes();
      archive.addFile(ArchiveFile(entry.value, bytes.length, bytes));
    }

    final encodedArchive = ZipEncoder().encode(archive);
    await outputFile.writeAsBytes(encodedArchive, flush: true);
    return outputFile.path;
  }

  Future<void> importBackup({
    required String backupFilePath,
    required String destinationDatabasePath,
  }) async {
    final backupFile = File(backupFilePath);
    if (!await backupFile.exists()) {
      throw StateError('Backup file not found.');
    }

    final archive = ZipDecoder().decodeBytes(await backupFile.readAsBytes());
    final manifestFile = archive.findFile(_backupManifestFileName);
    if (manifestFile == null) {
      throw StateError('Backup manifest missing.');
    }

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
        if (await file.exists()) {
          await file.delete();
        }
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
      if (!file.isFile || file.name == _backupManifestFileName) {
        continue;
      }

      final destinationPath = destinationByEntryName[file.name];
      if (destinationPath == null) {
        continue;
      }

      final bytes = file.content as List<int>;
      final destinationFile = File(destinationPath);
      await destinationFile.parent.create(recursive: true);
      await destinationFile.writeAsBytes(bytes, flush: true);

      if (file.name == _canonicalDatabaseFileName) {
        restoredDatabase = true;
      } else if (file.name.endsWith('.security.json')) {
        restoredSecurityMetadata = true;
      }
    }

    if (!restoredDatabase || !restoredSecurityMetadata) {
      throw StateError('Backup archive is incomplete.');
    }
  }

  static String backupFileNameForDatabasePath(String databasePath) {
    return '${_libraryNameForPath(databasePath)}$classiBackupExtension';
  }

  static String libraryNameForBackupFile(String backupFilePath) {
    return _libraryNameForPath(backupFilePath);
  }

  static bool isBackupFilePath(String path) {
    return p.basename(path).toLowerCase().endsWith(classiBackupExtension);
  }

  static String _libraryNameForPath(String path) {
    return p.basenameWithoutExtension(p.normalize(path));
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
