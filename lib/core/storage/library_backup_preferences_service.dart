import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class LibraryBackupPreferencesService {
  static const String _autoExportEnabledKey = 'backup.auto_export_enabled';
  static const String _autoExportFolderPathKey = 'backup.auto_export_folder';
  static const String _autoImportEnabledKey = 'backup.auto_import_enabled';
  static const String _autoImportBackupPathKey = 'backup.auto_import_backup';

  Future<bool> autoExportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoExportEnabledKey) ?? false;
  }

  Future<void> setAutoExportEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoExportEnabledKey, value);
  }

  Future<String?> autoExportFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    final folderPath = prefs.getString(_autoExportFolderPathKey);
    if (folderPath == null || folderPath.isEmpty) {
      return null;
    }
    return p.normalize(folderPath);
  }

  Future<void> setAutoExportFolderPath(String? folderPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (folderPath == null || folderPath.trim().isEmpty) {
      await prefs.remove(_autoExportFolderPathKey);
      return;
    }
    await prefs.setString(_autoExportFolderPathKey, p.normalize(folderPath));
  }

  Future<bool> autoImportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoImportEnabledKey) ?? false;
  }

  Future<void> setAutoImportEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoImportEnabledKey, value);
  }

  Future<String?> autoImportBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    final backupPath = prefs.getString(_autoImportBackupPathKey);
    if (backupPath == null || backupPath.isEmpty) {
      return null;
    }
    return p.normalize(backupPath);
  }

  Future<void> setAutoImportBackupPath(String? backupPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (backupPath == null || backupPath.trim().isEmpty) {
      await prefs.remove(_autoImportBackupPathKey);
      return;
    }
    await prefs.setString(_autoImportBackupPathKey, p.normalize(backupPath));
  }
}
