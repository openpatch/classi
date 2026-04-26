import 'package:shared_preferences/shared_preferences.dart';

class SecurityPreferencesService {
  static const String _lockOnBackgroundKey = 'security.lock_on_background';
  static const String _inactivityTimeoutSecondsKey =
      'security.inactivity_timeout_seconds';
  static const String _sessionDirtyKey = 'security.session_dirty';

  static const Duration defaultInactivityTimeout = Duration(minutes: 5);

  Future<bool> lockOnBackground() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockOnBackgroundKey) ?? true;
  }

  Future<void> setLockOnBackground(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockOnBackgroundKey, value);
  }

  Future<Duration> inactivityTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_inactivityTimeoutSecondsKey);
    if (seconds == null || seconds <= 0) {
      return defaultInactivityTimeout;
    }
    return Duration(seconds: seconds);
  }

  Future<void> setInactivityTimeout(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _inactivityTimeoutSecondsKey,
      duration.inSeconds,
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
}
