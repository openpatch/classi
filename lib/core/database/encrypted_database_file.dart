import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'cipher_opener.dart' show openEncryptedDatabase;

/// Opens a library database file with a plain sqlite3 handle.
///
/// Libraries on disk are SQLCipher-encrypted ([openEncryptedDatabase] is what
/// Drift uses), so anything that reads one outside Drift — the schema probe,
/// the sync merge, the conflict diff — has to apply the same cipher pragmas
/// before its first query. Without them the very first statement fails with
/// "file is not a database".
///
/// Pass `null` for [databaseKey] to open a plaintext file; that is only ever
/// the case for test fixtures.
sqlite3.Database openLibraryDatabaseFile(
  String path, {
  required String? databaseKey,
}) {
  final database = sqlite3.sqlite3.open(path);
  if (databaseKey == null) return database;
  try {
    final escapedKey = databaseKey.replaceAll("'", "''");
    database.execute("PRAGMA cipher = 'sqlcipher';");
    database.execute('PRAGMA legacy = 4;');
    database.execute("PRAGMA key = '$escapedKey';");
    return database;
  } on Object {
    database.close();
    rethrow;
  }
}
