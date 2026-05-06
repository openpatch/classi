import 'package:shared_preferences/shared_preferences.dart';

/// Persists WebDAV backup settings to [SharedPreferences].
class LibraryBackupPreferencesService {
  static const String _autoExportEnabledKey = 'backup.auto_export_enabled';
  static const String _autoImportEnabledKey = 'backup.auto_import_enabled';
  static const String _webDavUrlKey = 'backup.webdav_url';
  static const String _webDavUsernameKey = 'backup.webdav_username';
  static const String _webDavServerPathKey = 'backup.webdav_server_path';
  static const String _lastExportedAtKey = 'backup.last_exported_at';
  static const String _lastImportedAtKey = 'backup.last_imported_at';
  static const String _pendingImportDismissedAtKey =
      'backup.pending_import_dismissed_at';
  static const String _maxVersionsKey = 'backup.max_versions';

  static const int defaultMaxVersions = 3;

  Future<bool> autoExportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoExportEnabledKey) ?? false;
  }

  Future<void> setAutoExportEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoExportEnabledKey, value);
  }

  Future<bool> autoImportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoImportEnabledKey) ?? false;
  }

  Future<void> setAutoImportEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoImportEnabledKey, value);
  }

  Future<String?> webDavUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_webDavUrlKey);
    return (value != null && value.isNotEmpty) ? value : null;
  }

  Future<void> setWebDavUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_webDavUrlKey);
    } else {
      await prefs.setString(_webDavUrlKey, url.trim());
    }
  }

  Future<String?> webDavUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_webDavUsernameKey);
    return (value != null && value.isNotEmpty) ? value : null;
  }

  Future<void> setWebDavUsername(String? username) async {
    final prefs = await SharedPreferences.getInstance();
    if (username == null || username.trim().isEmpty) {
      await prefs.remove(_webDavUsernameKey);
    } else {
      await prefs.setString(_webDavUsernameKey, username.trim());
    }
  }

  Future<String?> webDavServerPath() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_webDavServerPathKey);
    return (value != null && value.isNotEmpty) ? value : null;
  }

  Future<void> setWebDavServerPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(_webDavServerPathKey);
    } else {
      await prefs.setString(_webDavServerPathKey, path.trim());
    }
  }

  Future<DateTime?> lastExportedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastExportedAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setLastExportedAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastExportedAtKey, value.toUtc().toIso8601String());
  }

  Future<DateTime?> lastImportedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastImportedAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setLastImportedAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastImportedAtKey, value.toUtc().toIso8601String());
  }

  /// The server mTime of the backup the user chose to dismiss without
  /// restoring. Cleared automatically when a newer backup appears.
  Future<DateTime?> pendingImportDismissedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_pendingImportDismissedAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setPendingImportDismissedAt(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_pendingImportDismissedAtKey);
    } else {
      await prefs.setString(
        _pendingImportDismissedAtKey,
        value.toUtc().toIso8601String(),
      );
    }
  }

  Future<int> maxVersions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxVersionsKey) ?? defaultMaxVersions;
  }

  Future<void> setMaxVersions(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxVersionsKey, value);
  }
}
