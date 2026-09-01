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

      // Homework and material stay untouched. Marking a student absent used to
      // hard-delete both logs for that day, so a mis-tap silently destroyed
      // records that undoing the absence could not bring back. Absence and
      // homework are independent facts: a student can be absent and still have
      // handed work in, and the summaries already treat a missing row as
      // "not recorded".
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

  /// Writes absences read from WebUntis into the attendance log.
  ///
  /// The import never destroys what a teacher recorded themselves:
  ///
  /// * A day with no record yet is written as absent.
  /// * A day already marked absent only has its excuse status corrected.
  /// * A day the teacher marked *present* is left alone unless
  ///   [overwriteExisting] is set, and is reported as skipped either way.
  ///
  /// An absence Classi holds but WebUntis does not know about is never
  /// deleted, in both modes: WebUntis only sees the lessons it manages, and a
  /// teacher's own record of a missing student is not evidence of an error.
  Future<AttendanceImportResult> importAbsences({
    required List<({int studentId, DateTime date, bool excused})> absences,
    bool overwriteExisting = false,
  }) async {
    if (absences.isEmpty) {
      return const AttendanceImportResult(
        created: 0,
        updated: 0,
        unchanged: 0,
        skipped: 0,
      );
    }

    return _database.transaction(() async {
      var created = 0;
      var updated = 0;
      var unchanged = 0;
      var skipped = 0;

      for (final absence in absences) {
        final date = DateTime(
          absence.date.year,
          absence.date.month,
          absence.date.day,
        );

        final existing =
            await (_database.select(_database.attendanceLogsTable)
                  ..where((table) => table.studentId.equals(absence.studentId))
                  ..where((table) => table.date.equals(date)))
                .getSingleOrNull();

        if (existing == null) {
          await _database
              .into(_database.attendanceLogsTable)
              .insert(
                AttendanceLogsTableCompanion.insert(
                  studentId: absence.studentId,
                  date: date,
                  isAbsent: const Value(true),
                  isExcused: Value(absence.excused),
                ),
              );
          created++;
          continue;
        }

        if (!existing.isAbsent && !overwriteExisting) {
          skipped++;
          continue;
        }

        if (existing.isAbsent && existing.isExcused == absence.excused) {
          unchanged++;
          continue;
        }

        await (_database.update(
          _database.attendanceLogsTable,
        )..where((table) => table.id.equals(existing.id))).write(
          AttendanceLogsTableCompanion(
            isAbsent: const Value(true),
            isExcused: Value(absence.excused),
          ),
        );
        updated++;
      }

      return AttendanceImportResult(
        created: created,
        updated: updated,
        unchanged: unchanged,
        skipped: skipped,
      );
    });
  }

  Stream<List<AttendanceLog>> watchAttendanceForStudentInDateRange(
    int studentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    return (_database.select(_database.attendanceLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.isBiggerOrEqualValue(normalizedStart) & 
                     table.date.isSmallerOrEqualValue(normalizedEnd))
          ..orderBy([(table) => OrderingTerm.asc(table.date)]))
        .watch();
  }

  Stream<Map<int, List<AttendanceLog>>> watchAttendanceForGroupInDateRange(
    int groupId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final query = _database.select(_database.attendanceLogsTable).join([
      innerJoin(
        _database.studentsTable,
        _database.studentsTable.id.equalsExp(_database.attendanceLogsTable.studentId),
      ),
    ])
      ..where(_database.studentsTable.groupId.equals(groupId))
      ..where(_database.attendanceLogsTable.date.isBiggerOrEqualValue(normalizedStart))
      ..where(_database.attendanceLogsTable.date.isSmallerOrEqualValue(normalizedEnd))
      ..orderBy([OrderingTerm.asc(_database.attendanceLogsTable.studentId), OrderingTerm.asc(_database.attendanceLogsTable.date)]);

    return query.watch().map((rows) {
      final result = <int, List<AttendanceLog>>{};
      for (final row in rows) {
        final log = row.readTable(_database.attendanceLogsTable);
        result.putIfAbsent(log.studentId, () => []).add(log);
      }
      return result;
    });
  }
}

/// What an attendance import changed, so the UI can report it without
/// guessing.
class AttendanceImportResult {
  const AttendanceImportResult({
    required this.created,
    required this.updated,
    required this.unchanged,
    required this.skipped,
  });

  /// Days that had no attendance record and are now marked absent.
  final int created;

  /// Days whose record changed, i.e. an excuse status that moved, or a day
  /// flipped from present to absent while overwriting.
  final int updated;

  /// Days that already said exactly this.
  final int unchanged;

  /// Days the teacher had marked present and that were left untouched.
  final int skipped;

  int get total => created + updated + unchanged + skipped;

  bool get changedAnything => created > 0 || updated > 0;
}
