import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class AttendanceRepository {
  AttendanceRepository(this._database);

  final AppDatabase _database;

  Stream<Set<String>> watchGroupSelections({
    required String groupId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT a.student_id
      FROM attendance_logs_table a
      JOIN students_table s ON s.id = a.student_id
      WHERE s.group_id = ? AND a.date = ?
      ''',
          variables: [
            Variable.withString(groupId),
            Variable.withDateTime(normalizedDate),
          ],
          readsFrom: {_database.attendanceLogsTable, _database.studentsTable},
        )
        .watch()
        .map(
          (rows) => {for (final row in rows) row.read<String>('student_id')},
        );
  }

  Future<void> markAbsent({
    required String studentId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing =
        await (_database.select(_database.attendanceLogsTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where((table) => table.date.equals(normalizedDate)))
            .getSingleOrNull();

    await _database.transaction(() async {
      if (existing == null) {
        await _database
            .into(_database.attendanceLogsTable)
            .insert(
              AttendanceLogsTableCompanion.insert(
                studentId: studentId,
                date: normalizedDate,
              ),
            );
      }

      await (_database.delete(_database.materialLogsTable)
            ..where((table) => table.studentId.equals(studentId))
            ..where((table) => table.date.equals(normalizedDate)))
          .go();
      await (_database.delete(_database.homeworkLogsTable)
            ..where((table) => table.studentId.equals(studentId))
            ..where((table) => table.date.equals(normalizedDate)))
          .go();
    });
  }

  Future<void> clearAbsence({
    required String studentId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.delete(_database.attendanceLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.equals(normalizedDate)))
        .go();
  }
}
