import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import 'lesson_support.dart';

class LessonRepository {
  LessonRepository(this._database);

  final AppDatabase _database;

  Stream<Set<DateTime>> watchGroupEntryDates(int groupId) {
    return Stream.multi((controller) {
      var attendanceDates = <DateTime>{};
      var homeworkDates = <DateTime>{};
      var materialDates = <DateTime>{};
      var gradeDates = <DateTime>{};
      var noteDates = <DateTime>{};
      var hasAttendanceDates = false;
      var hasHomeworkDates = false;
      var hasMaterialDates = false;
      var hasGradeDates = false;
      var hasNoteDates = false;

      void emit() {
        if (!hasAttendanceDates ||
            !hasHomeworkDates ||
            !hasMaterialDates ||
            !hasGradeDates ||
            !hasNoteDates) {
          return;
        }
        controller.add({
          ...attendanceDates,
          ...homeworkDates,
          ...materialDates,
          ...gradeDates,
          ...noteDates,
        });
      }

      final attendanceSubscription =
          _watchStudentLogDates(
            groupId: groupId,
            tableName: 'attendance_logs_table',
            alias: 'a',
            dateColumn: 'date',
            readsFrom: {_database.attendanceLogsTable, _database.studentsTable},
          ).listen((value) {
            attendanceDates = value;
            hasAttendanceDates = true;
            emit();
          }, onError: controller.addError);

      final homeworkSubscription =
          _watchStudentLogDates(
            groupId: groupId,
            tableName: 'homework_logs_table',
            alias: 'h',
            dateColumn: 'date',
            readsFrom: {_database.homeworkLogsTable, _database.studentsTable},
          ).listen((value) {
            homeworkDates = value;
            hasHomeworkDates = true;
            emit();
          }, onError: controller.addError);

      final materialSubscription =
          _watchStudentLogDates(
            groupId: groupId,
            tableName: 'material_logs_table',
            alias: 'm',
            dateColumn: 'date',
            readsFrom: {_database.materialLogsTable, _database.studentsTable},
          ).listen((value) {
            materialDates = value;
            hasMaterialDates = true;
            emit();
          }, onError: controller.addError);

      final gradeSubscription =
          _watchStudentLogDates(
            groupId: groupId,
            tableName: 'grade_entries_table',
            alias: 'g',
            dateColumn: 'date',
            readsFrom: {_database.gradeEntriesTable, _database.studentsTable},
          ).listen((value) {
            gradeDates = value;
            hasGradeDates = true;
            emit();
          }, onError: controller.addError);

      final noteSubscription =
          (_database.select(_database.notesTable)
                ..where((table) => table.groupId.equals(groupId))
                ..where((table) => table.archivedAt.isNull()))
              .watch()
              .map(
                (notes) => {
                  for (final note in notes) normalizeLessonDate(note.createdAt),
                },
              )
              .listen((value) {
                noteDates = value;
                hasNoteDates = true;
                emit();
              }, onError: controller.addError);

      controller.onCancel = () async {
        await attendanceSubscription.cancel();
        await homeworkSubscription.cancel();
        await materialSubscription.cancel();
        await gradeSubscription.cancel();
        await noteSubscription.cancel();
      };
    });
  }

  Stream<Set<DateTime>> _watchStudentLogDates({
    required int groupId,
    required String tableName,
    required String alias,
    required String dateColumn,
    required Set<ResultSetImplementation<dynamic, dynamic>> readsFrom,
  }) {
    return _database
        .customSelect(
          '''
          SELECT DISTINCT $alias.$dateColumn AS entry_date
          FROM $tableName $alias
          JOIN students_table s ON s.id = $alias.student_id
          WHERE s.group_id = ?
          ORDER BY $alias.$dateColumn DESC
          ''',
          variables: [Variable.withInt(groupId)],
          readsFrom: readsFrom,
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              normalizeLessonDate(row.read<DateTime>('entry_date')),
          },
        );
  }
}
