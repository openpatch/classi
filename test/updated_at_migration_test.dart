import 'dart:io';

import 'package:classi/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Every table that gained `updated_at` in schema v28.
const List<String> _updatedAtTables = [
  'attendance_logs_table',
  'grade_entries_table',
  'groups_table',
  'homework_logs_table',
  'lesson_slots_table',
  'list_items_table',
  'lists_table',
  'material_logs_table',
  'notes_table',
  'school_years_table',
  'seating_plans_table',
  'sessions_table',
  'student_relations_table',
  'students_table',
  'timeframes_table',
  'seating_plan_positions_table',
  'timeframe_grades_table',
];

/// Builds a library file that looks like schema v27 and returns its path.
///
/// Hand-writing seventeen v27 `CREATE TABLE` statements would go stale the
/// moment a table changes, so this lets Drift build the current schema and
/// then rewinds exactly what v28 added: the `updated_at` columns, their
/// triggers, and the version stamp. [seed] runs against the current schema
/// before the rewind, so rows are already in place when the migration runs.
Future<String> _buildLegacyLibrary(
  Directory directory, {
  Future<void> Function(AppDatabase database)? seed,
}) async {
  final path = '${directory.path}/legacy.db';
  final database = AppDatabase.test(NativeDatabase(File(path)));
  await database.customSelect('SELECT 1').getSingle();
  await seed?.call(database);
  await database.close();

  final raw = sqlite3.sqlite3.open(path);
  try {
    for (final table in _updatedAtTables) {
      raw.execute('DROP TRIGGER IF EXISTS ${table}_updated_at_trigger');
      raw.execute('ALTER TABLE $table DROP COLUMN updated_at');
    }
    raw.execute('PRAGMA user_version = 27');
  } finally {
    raw.close();
  }
  return path;
}

void main() {
  test(
    'a fresh library has updated_at on every table',
    () async {
      // A fresh library is created at the current schema version, so it
      // should have updated_at on every table and the triggers from the
      // start.
      final database = AppDatabase.test(NativeDatabase.memory());
      addTearDown(database.close);

      await database.customSelect('SELECT 1').getSingle();

      for (final tableName in [
        'school_years_table',
        'groups_table',
        'students_table',
        'attendance_logs_table',
        'grade_entries_table',
        'homework_logs_table',
        'material_logs_table',
        'sessions_table',
        'timeframes_table',
        'timeframe_grades_table',
        'lesson_slots_table',
        'lists_table',
        'list_items_table',
        'notes_table',
        'seating_plans_table',
        'seating_plan_positions_table',
        'student_relations_table',
      ]) {
        final cols = await database.customSelect(
          "PRAGMA table_info('$tableName')",
        ).get();
        final names = {for (final r in cols) r.data['name'] as String};
        expect(
          names,
          contains('updated_at'),
          reason: '$tableName should have updated_at',
        );
      }
    },
  );

  test(
    'updated_at is set automatically on UPDATE via trigger',
    () async {
      final database = AppDatabase.test(NativeDatabase.memory());
      addTearDown(database.close);

      await database.customSelect('SELECT 1').getSingle();

      await database.customStatement(
        "INSERT INTO groups_table (name, school_year_id) VALUES ('Test', 1)",
      );
      await database.customStatement(
        "INSERT INTO students_table (first_name, last_name, group_id) "
        "VALUES ('Anna', 'Schmidt', 1)",
      );

      final before = await database.customSelect(
        'SELECT updated_at FROM students_table WHERE id = 1',
      ).get();
      final beforeTs = before.first.read<int>('updated_at');

      await Future<void>.delayed(const Duration(seconds: 1));

      await database.customStatement(
        "UPDATE students_table SET first_name = 'Marie' WHERE id = 1",
      );

      final after = await database.customSelect(
        'SELECT updated_at FROM students_table WHERE id = 1',
      ).get();
      final afterTs = after.first.read<int>('updated_at');

      expect(
        afterTs,
        greaterThan(beforeTs),
        reason: 'updated_at should advance on UPDATE',
      );
    },
  );

  test('updated_at trigger exists for every table', () async {
    final database = AppDatabase.test(NativeDatabase.memory());
    addTearDown(database.close);

    await database.customSelect('SELECT 1').getSingle();

    final triggers = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'trigger' "
      "AND name LIKE '%_updated_at_trigger'",
    ).get();
    final triggerNames = {
      for (final r in triggers) r.data['name'] as String,
    };

    for (final tableName in [
      'school_years_table',
      'groups_table',
      'students_table',
      'attendance_logs_table',
      'grade_entries_table',
      'homework_logs_table',
      'material_logs_table',
      'sessions_table',
      'timeframes_table',
      'timeframe_grades_table',
      'lesson_slots_table',
      'lists_table',
      'list_items_table',
      'notes_table',
      'seating_plans_table',
      'seating_plan_positions_table',
      'student_relations_table',
    ]) {
      expect(
        triggerNames,
        contains('${tableName}_updated_at_trigger'),
        reason: '$tableName should have an updated_at trigger',
      );
    }
  });

  group('upgrading an existing library', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('updated-at-migration');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('a v27 library gains updated_at on every table', () async {
      final path = await _buildLegacyLibrary(tempDir);

      final database = AppDatabase.test(NativeDatabase(File(path)));
      addTearDown(database.close);
      await database.customSelect('SELECT 1').getSingle();

      for (final table in _updatedAtTables) {
        final cols = await database.customSelect(
          "PRAGMA table_info('$table')",
        ).get();
        final names = {for (final r in cols) r.data['name'] as String};
        expect(
          names,
          contains('updated_at'),
          reason: '$table should have updated_at after the upgrade',
        );
      }
    });

    test('existing rows are backfilled from created_at', () async {
      final path = await _buildLegacyLibrary(
        tempDir,
        seed: (database) async {
          await database.customStatement(
            "INSERT INTO groups_table (name, school_year_id, created_at) "
            "VALUES ('Test', 1, 1234)",
          );
        },
      );

      final database = AppDatabase.test(NativeDatabase(File(path)));
      addTearDown(database.close);

      final row = await database.customSelect(
        'SELECT created_at, updated_at FROM groups_table',
      ).getSingle();
      expect(row.read<int>('updated_at'), row.read<int>('created_at'));
      expect(row.read<int>('updated_at'), 1234);
    });

    test('the upgrade installs a trigger for every table', () async {
      final path = await _buildLegacyLibrary(tempDir);

      final database = AppDatabase.test(NativeDatabase(File(path)));
      addTearDown(database.close);

      final triggers = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'trigger' "
        "AND name LIKE '%_updated_at_trigger'",
      ).get();
      final names = {for (final r in triggers) r.data['name'] as String};
      for (final table in _updatedAtTables) {
        expect(names, contains('${table}_updated_at_trigger'));
      }
    });
  });

  test('an explicitly written updated_at survives the trigger', () async {
    // The sync merge carries the winning side's timestamp across. A trigger
    // that stamped wall-clock time over it would let a merged row outrank a
    // peer's genuinely newer edit on the next round.
    final database = AppDatabase.test(NativeDatabase.memory());
    addTearDown(database.close);

    await database.customStatement(
      "INSERT INTO groups_table (name, school_year_id) VALUES ('Test', 1)",
    );
    await database.customStatement(
      "INSERT INTO students_table (first_name, last_name, group_id) "
      "VALUES ('Anna', 'Schmidt', 1)",
    );

    await database.customStatement(
      "UPDATE students_table SET first_name = 'Marie', updated_at = 4242 "
      "WHERE id = 1",
    );

    final row = await database.customSelect(
      'SELECT updated_at FROM students_table WHERE id = 1',
    ).getSingle();
    expect(row.read<int>('updated_at'), 4242);
  });
}
