@Tags(['cipher-compat'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Checks that a library encrypted by one sqlite3mc build opens in another.
///
/// The app can be built against either the prebuilt `libsqlite3mc.so` the
/// `sqlite3` package downloads, or the same version compiled from the
/// amalgamation (which is what the Flatpak has to do, since Flathub builds
/// offline and from source). If those two disagree about the on-disk format,
/// a teacher moving between the AppImage and the Flatpak silently loses access
/// to their data — so the two halves of this check run under different builds
/// and meet on a file.
///
/// Not part of the normal suite: it needs two builds and an explicit path.
/// Driven by tool/check_cipher_compat.sh.
void main() {
  final path = Platform.environment['CLASSI_COMPAT_DB'];
  final mode = Platform.environment['CLASSI_COMPAT_MODE'];

  test('encrypted database round-trips across sqlite3mc builds', () {
    if (path == null || mode == null) {
      markTestSkipped('Set CLASSI_COMPAT_DB and CLASSI_COMPAT_MODE to run.');
      return;
    }

    // The same pragmas lib/core/database/cipher_opener.dart uses.
    Database open() {
      final database = sqlite3.open(path);
      database.execute("PRAGMA cipher = 'sqlcipher';");
      database.execute('PRAGMA legacy = 4;');
      database.execute("PRAGMA key = 'compat-passphrase';");
      return database;
    }

    final database = open();
    addTearDown(database.close);

    if (mode == 'create') {
      database.execute('CREATE TABLE probe (id INTEGER PRIMARY KEY, v TEXT);');
      database.execute("INSERT INTO probe (v) VALUES ('written by $mode');");
      // Fold the WAL back in so the other build reads a complete file.
      database.execute('PRAGMA wal_checkpoint(TRUNCATE);');
      expect(database.select('SELECT v FROM probe').single['v'], isNotNull);
    } else {
      final rows = database.select('SELECT v FROM probe');
      expect(
        rows.single['v'],
        'written by create',
        reason: 'The other sqlite3mc build could not read this database.',
      );
    }
  });
}
