import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class AttendanceRepository {
  AttendanceRepository(this._database);

  final AppDatabase _database;

  Stream<List<AttendanceLog>> watchStudentLogs(int studentId) {
    return (_database.select(_database.attendanceLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..orderBy([(table) => OrderingTerm.desc(table.date)]))
        .watch();
  }

  Stream<Set<int>> watchGroupSelections({
    required int groupId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT a.student_id
      FROM attendance_logs_table a
      JOIN students_table s ON s.id = a.student_id
      WHERE s.group_id = ? AND a.date = ? AND a.is_absent = 1
      ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
          ],
          readsFrom: {_database.attendanceLogsTable, _database.studentsTable},
        )
        .watch()
        .map((rows) => {for (final row in rows) row.read<int>('student_id')});
  }

  Stream<Set<int>> watchExcusedSelections({
    required int groupId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT a.student_id
      FROM attendance_logs_table a
      JOIN students_table s ON s.id = a.student_id
      WHERE s.group_id = ? AND a.date = ? AND a.is_absent = 1 AND a.is_excused = 1
      ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
          ],
          readsFrom: {_database.attendanceLogsTable, _database.studentsTable},
        )
        .watch()
        .map((rows) => {for (final row in rows) row.read<int>('student_id')});
  }

  Future<void> setExcused({
    required int studentId,
    required DateTime date,
    required bool excused,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.update(_database.attendanceLogsTable)
          ..where((t) => t.studentId.equals(studentId))
          ..where((t) => t.date.equals(normalizedDate))
          ..where((t) => t.isAbsent.equals(true)))
        .write(AttendanceLogsTableCompanion(isExcused: Value(excused)));
  }

  Future<void> clearGroupAbsencesForDate({
    required int groupId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final studentIds = await _database
        .customSelect(
          'SELECT id FROM students_table WHERE group_id = ?',
          variables: [Variable.withInt(groupId)],
          readsFrom: {_database.studentsTable},
        )
        .map((row) => row.read<int>('id'))
        .get();

    if (studentIds.isEmpty) return;

    await (_database.delete(_database.attendanceLogsTable)
          ..where(
            (table) =>
                table.studentId.isIn(studentIds) &
                table.date.equals(normalizedDate),
          ))
        .go();
  }

  Future<void> markAbsent({
    required int studentId,
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
                isAbsent: const Value(true),
              ),
            );
      } else if (!existing.isAbsent) {
        await (_database.update(_database.attendanceLogsTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(const AttendanceLogsTableCompanion(isAbsent: Value(true)));
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

  Future<void> savePresenceForDate({
    required int groupId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final studentIds = await _database
        .customSelect(
          'SELECT id FROM students_table WHERE group_id = ?',
          variables: [Variable.withInt(groupId)],
          readsFrom: {_database.studentsTable},
        )
        .map((row) => row.read<int>('id'))
        .get();

    if (studentIds.isEmpty) return;

    final existingStudentIds =
        await (_database.select(_database.attendanceLogsTable)
              ..where((t) => t.studentId.isIn(studentIds))
              ..where((t) => t.date.equals(normalizedDate)))
            .map((row) => row.studentId)
            .get();

    final missingIds =
        studentIds.where((id) => !existingStudentIds.contains(id)).toList();

    if (missingIds.isEmpty) return;

    await _database.batch((batch) {
      batch.insertAll(_database.attendanceLogsTable, [
        for (final studentId in missingIds)
          AttendanceLogsTableCompanion.insert(
            studentId: studentId,
            date: normalizedDate,
            isAbsent: const Value(false),
          ),
      ]);
    });
  }

  Future<void> clearAbsence({
    required int studentId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.delete(_database.attendanceLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.equals(normalizedDate)))
        .go();
  }
}
