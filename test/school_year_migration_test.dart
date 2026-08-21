import 'package:classi/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Builds an in-memory database with the schema of app version 22, where
/// timeframes still belonged to a single group.
AppDatabase openLegacyDatabase(void Function(Database db) seed) {
  return AppDatabase.test(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON;');
        db.execute('''
          CREATE TABLE groups_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color_hex TEXT NOT NULL DEFAULT '#FF1E88E5',
            grade_scale_json TEXT NOT NULL DEFAULT '["1","2","3","4","5","6"]',
            grade_categories_json TEXT NOT NULL DEFAULT '[]',
            created_at INTEGER NOT NULL,
            archived_at INTEGER NULL
          );
        ''');
        db.execute('''
          CREATE TABLE students_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL REFERENCES groups_table (id)
              ON DELETE CASCADE
          );
        ''');
        db.execute('''
          CREATE TABLE timeframes_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL REFERENCES groups_table (id)
              ON DELETE CASCADE,
            label TEXT NOT NULL,
            start_date INTEGER NOT NULL,
            end_date INTEGER NOT NULL,
            final_grade TEXT NULL,
            created_at INTEGER NOT NULL
          );
        ''');
        // Present in every real version 22 database (added in version 17),
        // and rewritten by the version 24 migration that adds lesson periods.
        db.execute('''
          CREATE TABLE sessions_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL REFERENCES groups_table (id)
              ON DELETE CASCADE,
            date INTEGER NOT NULL,
            label TEXT NOT NULL,
            description TEXT NULL,
            category_id TEXT NOT NULL DEFAULT 'sonstige-mitarbeit',
            category_name TEXT NOT NULL DEFAULT 'Sonstige Mitarbeit',
            created_at INTEGER NOT NULL,
            UNIQUE (group_id, date, category_id)
          );
        ''');
        db.execute('''
          CREATE TABLE timeframe_grades_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            timeframe_id INTEGER NOT NULL REFERENCES timeframes_table (id)
              ON DELETE CASCADE,
            student_id INTEGER NOT NULL REFERENCES students_table (id)
              ON DELETE CASCADE,
            grade TEXT NOT NULL,
            UNIQUE (timeframe_id, student_id)
          );
        ''');
        seed(db);
        db.execute('PRAGMA user_version = 22;');
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

  test('moves group timeframes onto shared school years', () async {
    database = openLegacyDatabase((db) {
      // Two groups running the same two half-year timeframes, plus a third
      // group from the previous school year.
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES '
        '(1, ?, ?), (2, ?, ?), (3, ?, ?)',
        [
          '10A',
          _seconds(DateTime(2025, 9, 1)),
          '10B',
          _seconds(DateTime(2025, 9, 1)),
          '9C',
          _seconds(DateTime(2024, 9, 1)),
        ],
      );
      db.execute(
        'INSERT INTO students_table (id, group_id) VALUES (1, 1), (2, 2)',
      );
      db.execute(
        'INSERT INTO timeframes_table '
        '(id, group_id, label, start_date, end_date, created_at) VALUES '
        '(1, 1, ?, ?, ?, 0), (2, 2, ?, ?, ?, 0), (3, 1, ?, ?, ?, 0), '
        '(4, 3, ?, ?, ?, 0)',
        [
          'Halbjahr 1',
          _seconds(DateTime(2025, 9, 1)),
          _seconds(DateTime(2026, 1, 31)),
          'Halbjahr 1',
          _seconds(DateTime(2025, 9, 1)),
          _seconds(DateTime(2026, 1, 31)),
          'Halbjahr 2',
          _seconds(DateTime(2026, 2, 1)),
          _seconds(DateTime(2026, 7, 15)),
          'Halbjahr 1',
          _seconds(DateTime(2024, 9, 1)),
          _seconds(DateTime(2025, 1, 31)),
        ],
      );
      // One grade in each group's copy of "Halbjahr 1".
      db.execute(
        'INSERT INTO timeframe_grades_table '
        '(id, timeframe_id, student_id, grade) VALUES (1, 1, 1, ?), (2, 2, 2, ?)',
        ['2', '3'],
      );
    });

    final years = await database.select(database.schoolYearsTable).get();
    expect(years.map((y) => y.label), containsAll(['2024/25', '2025/26']));

    final currentYear = years.firstWhere((y) => y.label == '2025/26');
    final previousYear = years.firstWhere((y) => y.label == '2024/25');
    expect(currentYear.startDate, DateTime(2025, 8, 1));
    expect(currentYear.endDate, DateTime(2026, 7, 31));

    // The two identical "Halbjahr 1" timeframes became one shared timeframe.
    final timeframes = await database.select(database.timeframesTable).get();
    final currentTimeframes = timeframes
        .where((t) => t.schoolYearId == currentYear.id)
        .toList();
    expect(currentTimeframes.map((t) => t.label), ['Halbjahr 1', 'Halbjahr 2']);
    expect(
      timeframes.where((t) => t.schoolYearId == previousYear.id).length,
      1,
    );

    // Both groups' grades survived and now hang off the surviving timeframe.
    final sharedTimeframe = currentTimeframes.first;
    final grades = await database.select(database.timeframeGradesTable).get();
    expect(grades.length, 2);
    expect(
      grades.every((g) => g.timeframeId == sharedTimeframe.id),
      isTrue,
      reason: 'grades should be remapped onto the merged timeframe',
    );
    expect(grades.map((g) => g.grade).toSet(), {'2', '3'});

    // Groups landed in the school year their timeframes ran in.
    final groups = await database.select(database.groupsTable).get();
    expect(
      {for (final group in groups) group.name: group.schoolYearId},
      {'10A': currentYear.id, '10B': currentYear.id, '9C': previousYear.id},
    );
  });

  test('assigns a school year to groups without timeframes', () async {
    database = openLegacyDatabase((db) {
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES (1, ?, ?)',
        ['5A', _seconds(DateTime(2025, 3, 10))],
      );
    });

    final groups = await database.select(database.groupsTable).get();
    final years = await database.select(database.schoolYearsTable).get();
    final assigned = years.firstWhere(
      (y) => y.id == groups.single.schoolYearId,
    );
    // March 2025 belongs to the school year that started in August 2024.
    expect(assigned.label, '2024/25');
  });

  test('keeps timeframes that differ in dates apart', () async {
    database = openLegacyDatabase((db) {
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES '
        '(1, ?, ?), (2, ?, ?)',
        [
          '10A',
          _seconds(DateTime(2025, 9, 1)),
          '10B',
          _seconds(DateTime(2025, 9, 1)),
        ],
      );
      db.execute(
        'INSERT INTO timeframes_table '
        '(id, group_id, label, start_date, end_date, created_at) VALUES '
        '(1, 1, ?, ?, ?, 0), (2, 2, ?, ?, ?, 0)',
        [
          'Halbjahr 1',
          _seconds(DateTime(2025, 9, 1)),
          _seconds(DateTime(2026, 1, 31)),
          'Halbjahr 1',
          _seconds(DateTime(2025, 9, 15)),
          _seconds(DateTime(2026, 1, 31)),
        ],
      );
    });

    final timeframes = await database.select(database.timeframesTable).get();
    expect(timeframes.length, 2);
    expect(
      timeframes.map((t) => t.schoolYearId).toSet().length,
      1,
      reason: 'both belong to the same school year',
    );
  });

  test('a fresh library starts with the current school year', () async {
    database = AppDatabase.test(NativeDatabase.memory());

    final years = await database.select(database.schoolYearsTable).get();
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    expect(
      years.single.label,
      '$startYear/${(startYear + 1).toString().substring(2)}',
    );
    expect(years.single.startDate, DateTime(startYear, 8, 1));
  });
}
