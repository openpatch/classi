import 'dart:io';

import 'package:classi/core/sync/merge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Creates a temporary SQLite database with the minimal schema needed for
/// merge tests. All tables have `id`, `name`, `created_at`, and
/// `updated_at` columns.
sqlite3.Database _createTestDatabase() {
  final db = sqlite3.sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE groups_table (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      color_hex TEXT NOT NULL DEFAULT '#FF1E88E5',
      grade_scale_json TEXT NOT NULL DEFAULT '[]',
      grade_categories_json TEXT NOT NULL DEFAULT '[]',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      archived_at INTEGER NULL,
      school_year_id INTEGER NULL,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  db.execute('''
    CREATE TABLE students_table (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      call_name TEXT NULL,
      group_id INTEGER NOT NULL,
      origin_note TEXT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      avatar_json TEXT NULL,
      seat_index INTEGER NULL,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  return db;
}

/// Writes a database's contents to a file and returns the path.
String _dbToFile(sqlite3.Database db, String path) {
  final fileDb = sqlite3.sqlite3.open(path);
  // Copy schema and data.
  for (final table in ['groups_table', 'students_table']) {
    final cols = db.select("PRAGMA table_info('$table')");
    final colNames = cols.map((r) => r['name'] as String).toList();
    final createSql = db.select(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    ).first['sql'] as String;
    fileDb.execute(createSql);
    final rows = db.select('SELECT * FROM $table');
    for (final row in rows) {
      final placeholders = List.filled(colNames.length, '?').join(', ');
      fileDb.execute(
        'INSERT INTO $table (${colNames.join(', ')}) VALUES ($placeholders)',
        colNames.map((c) => row[c]).toList(),
      );
    }
  }
  fileDb.close();
  return path;
}

/// Creates a temporary file path for a database.
String _tempDbPath(Directory dir, String name) =>
    '${dir.path}/$name.db';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('merge-test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('rows added on remote are merged into local', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    // Base has one group, no students.
    base.execute(
      "INSERT INTO groups_table (id, name, created_at, updated_at) "
      "VALUES (1, 'Class A', 1000, 1000)",
    );
    local.execute(
      "INSERT INTO groups_table (id, name, created_at, updated_at) "
      "VALUES (1, 'Class A', 1000, 1000)",
    );
    remote.execute(
      "INSERT INTO groups_table (id, name, created_at, updated_at) "
      "VALUES (1, 'Class A', 1000, 1000)",
    );

    // Remote adds a student.
    remote.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id, "
      "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 2000, 2000)",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    final result = await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    expect(result.hasConflicts, isFalse);
    expect(result.rowsAdded, 1);

    // Verify the student was added to local.
    final merged = sqlite3.sqlite3.open(localPath);
    final students = merged.select('SELECT * FROM students_table');
    expect(students.length, 1);
    expect(students.first['first_name'], 'Anna');
    merged.close();
  });

  test('rows modified on remote override local when newer', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    // All three start with the same student.
    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 1000, 1000)",
      );
    }

    // Local updates the student at time 2000.
    local.execute(
      "UPDATE students_table SET first_name = 'Annie', updated_at = 2000 "
      "WHERE id = 1",
    );

    // Remote updates the student at time 3000 (newer).
    remote.execute(
      "UPDATE students_table SET first_name = 'Annika', updated_at = 3000 "
      "WHERE id = 1",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    final result = await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    expect(result.hasConflicts, isFalse);
    expect(result.rowsUpdated, 1);

    final merged = sqlite3.sqlite3.open(localPath);
    final students = merged.select('SELECT * FROM students_table');
    expect(students.first['first_name'], 'Annika');
    merged.close();
  });

  test('local changes are kept when local is newer', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 1000, 1000)",
      );
    }

    // Local updates at time 3000 (newer).
    local.execute(
      "UPDATE students_table SET first_name = 'Annie', updated_at = 3000 "
      "WHERE id = 1",
    );

    // Remote updates at time 2000 (older).
    remote.execute(
      "UPDATE students_table SET first_name = 'Annika', updated_at = 2000 "
      "WHERE id = 1",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    final result = await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    expect(result.hasConflicts, isFalse);
    // Local was already correct, so no update needed.
    expect(result.rowsUpdated, 0);

    final merged = sqlite3.sqlite3.open(localPath);
    final students = merged.select('SELECT * FROM students_table');
    expect(students.first['first_name'], 'Annie');
    merged.close();
  });

  test('non-overlapping changes merge without conflict', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    // Base has two students.
    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 1000, 1000)",
      );
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (2, 'Ben', 'Bauer', 1, 1000, 1000)",
      );
    }

    // Local changes student 1.
    local.execute(
      "UPDATE students_table SET first_name = 'Annie', updated_at = 2000 "
      "WHERE id = 1",
    );

    // Remote changes student 2.
    remote.execute(
      "UPDATE students_table SET first_name = 'Benjamin', updated_at = 3000 "
      "WHERE id = 2",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    final result = await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    expect(result.hasConflicts, isFalse);
    expect(result.rowsUpdated, 1);

    final merged = sqlite3.sqlite3.open(localPath);
    final students = merged.select(
      'SELECT * FROM students_table ORDER BY id',
    );
    expect(students[0]['first_name'], 'Annie');
    expect(students[1]['first_name'], 'Benjamin');
    merged.close();
  });

  test('same-timestamp changes to the same row surface a conflict', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 1000, 1000)",
      );
    }

    // Both sides update at the same timestamp with different content.
    local.execute(
      "UPDATE students_table SET first_name = 'Annie', updated_at = 2000 "
      "WHERE id = 1",
    );
    remote.execute(
      "UPDATE students_table SET first_name = 'Annika', updated_at = 2000 "
      "WHERE id = 1",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    final result = await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    expect(result.hasConflicts, isTrue);
    expect(result.conflicts.length, 1);
    expect(result.conflicts.first.tableName, 'students_table');
    expect(result.conflicts.first.rowId, 1);
  });

  test('rows deleted on one side and unchanged on the other are deleted', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 1000, 1000)",
      );
    }

    // Local deletes the student.
    local.execute('DELETE FROM students_table WHERE id = 1');

    // Remote keeps it unchanged.

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    final result = await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    expect(result.hasConflicts, isFalse);

    final merged = sqlite3.sqlite3.open(localPath);
    final students = merged.select('SELECT * FROM students_table');
    expect(students, isEmpty);
    merged.close();
  });

  test('rows deleted on one side and modified on the other surface a conflict', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 1000, 1000)",
      );
    }

    // Local deletes the student.
    local.execute('DELETE FROM students_table WHERE id = 1');

    // Remote modifies it.
    remote.execute(
      "UPDATE students_table SET first_name = 'Annika', updated_at = 2000 "
      "WHERE id = 1",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    final result = await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    expect(result.hasConflicts, isTrue);
    expect(result.conflicts.length, 1);
    expect(result.conflicts.first.description, contains('deleted locally'));
  });

  test('an inserted row keeps the primary key it had on the remote', () async {
    // Child tables store the parent's id and are copied across by this same
    // merge, so a row that arrives under a fresh autoincrement id silently
    // repoints every reference to it.
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO groups_table (id, name, created_at, updated_at) "
        "VALUES (1, 'Class A', 1000, 1000)",
      );
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 1, 1000, 1000)",
      );
      db.execute(
        "INSERT INTO students_table (id, first_name, last_name, group_id, "
        "created_at, updated_at) VALUES (2, 'Ben', 'Klein', 1, 1000, 1000)",
      );
    }

    // Local drops a student, so the ids it would hand out no longer line up
    // with the remote's.
    local.execute('DELETE FROM students_table WHERE id = 2');

    // Remote adds a student well above the local high-water mark.
    remote.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id, "
      "created_at, updated_at) VALUES (9, 'Zoe', 'Wagner', 1, 2000, 2000)",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    await MergeService().merge(
      basePath: basePath,
      localPath: localPath,
      remotePath: remotePath,
      baseKey: null,
      localKey: null,
      remoteKey: null,
    );

    final merged = sqlite3.sqlite3.open(localPath);
    final zoe = merged.select(
      "SELECT id FROM students_table WHERE first_name = 'Zoe'",
    );
    expect(zoe.length, 1);
    expect(zoe.first['id'], 9);
    merged.close();
  });

  test('a failed merge leaves the local library untouched', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    for (final db in [base, local, remote]) {
      db.execute(
        "INSERT INTO groups_table (id, name, created_at, updated_at) "
        "VALUES (1, 'Class A', 1000, 1000)",
      );
    }
    // Remote adds a group and a student; the student cannot be written
    // because local's students_table is missing by the time it is reached.
    remote.execute(
      "INSERT INTO groups_table (id, name, created_at, updated_at) "
      "VALUES (2, 'Class B', 2000, 2000)",
    );
    remote.execute(
      "INSERT INTO students_table (id, first_name, last_name, group_id, "
      "created_at, updated_at) VALUES (1, 'Anna', 'Schmidt', 2, 2000, 2000)",
    );

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    // Give local a NOT NULL column the remote snapshot knows nothing about,
    // so writing the student throws — after groups_table has already been
    // written.
    final sabotaged = sqlite3.sqlite3.open(localPath);
    sabotaged.execute(
      "ALTER TABLE students_table ADD COLUMN required_note TEXT NOT NULL "
      "DEFAULT ''",
    );
    sabotaged.close();

    await expectLater(
      MergeService().merge(
        basePath: basePath,
        localPath: localPath,
        remotePath: remotePath,
        baseKey: null,
        localKey: null,
        remoteKey: null,
      ),
      throwsA(anything),
    );

    // The group written before the failure must have been rolled back.
    final merged = sqlite3.sqlite3.open(localPath);
    final groups = merged.select('SELECT id FROM groups_table ORDER BY id');
    expect(groups.map((r) => r['id']), [1]);
    merged.close();
  });

  test('a merge across schema versions is refused', () async {
    final base = _createTestDatabase();
    final local = _createTestDatabase();
    final remote = _createTestDatabase();

    final basePath = _dbToFile(base, _tempDbPath(tempDir, 'base'));
    final localPath = _dbToFile(local, _tempDbPath(tempDir, 'local'));
    final remotePath = _dbToFile(remote, _tempDbPath(tempDir, 'remote'));

    for (final entry in {basePath: 28, localPath: 29, remotePath: 29}.entries) {
      final db = sqlite3.sqlite3.open(entry.key);
      db.execute('PRAGMA user_version = ${entry.value}');
      db.close();
    }

    await expectLater(
      MergeService().merge(
        basePath: basePath,
        localPath: localPath,
        remotePath: remotePath,
        baseKey: null,
        localKey: null,
        remoteKey: null,
      ),
      throwsA(isA<MergeSchemaMismatch>()),
    );
  });
}
