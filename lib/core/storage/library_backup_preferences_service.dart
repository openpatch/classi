import 'package:shared_preferences/shared_preferences.dart';

import 'project_settings_store.dart';

/// Persists WebDAV backup settings into the current `.classi` project.
class LibraryBackupPreferencesService {
  LibraryBackupPreferencesService({ProjectSettingsStore? projectSettingsStore})
    : _projectSettingsStore = projectSettingsStore ?? ProjectSettingsStore();

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
  static const String _lastKnownRevisionKey = 'backup.last_known_revision';
  static const List<String> _autoExportEnabledPath = [
    'backup',
    'autoExportEnabled',
  ];
  static const List<String> _autoImportEnabledPath = [
    'backup',
    'autoImportEnabled',
  ];
  static const List<String> _webDavUrlPath = ['backup', 'webDavUrl'];
  static const List<String> _webDavUsernamePath = ['backup', 'webDavUsername'];
  static const List<String> _webDavServerPathPath = [
    'backup',
    'webDavServerPath',
  ];
  static const List<String> _lastExportedAtPath = ['backup', 'lastExportedAt'];
  static const List<String> _lastImportedAtPath = ['backup', 'lastImportedAt'];
  static const List<String> _pendingImportDismissedAtPath = [
    'backup',
    'pendingImportDismissedAt',
  ];
  static const List<String> _maxVersionsPath = ['backup', 'maxVersions'];
  static const List<String> _lastKnownRevisionPath = [
    'backup',
    'lastKnownRevision',
  ];

  static const int defaultMaxVersions = 3;

  final ProjectSettingsStore _projectSettingsStore;

  Future<bool> autoExportEnabled() async {
    return await _readBool(
          path: _autoExportEnabledPath,
          legacyKey: _autoExportEnabledKey,
        ) ??
        false;
  }

  Future<void> setAutoExportEnabled(bool value) async {
    await _writeBool(
      path: _autoExportEnabledPath,
      value: value,
      removeLegacyKey: _autoExportEnabledKey,
    );
  }

  Future<bool> autoImportEnabled() async {
    return await _readBool(
          path: _autoImportEnabledPath,
          legacyKey: _autoImportEnabledKey,
        ) ??
        false;
  }

  Future<void> setAutoImportEnabled(bool value) async {
    await _writeBool(
      path: _autoImportEnabledPath,
      value: value,
      removeLegacyKey: _autoImportEnabledKey,
    );
  }

  Future<String?> webDavUrl() async {
    return _readString(path: _webDavUrlPath, legacyKey: _webDavUrlKey);
  }

  Future<void> setWebDavUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _removePath(path: _webDavUrlPath, removeLegacyKey: _webDavUrlKey);
      return;
    }
    await _writeString(
      path: _webDavUrlPath,
      value: url.trim(),
      removeLegacyKey: _webDavUrlKey,
    );
  }

  Future<String?> webDavUsername() async {
    return _readString(
      path: _webDavUsernamePath,
      legacyKey: _webDavUsernameKey,
    );
  }

  Future<void> setWebDavUsername(String? username) async {
    if (username == null || username.trim().isEmpty) {
      await _removePath(
        path: _webDavUsernamePath,
        removeLegacyKey: _webDavUsernameKey,
      );
      return;
    }
    await _writeString(
      path: _webDavUsernamePath,
      value: username.trim(),
      removeLegacyKey: _webDavUsernameKey,
    );
  }

  Future<String?> webDavServerPath() async {
    return _readString(
      path: _webDavServerPathPath,
      legacyKey: _webDavServerPathKey,
    );
  }

  Future<void> setWebDavServerPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await _removePath(
        path: _webDavServerPathPath,
        removeLegacyKey: _webDavServerPathKey,
      );
      return;
    }
    await _writeString(
      path: _webDavServerPathPath,
      value: path.trim(),
      removeLegacyKey: _webDavServerPathKey,
    );
  }

  /// The revision token of the remote backup this device last synced with
  /// (via export or import), used to detect whether another device has
  /// pushed a conflicting change since. `null` before the first sync.
  Future<String?> lastKnownRevision() async {
    return _readString(
      path: _lastKnownRevisionPath,
      legacyKey: _lastKnownRevisionKey,
    );
  }

  Future<void> setLastKnownRevision(String? revision) async {
    if (revision == null || revision.isEmpty) {
      await _removePath(
        path: _lastKnownRevisionPath,
        removeLegacyKey: _lastKnownRevisionKey,
      );
      return;
    }
    await _writeString(
      path: _lastKnownRevisionPath,
      value: revision,
      removeLegacyKey: _lastKnownRevisionKey,
    );
  }

  Future<DateTime?> lastExportedAt() async {
    return _readDateTime(
      path: _lastExportedAtPath,
      legacyKey: _lastExportedAtKey,
    );
  }

  Future<void> setLastExportedAt(DateTime value) async {
    await _writeString(
      path: _lastExportedAtPath,
      value: value.toUtc().toIso8601String(),
      removeLegacyKey: _lastExportedAtKey,
    );
  }

  Future<DateTime?> lastImportedAt() async {
    return _readDateTime(
      path: _lastImportedAtPath,
      legacyKey: _lastImportedAtKey,
    );
  }

  Future<void> setLastImportedAt(DateTime value) async {
    await _writeString(
      path: _lastImportedAtPath,
      value: value.toUtc().toIso8601String(),
      removeLegacyKey: _lastImportedAtKey,
    );
  }

  /// The server mTime of the backup the user chose to dismiss without
  /// restoring. Cleared automatically when a newer backup appears.
  Future<DateTime?> pendingImportDismissedAt() async {
    return _readDateTime(
      path: _pendingImportDismissedAtPath,
      legacyKey: _pendingImportDismissedAtKey,
    );
  }

  Future<void> setPendingImportDismissedAt(DateTime? value) async {
    if (value == null) {
      await _removePath(
        path: _pendingImportDismissedAtPath,
        removeLegacyKey: _pendingImportDismissedAtKey,
      );
      return;
    }
    await _writeString(
      path: _pendingImportDismissedAtPath,
      value: value.toUtc().toIso8601String(),
      removeLegacyKey: _pendingImportDismissedAtKey,
    );
  }

  Future<int> maxVersions() async {
    return await _readInt(path: _maxVersionsPath, legacyKey: _maxVersionsKey) ??
        defaultMaxVersions;
  }

  Future<void> setMaxVersions(int value) async {
    await _writeInt(
      path: _maxVersionsPath,
      value: value,
      removeLegacyKey: _maxVersionsKey,
    );
  }

  Future<bool?> _readBool({
    required List<String> path,
    required String legacyKey,
  }) async {
    final settings = await _projectSettingsStore.read();
    final stored = ProjectSettingsStore.boolAt(settings, path);
    if (stored != null) {
      return stored;
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getBool(legacyKey);
    if (legacy != null) {
      if (await _projectSettingsStore.hasProjectContainer()) {
        await _writeBool(path: path, value: legacy, removeLegacyKey: legacyKey);
      }
    }
    return legacy;
  }

  Future<int?> _readInt({
    required List<String> path,
    required String legacyKey,
  }) async {
    final settings = await _projectSettingsStore.read();
    final stored = ProjectSettingsStore.intAt(settings, path);
    if (stored != null) {
      return stored;
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getInt(legacyKey);
    if (legacy != null) {
      if (await _projectSettingsStore.hasProjectContainer()) {
        await _writeInt(path: path, value: legacy, removeLegacyKey: legacyKey);
      }
    }
    return legacy;
  }

  Future<String?> _readString({
    required List<String> path,
    required String legacyKey,
  }) async {
    final settings = await _projectSettingsStore.read();
    final stored = ProjectSettingsStore.stringAt(settings, path);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      if (await _projectSettingsStore.hasProjectContainer()) {
        await _writeString(
          path: path,
          value: legacy,
          removeLegacyKey: legacyKey,
        );
      }
      return legacy;
    }
    return null;
  }

  Future<DateTime?> _readDateTime({
    required List<String> path,
    required String legacyKey,
  }) async {
    final value = await _readString(path: path, legacyKey: legacyKey);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> _writeBool({
    required List<String> path,
    required bool value,
    required String removeLegacyKey,
  }) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, path, value);
      return settings;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(removeLegacyKey);
  }

  Future<void> _writeInt({
    required List<String> path,
    required int value,
    required String removeLegacyKey,
  }) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, path, value);
      return settings;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(removeLegacyKey);
  }

  Future<void> _writeString({
    required List<String> path,
    required String value,
    required String removeLegacyKey,
  }) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, path, value);
      return settings;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(removeLegacyKey);
  }

  Future<void> _removePath({
    required List<String> path,
    required String removeLegacyKey,
  }) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.removePath(settings, path);
      return settings;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(removeLegacyKey);
  }
}
