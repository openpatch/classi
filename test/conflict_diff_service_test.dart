import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
  test('identical databases report no differences', () {
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

    final summary = ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
    );

    expect(summary.totalDifferences, 0);
    expect(summary.tableSummaries, isEmpty);
  });

  test('rows only on this device are counted', () {
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

    final summary = ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
    );

    expect(summary.rowsOnlyOnThisDevice, 1);
    expect(summary.rowsOnlyOnServer, 0);
    expect(summary.totalDifferences, 1);
    expect(summary.tableSummaries.length, 1);
    expect(summary.tableSummaries.first.displayName, 'Students');
    expect(summary.tableSummaries.first.onlyOnThisDevice, 1);
  });

  test('rows only on server are counted', () {
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

    final summary = ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
    );

    expect(summary.rowsOnlyOnServer, 1);
    expect(summary.totalDifferences, 1);
  });

  test('rows with different content are counted as changed on both', () {
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

    final summary = ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
    );

    expect(summary.rowsChangedOnBoth, 1);
    expect(summary.totalDifferences, 1);
  });

  test('canAutoMerge is true when there are no overlapping changes', () {
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

    final summary = ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
    );

    expect(summary.canAutoMerge, isTrue);
    expect(summary.rowsChangedOnBoth, 0);
    expect(summary.rowsOnlyOnThisDevice, 1);
    expect(summary.rowsOnlyOnServer, 1);
  });

  test('canAutoMerge is false when there are overlapping changes', () {
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

    final summary = ConflictDiffService().compare(
      thisDeviceBytes: backup1,
      serverBytes: backup2,
    );

    expect(summary.canAutoMerge, isFalse);
  });
}
