import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Reads `PRAGMA user_version` from an encrypted library without going through
/// Drift.
///
/// Drift runs pending migrations as part of opening the database, so the only
/// moment a safety copy can be taken is *before* that — which means the schema
/// version has to be read with a plain sqlite3 handle first.
///
/// Returns `null` when the version cannot be determined (missing file, wrong
/// key, unreadable database). Callers treat that as "don't know" and carry on:
/// this is a safety net, never a gate.
Future<int?> readOnDiskSchemaVersion({
  required File dbFile,
  required String databaseKey,
}) async {
  if (!await dbFile.exists()) {
    return null;
  }

  Database? database;
  try {
    database = sqlite3.open(dbFile.path);
    final escapedKey = databaseKey.replaceAll("'", "''");
    database.execute("PRAGMA cipher = 'sqlcipher';");
    database.execute('PRAGMA legacy = 4;');
    database.execute("PRAGMA key = '$escapedKey';");
    // Keep the probe from writing anything, including a WAL checkpoint.
    database.execute('PRAGMA query_only = ON;');

    final rows = database.select('PRAGMA user_version;');
    if (rows.isEmpty) {
      return null;
    }
    final value = rows.first.values.first;
    return value is int ? value : null;
  } on Object {
    // A wrong key surfaces here as "file is not a database". The real unlock
    // path reports that properly; the probe stays quiet.
    return null;
  } finally {
    database?.close();
  }
}
