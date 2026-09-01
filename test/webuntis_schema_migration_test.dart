import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Builds an in-memory database with the schema of app version 25, before
/// groups and students knew anything about WebUntis.
AppDatabase openVersion25Database(void Function(Database db) seed) {
  return AppDatabase.test(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON;');
        db.execute('''
          CREATE TABLE school_years_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL,
            start_date INTEGER NOT NULL,
            end_date INTEGER NOT NULL,
            archived_at INTEGER NULL,
            created_at INTEGER NOT NULL
          );
        ''');
        db.execute('''
          CREATE TABLE groups_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color_hex TEXT NOT NULL DEFAULT '#FF1E88E5',
            grade_scale_json TEXT NOT NULL DEFAULT '["1","2","3","4","5","6"]',
            grade_categories_json TEXT NOT NULL DEFAULT '[]',
            created_at INTEGER NOT NULL,
            archived_at INTEGER NULL,
            school_year_id INTEGER NULL REFERENCES school_years_table (id)
              ON DELETE SET NULL
          );
        ''');
        db.execute('''
          CREATE TABLE students_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            call_name TEXT NULL,
            group_id INTEGER NOT NULL REFERENCES groups_table (id)
              ON DELETE CASCADE,
            origin_note TEXT NULL,
            created_at INTEGER NOT NULL
              DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
            avatar_json TEXT NULL,
            seat_index INTEGER NULL
          );
        ''');
        seed(db);
        db.execute('PRAGMA user_version = 25;');
      },
    ),
  );
}

int _seconds(DateTime date) => date.millisecondsSinceEpoch ~/ 1000;

void main() {
  late AppDatabase database;

  tearDown(() async {
    await database.close();
  });

  test('upgrading to 26 keeps existing groups and students', () async {
    database = openVersion25Database((db) {
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES (1, ?, ?)',
        ['10A', _seconds(DateTime(2026, 8, 1))],
      );
      db.execute(
        'INSERT INTO students_table '
        '(id, first_name, last_name, group_id, created_at) '
        'VALUES (1, ?, ?, 1, ?)',
        ['Ada', 'Lovelace', _seconds(DateTime(2026, 8, 1))],
      );
    });

    final students = await StudentRepository(database).watchByGroup(1).first;

    expect(students, hasLength(1));
    expect(students.single.firstName, 'Ada');
    // The new columns arrive empty for data that predates them.
    expect(students.single.webuntisStudentId, isNull);

    final groups = await GroupRepository(database).allActiveGroups();
    expect(groups.single.name, '10A');
    expect(groups.single.webuntisKlasseId, isNull);
  });

  test('the migrated columns are writable', () async {
    database = openVersion25Database((db) {
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES (1, ?, ?)',
        ['10A', _seconds(DateTime(2026, 8, 1))],
      );
    });

    final groupRepository = GroupRepository(database);
    final studentRepository = StudentRepository(database);

    await groupRepository.setWebUntisKlasseId(groupId: 1, klasseId: 11);
    await studentRepository.importWebUntisStudents(
      groupId: 1,
      students: const [
        (firstName: 'Ada', lastName: 'Lovelace', webuntisStudentId: 100),
      ],
    );

    expect((await groupRepository.groupsByWebUntisKlasseId())[11]!.id, 1);
    expect(await studentRepository.webUntisStudentIds(1), hasLength(1));
  });
}
