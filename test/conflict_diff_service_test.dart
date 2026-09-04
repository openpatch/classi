import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:classi/core/database/encrypted_database_file.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/sync/conflict_diff_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Builds a `.classi-backup` ZIP archive from an in-memory SQLite database.
Uint8List _buildBackup(sqlite3.Database db) {
  final dbBytes = File(
    '${Directory.systemTemp.path}/diff-test-${DateTime.now().microsecondsSinceEpoch}.db',
  )..writeAsBytesSync(_dbToBytes(db));
  final archive = Archive();
  archive.addFile(ArchiveFile('data.db', dbBytes.lengthSync(), dbBytes.readAsBytesSync()));
  // Add a minimal manifest.
  archive.addFile(ArchiveFile.string('backup.json', '{"formatVersion":1}'));
  final encoded = Uint8List.fromList(ZipEncoder().encode(archive));
  dbBytes.deleteSync();
  return encoded;
}

/// Serializes an in-memory SQLite database to bytes.
Uint8List _dbToBytes(sqlite3.Database db) {
  // Serialize the in-memory database to a file, then read the bytes.
  final tempPath = '${Directory.systemTemp.path}/serial-${DateTime.now().microsecondsSinceEpoch}.db';
  db.execute('VACUUM INTO ?', [tempPath]);
  final bytes = File(tempPath).readAsBytesSync();
  File(tempPath).deleteSync();
  return bytes;
}

sqlite3.Database _createDatabase() {
  final db = sqlite3.sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE students_table (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      group_id INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  return db;
}

void main() {
  test('identical databases report no differences', () async {
    final db1 = _createDatabase();
    final db2 = _createDatabase();
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );
    db2.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );

    final backup1 = _buildBackup(db1);
    final backup2 = _buildBackup(db2);

    final summary = await ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
      passphrase: null,
    );

    expect(summary.totalDifferences, 0);
    expect(summary.tableSummaries, isEmpty);
  });

  test('rows only on this device are counted', () async {
    final db1 = _createDatabase();
    final db2 = _createDatabase();
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (2, 'Ben', 'Bauer', 1)",
    );
    db2.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );

    final backup1 = _buildBackup(db1);
    final backup2 = _buildBackup(db2);

    final summary = await ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
      passphrase: null,
    );

    expect(summary.rowsOnlyOnThisDevice, 1);
    expect(summary.rowsOnlyOnServer, 0);
    expect(summary.totalDifferences, 1);
    expect(summary.tableSummaries.length, 1);
    expect(summary.tableSummaries.first.displayNameKey, 'students');
    expect(summary.tableSummaries.first.onlyOnThisDevice, 1);
  });

  test('rows only on server are counted', () async {
    final db1 = _createDatabase();
    final db2 = _createDatabase();
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );
    db2.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );
    db2.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (2, 'Ben', 'Bauer', 1)",
    );

    final backup1 = _buildBackup(db1);
    final backup2 = _buildBackup(db2);

    final summary = await ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
      passphrase: null,
    );

    expect(summary.rowsOnlyOnServer, 1);
    expect(summary.totalDifferences, 1);
  });

  test('rows with different content are counted as changed on both', () async {
    final db1 = _createDatabase();
    final db2 = _createDatabase();
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );
    db2.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Annie', 'Schmidt', 1)",
    );

    final backup1 = _buildBackup(db1);
    final backup2 = _buildBackup(db2);

    final summary = await ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
      passphrase: null,
    );

    expect(summary.rowsChangedOnBoth, 1);
    expect(summary.totalDifferences, 1);
  });

  test('canAutoMerge is true when there are no overlapping changes', () async {
    final db1 = _createDatabase();
    final db2 = _createDatabase();
    // Only on this device
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );
    // Only on server
    db2.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (2, 'Ben', 'Bauer', 1)",
    );

    final backup1 = _buildBackup(db1);
    final backup2 = _buildBackup(db2);

    final summary = await ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
      passphrase: null,
    );

    expect(summary.canAutoMerge, isTrue);
    expect(summary.rowsChangedOnBoth, 0);
    expect(summary.rowsOnlyOnThisDevice, 1);
    expect(summary.rowsOnlyOnServer, 1);
  });

  test('canAutoMerge is false when there are overlapping changes', () async {
    final db1 = _createDatabase();
    final db2 = _createDatabase();
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );
    db2.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Annie', 'Schmidt', 1)",
    );

    final backup1 = _buildBackup(db1);
    final backup2 = _buildBackup(db2);

    final summary = await ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
      passphrase: null,
    );

    expect(summary.canAutoMerge, isFalse);
  });

  test('compares SQLCipher-encrypted backups, as shipped libraries are',
      () async {
    // Libraries on disk are encrypted, and the archive carries the raw file.
    // Opening one without applying its key fails on the very first query,
    // which is what a plaintext fixture can never catch.
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('classi-diff-enc');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    const passphrase = 'correct horse battery staple';
    final keyService = KeyService();

    /// Builds an encrypted library plus its security sidecar, and returns
    /// the archive bytes.
    Future<Uint8List> buildEncryptedBackup(
      String name,
      List<String> statements,
    ) async {
      final dir = Directory('${tempDir.path}/$name')..createSync();
      final dbFile = File('${dir.path}/data.db');
      // A low iteration count keeps the test fast; the derivation path is
      // identical either way.
      await keyService.bootstrapSecurity(
        dbFile: dbFile,
        passphrase: passphrase,
        iterations: 1000,
      );
      final key = await keyService.deriveDatabaseKey(
        dbFile: dbFile,
        passphrase: passphrase,
      );

      final db = openLibraryDatabaseFile(dbFile.path, databaseKey: key);
      db.execute('''
        CREATE TABLE students_table (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          group_id INTEGER NOT NULL,
          created_at INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL DEFAULT 0
        )
      ''');
      for (final statement in statements) {
        db.execute(statement);
      }
      db.close();

      final archive = Archive();
      for (final file in dir.listSync().whereType<File>()) {
        final bytes = file.readAsBytesSync();
        archive.addFile(
          ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes),
        );
      }
      archive.addFile(ArchiveFile.string('backup.json', '{"formatVersion":1}'));
      return Uint8List.fromList(ZipEncoder().encode(archive));
    }

    final thisDevice = await buildEncryptedBackup('this-device', [
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
          "VALUES (1, 'Anna', 'Schmidt', 1)",
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
          "VALUES (2, 'Ben', 'Klein', 1)",
    ]);
    final server = await buildEncryptedBackup('server', [
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
          "VALUES (1, 'Anna', 'Schmidt', 1)",
    ]);

    final summary = await ConflictDiffService(keyService: keyService).compare(
      thisDeviceBytes: thisDevice,
      serverBytes: server,
      passphrase: passphrase,
    );

    expect(summary.rowsOnlyOnThisDevice, 1);
    expect(summary.rowsOnlyOnServer, 0);
    expect(summary.tableSummaries.single.displayNameKey, 'students');
  });

  test('runs in a background isolate with no Flutter bindings', () async {
    // The conflict screen offloads this work so the frame pump keeps
    // running. A platform-channel call anywhere on the path would break
    // that, and would do it only in the real app — this pins the property
    // down where it is cheap to notice.
    final db1 = _createDatabase();
    final db2 = _createDatabase();
    db1.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id) "
      "VALUES (1, 'Anna', 'Schmidt', 1)",
    );

    final thisDevice = _buildBackup(db1);
    final server = _buildBackup(db2);

    final summary = await Isolate.run(
      () => ConflictDiffService().compare(
        thisDeviceBytes: thisDevice,
        serverBytes: server,
        passphrase: null,
      ),
    );

    expect(summary.rowsOnlyOnThisDevice, 1);
    expect(summary.tableSummaries.single.displayNameKey, 'students');
  });
}
