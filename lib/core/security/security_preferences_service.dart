import 'package:shared_preferences/shared_preferences.dart';

import '../storage/project_settings_store.dart';

class SecurityPreferencesService {
  SecurityPreferencesService({ProjectSettingsStore? projectSettingsStore})
    : _projectSettingsStore = projectSettingsStore ?? ProjectSettingsStore();

  static const String _lockOnBackgroundKey = 'security.lock_on_background';
  static const String _inactivityTimeoutSecondsKey =
      'security.inactivity_timeout_seconds';
  static const String _sessionDirtyKey = 'security.session_dirty';
  static const String _biometricEnabledKey = 'security.biometric_enabled';
  static const List<String> _lockOnBackgroundPath = [
    'security',
    'lockOnBackground',
  ];
  static const List<String> _inactivityTimeoutPath = [
    'security',
    'inactivityTimeoutSeconds',
  ];
  static const List<String> _biometricEnabledPath = [
    'security',
    'biometricEnabled',
  ];

  static const Duration defaultInactivityTimeout = Duration(minutes: 5);

  final ProjectSettingsStore _projectSettingsStore;

  Future<bool> lockOnBackground() async {
    final settings = await _projectSettingsStore.read();
    final stored = ProjectSettingsStore.boolAt(settings, _lockOnBackgroundPath);
    if (stored != null) {
      return stored;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getBool(_lockOnBackgroundKey);
    if (legacy != null) {
      if (await _projectSettingsStore.hasProjectContainer()) {
        await _writeBool(
          _lockOnBackgroundPath,
          legacy,
          removeLegacyKey: _lockOnBackgroundKey,
        );
      }
      return legacy;
    }
    return true;
  }

  Future<void> setLockOnBackground(bool value) async {
    await _writeBool(
      _lockOnBackgroundPath,
      value,
      removeLegacyKey: _lockOnBackgroundKey,
    );
  }

  Future<Duration> inactivityTimeout() async {
    final settings = await _projectSettingsStore.read();
    final storedSeconds = ProjectSettingsStore.intAt(
      settings,
      _inactivityTimeoutPath,
    );
    if (storedSeconds != null && storedSeconds > 0) {
      return Duration(seconds: storedSeconds);
    }

    final prefs = await SharedPreferences.getInstance();
    final legacySeconds = prefs.getInt(_inactivityTimeoutSecondsKey);
    if (legacySeconds == null || legacySeconds <= 0) {
      return defaultInactivityTimeout;
    }
    await _writeInt(
      _inactivityTimeoutPath,
      legacySeconds,
      removeLegacyKey: _inactivityTimeoutSecondsKey,
    );
    return Duration(seconds: legacySeconds);
  }

  Future<void> setInactivityTimeout(Duration duration) async {
    await _writeInt(
      _inactivityTimeoutPath,
      duration.inSeconds,
      removeLegacyKey: _inactivityTimeoutSecondsKey,
    );
  }

  Future<bool> wasSessionDirty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionDirtyKey) ?? false;
  }

  Future<void> setSessionDirty(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionDirtyKey, value);
  }

  Future<bool> biometricEnabled() async {
    final settings = await _projectSettingsStore.read();
    final stored = ProjectSettingsStore.boolAt(settings, _biometricEnabledPath);
    if (stored != null) {
      return stored;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getBool(_biometricEnabledKey);
    if (legacy != null) {
      if (await _projectSettingsStore.hasProjectContainer()) {
        await _writeBool(
          _biometricEnabledPath,
          legacy,
          removeLegacyKey: _biometricEnabledKey,
        );
      }
      return legacy;
    }
    return false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _writeBool(
      _biometricEnabledPath,
      value,
      removeLegacyKey: _biometricEnabledKey,
    );
  }

  Future<void> _writeBool(
    List<String> path,
    bool value, {
    required String removeLegacyKey,
  }) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, path, value);
      return settings;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(removeLegacyKey);
  }

  Future<void> _writeInt(
    List<String> path,
    int value, {
    required String removeLegacyKey,
  }) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, path, value);
      return settings;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(removeLegacyKey);
  }
}
