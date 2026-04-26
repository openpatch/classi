import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

QueryExecutor openEncryptedDatabase(File dbFile, String passphrase) {
  return NativeDatabase.createInBackground(
    dbFile,
    setup: (database) {
      final escapedPassphrase = passphrase.replaceAll("'", "''");
      database.execute("PRAGMA cipher = 'sqlcipher';");
      database.execute('PRAGMA legacy = 4;');
      database.execute("PRAGMA key = '$escapedPassphrase';");
      database.execute('PRAGMA journal_mode = WAL;');
      database.execute('PRAGMA foreign_keys = ON;');
      database.execute('PRAGMA busy_timeout = 5000;');
      database.execute('PRAGMA secure_delete = ON;');
      database.execute('PRAGMA temp_store = MEMORY;');
    },
  );
}
