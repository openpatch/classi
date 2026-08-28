import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String defaultLibraryPackageName = 'classi.classi';
const String _internalDbFileName = 'data.db';
const String _databasePathPreferenceKey = 'db_file_path';
const List<String> _sidecars = [
  '-wal',
  '-shm',
  '.settings.json',
  '.security.json',
  '.integrity.json',
];

class DatabasePathService {
  /// Whether the user may store libraries in a folder of their choosing.
  ///
  /// Android's scoped storage forbids raw file access to arbitrary folders in
  /// shared storage, so on Android libraries always live in the app-specific
  /// external storage directory and the folder picker is hidden.
  static bool get supportsCustomLibraryFolder => !Platform.isAndroid;

  Future<File> getDatabaseFile() async {
    final selectedPath = await getCurrentDatabasePath();
    final databaseFilePath = databaseFilePathFor(selectedPath);
    await Directory(p.dirname(databaseFilePath)).create(recursive: true);
    return File(databaseFilePath);
  }

  Future<bool> databasePathExists(String databasePath) async {
    final normalizedPath = p.normalize(databasePath);
    if (isPackagePath(normalizedPath)) {
      return Directory(normalizedPath).exists();
    }
    return File(normalizedPath).exists();
  }

  Future<String> getCurrentDatabasePath() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedPath = prefs.getString(_databasePathPreferenceKey);
    if (selectedPath != null && selectedPath.isNotEmpty) {
      return selectedPath;
    }

    return p.join(await defaultLibrariesDirectory(), defaultLibraryPackageName);
  }

  Future<void> setDatabaseFilePath(String databasePath) async {
    final normalizedPath = p.normalize(databasePath);
    await Directory(
      containerParentPathFor(normalizedPath),
    ).create(recursive: true);
    if (isPackagePath(normalizedPath)) {
      await Directory(normalizedPath).create(recursive: true);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_databasePathPreferenceKey, normalizedPath);
  }

  Future<String> getCurrentFolderPath() async {
    return containerParentPathFor(await getCurrentDatabasePath());
  }

  Future<String> defaultLibrariesDirectory() async {
    if (Platform.isAndroid) {
      // Scoped storage blocks raw file access to user-chosen folders in shared
      // storage, so libraries live in the app-specific external directory
      // (falling back to internal storage if external is unavailable).
      final externalDirectory = await getExternalStorageDirectory();
      final baseDirectory =
          externalDirectory ?? await getApplicationDocumentsDirectory();
      return p.join(baseDirectory.path, 'Classi');
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return p.join(documentsDirectory.path, 'Classi');
  }

  /// Lists the `.classi` library packages that live in the default libraries
  /// directory, sorted by path.  Used on Android, where the SAF folder picker
  /// cannot reach the app-specific storage directory.
  Future<List<String>> listLibraryPackages() async {
    final directory = Directory(await defaultLibrariesDirectory());
    if (!await directory.exists()) {
      return const <String>[];
    }

    final packages = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is Directory && isPackagePath(entity.path)) {
        packages.add(p.normalize(entity.path));
      }
    }
    packages.sort();
    return packages;
  }

  Future<String> createUniqueImportedDatabasePath(String preferredName) async {
    final librariesDirectory = await defaultLibrariesDirectory();
    final normalizedName = normalizeDatabasePackageName(preferredName);
    final stem = p.basenameWithoutExtension(normalizedName);
    var candidatePath = p.join(librariesDirectory, normalizedName);
    var counter = 2;

    while (await databasePathExists(candidatePath)) {
      candidatePath = p.join(librariesDirectory, '$stem-$counter.classi');
      counter += 1;
    }

    return candidatePath;
  }

  Future<void> moveTo(String newFolderPath) async {
    await Directory(newFolderPath).create(recursive: true);

    final currentPath = await getCurrentDatabasePath();
    final targetPath = p.join(newFolderPath, p.basename(currentPath));

    if (p.equals(containerParentPathFor(currentPath), newFolderPath)) {
      return;
    }

    if (isPackagePath(currentPath)) {
      final sourceDirectory = Directory(currentPath);
      final targetDirectory = Directory(targetPath);
      if (await sourceDirectory.exists()) {
        await _copyDirectory(sourceDirectory, targetDirectory);
        await sourceDirectory.delete(recursive: true);
      }
    } else {
      final currentFile = await getDatabaseFile();
      final targetFile = File(
        p.join(newFolderPath, p.basename(currentFile.path)),
      );

      if (await currentFile.exists()) {
        await currentFile.copy(targetFile.path);
      }

      for (final ext in _sidecars) {
        final sourceSidecar = File('${currentFile.path}$ext');
        if (await sourceSidecar.exists()) {
          await sourceSidecar.copy('${targetFile.path}$ext');
          await sourceSidecar.delete();
        }
      }

      if (await currentFile.exists()) {
        await currentFile.delete();
      }
    }

    await setDatabaseFilePath(targetPath);
  }

  Future<List<String>> sidecarPaths() async {
    return artifactPathsFor(await getCurrentDatabasePath()).skip(1).toList();
  }

  static String normalizeDatabasePackageName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return defaultLibraryPackageName;
    }

    return trimmed.toLowerCase().endsWith('.classi')
        ? trimmed
        : '$trimmed.classi';
  }

  static bool isPackagePath(String path) =>
      path.toLowerCase().endsWith('.classi');

  static String databaseFilePathFor(String path) {
    if (isPackagePath(path)) {
      return p.join(path, _internalDbFileName);
    }
    return path;
  }

  static String projectSettingsPathFor(String path) =>
      '${databaseFilePathFor(path)}.settings.json';

  static String containerParentPathFor(String path) {
    if (isPackagePath(path)) {
      return p.dirname(path);
    }
    return p.dirname(path);
  }

  static List<String> artifactPathsFor(String databasePath) {
    final filePath = databaseFilePathFor(databasePath);
    return [filePath, ..._sidecars.map((ext) => '$filePath$ext')];
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final basename = p.basename(entity.path);
      final targetPath = p.join(target.path, basename);
      if (entity is File) {
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(targetPath));
      }
    }
  }
}
