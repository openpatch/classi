import 'package:shared_preferences/shared_preferences.dart';

const _supabaseUrlKey = 'sync.supabase_url';
const _supabaseAnonKeyKey = 'sync.supabase_anon_key';
const _powerSyncUrlKey = 'sync.powersync_url';

/// Stores the user-provided credentials required to connect PowerSync to a
/// Supabase backend.
///
/// All fields are optional. When no configuration has been saved the database
/// operates in local-only mode.
class SyncPreferencesService {
  /// Persists the sync configuration.
  Future<void> saveConfig(SyncConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_supabaseUrlKey, config.supabaseUrl);
    await prefs.setString(_supabaseAnonKeyKey, config.supabaseAnonKey);
    await prefs.setString(_powerSyncUrlKey, config.powerSyncUrl);
  }

  /// Loads the stored sync configuration, or `null` if it has not been set.
  Future<SyncConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final supabaseUrl = prefs.getString(_supabaseUrlKey);
    final supabaseAnonKey = prefs.getString(_supabaseAnonKeyKey);
    final powerSyncUrl = prefs.getString(_powerSyncUrlKey);

    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty ||
        powerSyncUrl == null ||
        powerSyncUrl.isEmpty) {
      return null;
    }

    return SyncConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      powerSyncUrl: powerSyncUrl,
    );
  }

  /// Clears all stored sync credentials.
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_supabaseUrlKey);
    await prefs.remove(_supabaseAnonKeyKey);
    await prefs.remove(_powerSyncUrlKey);
  }

  /// Returns `true` when a complete sync configuration has been saved.
  Future<bool> isConfigured() async {
    return (await loadConfig()) != null;
  }
}

/// Holds the credentials needed to connect to Supabase and PowerSync.
class SyncConfig {
  const SyncConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.powerSyncUrl,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String powerSyncUrl;
}
