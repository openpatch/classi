import 'dart:developer' as developer;

import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Connects PowerSync to a Supabase backend.
///
/// This connector authenticates with Supabase and uploads local CRUD
/// operations to the Supabase database. It requires a running PowerSync
/// service endpoint and a Supabase project with the matching table schema.
class ClassiSupabaseConnector extends PowerSyncBackendConnector {
  ClassiSupabaseConnector({
    required this.supabaseClient,
    required this.powerSyncEndpoint,
  });

  final SupabaseClient supabaseClient;
  final String powerSyncEndpoint;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabaseClient.auth.currentSession;
    if (session == null) {
      return null;
    }

    if (session.isExpired) {
      try {
        final refreshed = await supabaseClient.auth.refreshSession();
        if (refreshed.session == null) {
          return null;
        }
      } catch (error, stackTrace) {
        developer.log(
          'Failed to refresh Supabase session.',
          name: 'classi.sync',
          level: 900,
          error: error,
          stackTrace: stackTrace,
        );
        return null;
      }
    }

    final currentSession = supabaseClient.auth.currentSession!;
    return PowerSyncCredentials(
      endpoint: powerSyncEndpoint,
      token: currentSession.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final batch = await database.getCrudBatch(limit: 100);
    if (batch == null) {
      return;
    }

    try {
      for (final op in batch.crud) {
        switch (op.op) {
          case UpdateType.put:
            await supabaseClient
                .from(op.table)
                .upsert({'id': op.id, ...?op.opData});
            break;
          case UpdateType.patch:
            await supabaseClient
                .from(op.table)
                .update(op.opData ?? {})
                .eq('id', op.id);
            break;
          case UpdateType.delete:
            await supabaseClient
                .from(op.table)
                .delete()
                .eq('id', op.id);
            break;
        }
      }
      await batch.complete();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to upload sync batch.',
        name: 'classi.sync',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Signs in the user with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user and disconnects from PowerSync.
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  /// Returns whether a user is currently signed in.
  bool get isSignedIn => supabaseClient.auth.currentSession != null;
}
