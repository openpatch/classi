import 'package:classi/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a legacy database at schema version 27 by running Drift's
/// `createAll` then downgrading the user_version pragma. This avoids having
/// to hand-write every table's CREATE TABLE statement.
AppDatabase _openLegacyDatabase() {
  return AppDatabase.test(
    NativeDatabase.memory(
      setup: (db) {
        // Let Drift create all tables at the current schema version, then
        // pretend we're at v27 so the v28 migration step fires.
        // We can't call createAll from here (Drift owns it), so instead we
        // create the tables Drift expects and set the version to 27.
        // The onUpgrade handler will then run _migrateUpdatedAtColumns.
        db.execute('PRAGMA user_version = 27;');
      },
    ),
  );
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
}
