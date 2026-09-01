import '../../core/storage/project_settings_store.dart';

/// The non-secret half of a WebUntis connection, stored inside the `.classi`
/// project so it travels with the library the same way the WebDAV settings do.
///
/// The app shared secret is deliberately absent: it lives in the platform's
/// secure storage, keyed by database path, and is read through `KeyService`.
class WebUntisConnectionSettings {
  const WebUntisConnectionSettings({
    required this.server,
    required this.school,
    required this.username,
    this.displayName,
    this.lastSyncedAt,
  });

  final String server;
  final String school;
  final String username;

  /// The account name WebUntis reported at connect time, shown in settings so
  /// a teacher can tell which login a library is wired to.
  final String? displayName;

  final DateTime? lastSyncedAt;

  bool get isComplete =>
      server.isNotEmpty && school.isNotEmpty && username.isNotEmpty;
}

/// Persists WebUntis connection settings into the current `.classi` project.
class WebUntisSettingsService {
  WebUntisSettingsService({ProjectSettingsStore? projectSettingsStore})
    : _projectSettingsStore = projectSettingsStore ?? ProjectSettingsStore();

  static const List<String> _serverPath = ['webuntis', 'server'];
  static const List<String> _schoolPath = ['webuntis', 'school'];
  static const List<String> _usernamePath = ['webuntis', 'username'];
  static const List<String> _displayNamePath = ['webuntis', 'displayName'];
  static const List<String> _lastSyncedAtPath = ['webuntis', 'lastSyncedAt'];

  final ProjectSettingsStore _projectSettingsStore;

  Future<WebUntisConnectionSettings?> read() async {
    final settings = await _projectSettingsStore.read();
    final server = ProjectSettingsStore.stringAt(settings, _serverPath) ?? '';
    final school = ProjectSettingsStore.stringAt(settings, _schoolPath) ?? '';
    final username =
        ProjectSettingsStore.stringAt(settings, _usernamePath) ?? '';
    if (server.isEmpty || school.isEmpty || username.isEmpty) {
      return null;
    }

    final displayName = ProjectSettingsStore.stringAt(
      settings,
      _displayNamePath,
    );
    final lastSyncedAt = ProjectSettingsStore.stringAt(
      settings,
      _lastSyncedAtPath,
    );

    return WebUntisConnectionSettings(
      server: server,
      school: school,
      username: username,
      displayName: displayName == null || displayName.isEmpty
          ? null
          : displayName,
      lastSyncedAt: lastSyncedAt == null
          ? null
          : DateTime.tryParse(lastSyncedAt)?.toLocal(),
    );
  }

  Future<void> write(WebUntisConnectionSettings connection) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, _serverPath, connection.server);
      ProjectSettingsStore.setPath(settings, _schoolPath, connection.school);
      ProjectSettingsStore.setPath(
        settings,
        _usernamePath,
        connection.username,
      );
      if (connection.displayName == null || connection.displayName!.isEmpty) {
        ProjectSettingsStore.removePath(settings, _displayNamePath);
      } else {
        ProjectSettingsStore.setPath(
          settings,
          _displayNamePath,
          connection.displayName,
        );
      }
      return settings;
    });
  }

  Future<void> setLastSyncedAt(DateTime value) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(
        settings,
        _lastSyncedAtPath,
        value.toUtc().toIso8601String(),
      );
      return settings;
    });
  }

  Future<void> clear() async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.removePath(settings, _serverPath);
      ProjectSettingsStore.removePath(settings, _schoolPath);
      ProjectSettingsStore.removePath(settings, _usernamePath);
      ProjectSettingsStore.removePath(settings, _displayNamePath);
      ProjectSettingsStore.removePath(settings, _lastSyncedAtPath);
      return settings;
    });
  }
}
