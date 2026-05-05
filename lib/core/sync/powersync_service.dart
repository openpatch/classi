import 'dart:developer' as developer;

import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../storage/sync_preferences_service.dart';
import 'powersync_schema.dart';
import 'supabase_connector.dart';

/// Manages the lifecycle of the [PowerSyncDatabase] and its connection to the
/// optional Supabase sync backend.
///
/// Use [PowerSyncService.open] to create an encrypted local database and
/// obtain a [AppDatabase] backed by PowerSync. Call [connectSync] once sync
/// credentials have been configured to start background synchronisation.
class PowerSyncService {
  PowerSyncService._();

  PowerSyncDatabase? _db;
  ClassiSupabaseConnector? _connector;
  SyncStatus _syncStatus = const SyncStatus();

  SyncStatus get syncStatus => _syncStatus;

  /// Opens (or creates) a PowerSync database at [dbPath] with optional
  /// SQLCipher encryption using the provided [encryptionKey].
  ///
  /// Returns a [AppDatabase] that wraps the PowerSync connection via Drift.
  static Future<(PowerSyncService, AppDatabase)> open({
    required String dbPath,
    required String encryptionKey,
  }) async {
    final service = PowerSyncService._();
    final appDb = await service._open(
      dbPath: dbPath,
      encryptionKey: encryptionKey,
    );
    return (service, appDb);
  }

  Future<AppDatabase> _open({
    required String dbPath,
    required String encryptionKey,
  }) async {
    final db = PowerSyncDatabase(
      schema: classiSchema,
      path: dbPath,
      encryption: EncryptionOptions(key: encryptionKey),
    );
    await db.initialize();
    _db = db;

    _db!.statusStream.listen((status) {
      _syncStatus = status;
    });

    final driftConnection = SqliteAsyncDriftConnection(db);
    return AppDatabase.withConnection(driftConnection, databasePath: dbPath);
  }

  /// Initialises Supabase and starts syncing if credentials are stored.
  ///
  /// Call this after [open] to enable background synchronisation. It is safe
  /// to call when sync is not configured; in that case the database operates
  /// in local-only mode.
  Future<void> connectSyncIfConfigured(
    SyncPreferencesService prefs,
  ) async {
    final config = await prefs.loadConfig();
    if (config == null) {
      return;
    }

    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );

      final supabase = Supabase.instance.client;
      final connector = ClassiSupabaseConnector(
        supabaseClient: supabase,
        powerSyncEndpoint: config.powerSyncUrl,
      );
      _connector = connector;

      if (!connector.isSignedIn) {
        developer.log(
          'Supabase user is not signed in; running in local-only mode.',
          name: 'classi.sync',
        );
        return;
      }

      await _db?.connect(connector: connector);
      developer.log('PowerSync sync connected.', name: 'classi.sync');
    } catch (error, stackTrace) {
      developer.log(
        'Failed to connect PowerSync sync.',
        name: 'classi.sync',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Signs the user in with [email] and [password] and starts syncing.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final connector = _connector;
    if (connector == null) {
      throw StateError(
        'Call connectSyncIfConfigured before signing in.',
      );
    }
    await connector.signIn(email: email, password: password);
    await _db?.connect(connector: connector);
  }

  /// Disconnects from the sync backend and signs out.
  Future<void> signOut() async {
    await _db?.disconnect();
    await _connector?.signOut();
  }

  /// Closes the underlying PowerSync database.
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _connector = null;
  }
}
