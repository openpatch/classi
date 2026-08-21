import 'package:classi/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Builds an in-memory database with the schema of app version 23, where
/// sessions had no period and were unique on (group, date, category).
AppDatabase openLegacyDatabase(void Function(Database db) seed) {
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
        seed(db);
        db.execute('PRAGMA user_version = 23;');
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

  test('keeps existing lessons and gives them no period', () async {
    database = openLegacyDatabase((db) {
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES (1, ?, ?)',
        ['10A', _seconds(DateTime(2026, 8, 1))],
      );
      db.execute(
        'INSERT INTO sessions_table '
        '(id, group_id, date, label, category_id, category_name, created_at) '
        'VALUES (1, 1, ?, ?, ?, ?, ?), (2, 1, ?, ?, ?, ?, ?)',
        [
          _seconds(DateTime(2026, 8, 24)),
          'Vectors',
          'sonstige-mitarbeit',
          'Sonstige Mitarbeit',
          _seconds(DateTime(2026, 8, 24)),
          _seconds(DateTime(2026, 8, 28)),
          'Test',
          'klassenarbeit',
          'Klassenarbeit',
          _seconds(DateTime(2026, 8, 28)),
        ],
      );
    });

    final sessions = await database.select(database.sessionsTable).get();

    expect(sessions, hasLength(2));
    expect(sessions.map((s) => s.label), containsAll(['Vectors', 'Test']));
    expect(sessions.map((s) => s.periodStart), everyElement(0));
    expect(sessions.map((s) => s.periodEnd), everyElement(0));
    expect(
      sessions.firstWhere((s) => s.label == 'Test').categoryId,
      'klassenarbeit',
    );
  });

  test('the widened unique key lets one day hold two lessons', () async {
    database = openLegacyDatabase((db) {
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES (1, ?, ?)',
        ['10A', _seconds(DateTime(2026, 8, 1))],
      );
      db.execute(
        'INSERT INTO sessions_table '
        '(id, group_id, date, label, category_id, category_name, created_at) '
        'VALUES (1, 1, ?, ?, ?, ?, ?)',
        [
          _seconds(DateTime(2026, 8, 24)),
          'Morning',
          'sonstige-mitarbeit',
          'Sonstige Mitarbeit',
          _seconds(DateTime(2026, 8, 24)),
        ],
      );
    });

    // Force the migration to run before writing through the new schema.
    await database.select(database.sessionsTable).get();

    await database
        .into(database.sessionsTable)
        .insert(
          SessionsTableCompanion.insert(
            groupId: 1,
            date: DateTime(2026, 8, 24),
            label: 'Afternoon',
            periodStart: const Value(5),
            periodEnd: const Value(6),
          ),
        );

    final sessions = await database.select(database.sessionsTable).get();
    expect(sessions, hasLength(2));
    expect(sessions.map((s) => s.periodStart).toList()..sort(), [0, 5]);
  });

  test('the schedule table is created empty', () async {
    database = openLegacyDatabase((db) {
      db.execute(
        'INSERT INTO groups_table (id, name, created_at) VALUES (1, ?, ?)',
        ['10A', _seconds(DateTime(2026, 8, 1))],
      );
    });

    expect(await database.select(database.lessonSlotsTable).get(), isEmpty);
  });
}
