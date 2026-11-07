import 'dart:io';

import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/exams/data/exam_repository.dart';
import 'package:classi/features/exams/domain/grade_scheme.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Builds a library that looks like schema v35: the current schema with the
/// exam tables and `grade_entries.exam_id` taken out again.
Future<String> _buildV35Library(Directory directory) async {
  final path = '${directory.path}/v35.db';
  final database = AppDatabase.test(NativeDatabase(File(path)));
  final groupId = await GroupRepository(
    database,
  ).createGroup(name: '8a', gradeScale: defaultGradeScaleEntries);
  await database
      .into(database.gradeEntriesTable)
      .insert(
        GradeEntriesTableCompanion.insert(
          studentId: await database
              .into(database.studentsTable)
              .insert(
                StudentsTableCompanion.insert(
                  firstName: 'Ada',
                  lastName: 'Lovelace',
                  groupId: groupId,
                ),
              ),
          date: DateTime(2026, 1, 1),
          sessionLabel: 'Test',
          value: '2',
        ),
      );
  await database.close();

  final raw = sqlite3.sqlite3.open(path);
  try {
    raw.execute('DROP INDEX IF EXISTS idx_grade_entries_exam_id_student_id');
    for (final table in [
      'exam_scores_table',
      'exam_participants_table',
      'exam_expectations_table',
      'exams_table',
    ]) {
      raw.execute('DROP TABLE $table');
    }
    raw.execute('ALTER TABLE grade_entries_table DROP COLUMN exam_id');
    raw.execute('PRAGMA user_version = 35');
  } finally {
    raw.close();
  }
  return path;
}

void main() {
  late Directory directory;

  setUp(
    () => directory = Directory.systemTemp.createTempSync('exam-migration'),
  );
  tearDown(() => directory.deleteSync(recursive: true));

  test('version 36 adds the exam tables and keeps existing grades', () async {
    final path = await _buildV35Library(directory);
    final database = AppDatabase.test(NativeDatabase(File(path)));
    addTearDown(database.close);

    final grades = await database.select(database.gradeEntriesTable).get();
    expect(grades.single.value, '2');
    expect(grades.single.examId, isNull);

    final group = await database.select(database.groupsTable).getSingle();
    final exams = ExamRepository(database);
    final examId = await exams.createExam(
      groupId: group.id,
      title: 'KA',
      date: DateTime(2026, 2, 1),
      categoryId: 'klassenarbeit',
      categoryName: 'Klassenarbeit',
      scheme: const GradeScheme(thresholds: []),
    );
    expect(await exams.getExam(examId), isNotNull);

    final indexes = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_exam%'",
        )
        .get();
    expect(indexes, isNotEmpty);
    final triggers = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'trigger' AND name = 'exam_scores_table_updated_at_trigger'",
        )
        .get();
    expect(triggers, hasLength(1));
    final version = await database
        .customSelect('PRAGMA user_version')
        .map((row) => row.read<int>('user_version'))
        .getSingle();
    expect(version, AppDatabase.currentSchemaVersion);
  });
}
