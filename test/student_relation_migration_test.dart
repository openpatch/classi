import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/seating_plan/student_relation_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an in-memory database with the schema of app version 25, which knew
/// nothing about seating rules yet.
AppDatabase _openLegacyDatabase() {
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
            created_at INTEGER NOT NULL,
            avatar_json TEXT NULL,
            seat_index INTEGER NULL
          );
        ''');
        db.execute(
          "INSERT INTO groups_table (name, created_at) VALUES ('8A', 0);",
        );
        db.execute(
          'INSERT INTO students_table (first_name, last_name, group_id, '
          "created_at) VALUES ('Ada', 'Lovelace', 1, 0), "
          "('Grace', 'Hopper', 1, 0);",
        );
        db.execute('PRAGMA user_version = 25;');
      },
    ),
  );
}

Future<Set<String>> _indexNames(AppDatabase database) async {
  final rows = await database
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name LIKE 'idx_student_relations%'",
      )
      .get();
  return {for (final row in rows) row.read<String>('name')};
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = _openLegacyDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'a version 25 library gains seating rules and keeps its students',
    () async {
      final repository = StudentRelationRepository(database);

      await repository.upsertRelation(
        studentAId: 1,
        studentBId: 2,
        isPositive: false,
        comment: 'talk through every lesson',
      );

      final relations = await repository.watchRelationsForGroup(1).first;
      expect(relations, hasLength(1));
      expect(relations.single.comment, 'talk through every lesson');

      expect(await _indexNames(database), {
        'idx_student_relations_student_a_id',
        'idx_student_relations_student_b_id',
      });
    },
  );
}
