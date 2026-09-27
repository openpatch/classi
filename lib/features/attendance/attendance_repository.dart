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
    int periodStart = 0,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT a.student_id
      FROM attendance_logs_table a
      JOIN students_table s ON s.id = a.student_id
      WHERE s.group_id = ? AND a.date = ? AND a.period_start = ? AND a.is_absent = 1
      ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
            Variable.withInt(periodStart),
          ],
          readsFrom: {_database.attendanceLogsTable, _database.studentsTable},
        )
        .watch()
        .map((rows) => {for (final row in rows) row.read<int>('student_id')});
  }

  Stream<Set<int>> watchExcusedSelections({
    required int groupId,
    required DateTime date,
    int periodStart = 0,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT a.student_id
      FROM attendance_logs_table a
      JOIN students_table s ON s.id = a.student_id
      WHERE s.group_id = ? AND a.date = ? AND a.period_start = ? AND a.is_absent = 1 AND a.is_excused = 1
      ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
            Variable.withInt(periodStart),
          ],
          readsFrom: {_database.attendanceLogsTable, _database.studentsTable},
        )
        .watch()
        .map((rows) => {for (final row in rows) row.read<int>('student_id')});
  }

  Future<void> setExcused({
    required int studentId,
    required DateTime date,
    int periodStart = 0,
    required bool excused,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.update(_database.attendanceLogsTable)
          ..where((t) => t.studentId.equals(studentId))
          ..where((t) => t.date.equals(normalizedDate))
          ..where((t) => t.periodStart.equals(periodStart))
          ..where((t) => t.isAbsent.equals(true)))
        .write(AttendanceLogsTableCompanion(isExcused: Value(excused)));
  }

  Future<void> clearGroupAbsencesForDate({
    required int groupId,
    required DateTime date,
    int periodStart = 0,
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
                table.date.equals(normalizedDate) &
                table.periodStart.equals(periodStart),
          ))
        .go();
  }

  Future<void> markAbsent({
    required int studentId,
    required DateTime date,
    int periodStart = 0,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    // A day holds at most one attendance row per student, but nothing in the
    // schema enforces that and the sync merge can carry a second one across
    // when two devices logged the same day. Read the whole set rather than
    // `getSingleOrNull`, which throws on the second row, and fold any extras
    // into the one this write keeps.
    final existingLogs =
        await (_database.select(_database.attendanceLogsTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where((table) => table.date.equals(normalizedDate))
              ..where((table) => table.periodStart.equals(periodStart))
              ..orderBy([(table) => OrderingTerm.asc(table.id)]))
            .get();
    final existing = existingLogs.isEmpty ? null : existingLogs.first;

    await _database.transaction(() async {
      if (existing == null) {
        await _database
            .into(_database.attendanceLogsTable)
            .insert(
              AttendanceLogsTableCompanion.insert(
                studentId: studentId,
                date: normalizedDate,
                periodStart: Value(periodStart),
                isAbsent: const Value(true),
              ),
            );
      } else {
        if (!existing.isAbsent || existing.isLate) {
          await (_database.update(_database.attendanceLogsTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(
                const AttendanceLogsTableCompanion(
                  isAbsent: Value(true),
                  isLate: Value(false),
                ),
              );
        }
        for (final duplicate in existingLogs.skip(1)) {
          await (_database.delete(_database.attendanceLogsTable)
                ..where((t) => t.id.equals(duplicate.id)))
              .go();
        }
      }

      // Homework and material stay untouched. Marking a student absent used to
      // hard-delete both logs for that day, so a mis-tap silently destroyed
      // records that undoing the absence could not bring back. Absence and
      // homework are independent facts: a student can be absent and still have
      // handed work in, and the summaries already treat a missing row as
      // "not recorded".
    });
  }

  /// Students of [groupId] marked late on [date].
  Stream<Set<int>> watchLateSelections({
    required int groupId,
    required DateTime date,
    int periodStart = 0,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT a.student_id
      FROM attendance_logs_table a
      JOIN students_table s ON s.id = a.student_id
      WHERE s.group_id = ? AND a.date = ? AND a.period_start = ? AND a.is_absent = 0 AND a.is_late = 1
      ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
            Variable.withInt(periodStart),
          ],
          readsFrom: {_database.attendanceLogsTable, _database.studentsTable},
        )
        .watch()
        .map((rows) => {for (final row in rows) row.read<int>('student_id')});
  }

  /// Records that the student came late on [date]: present, but late. Replaces
  /// an absence, since a student cannot be both.
  Future<void> markLate({
    required int studentId,
    required DateTime date,
    int periodStart = 0,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await _database.transaction(() async {
      await (_database.delete(_database.attendanceLogsTable)
            ..where((t) => t.studentId.equals(studentId))
            ..where((t) => t.date.equals(normalizedDate))
            ..where((t) => t.periodStart.equals(periodStart)))
          .go();
      await _database
          .into(_database.attendanceLogsTable)
          .insert(
            AttendanceLogsTableCompanion.insert(
              studentId: studentId,
              date: normalizedDate,
              periodStart: Value(periodStart),
              isAbsent: const Value(false),
              isLate: const Value(true),
            ),
          );
    });
  }

  Future<void> savePresenceForDate({
    required int groupId,
    required DateTime date,
    int periodStart = 0,
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
              ..where((t) => t.date.equals(normalizedDate))
              ..where((t) => t.periodStart.equals(periodStart)))
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
            periodStart: Value(periodStart),
            isAbsent: const Value(false),
          ),
      ]);
    });
  }

  Future<void> clearAbsence({
    required int studentId,
    required DateTime date,
    int periodStart = 0,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.delete(_database.attendanceLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.equals(normalizedDate))
          ..where((table) => table.periodStart.equals(periodStart)))
        .go();
  }

  /// Takes back an absence, leaving a present or late entry as it is.
  /// Recording homework or material for a student implies they were there.
  Future<void> clearAbsenceOnly({
    required int studentId,
    required DateTime date,
    int periodStart = 0,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.delete(_database.attendanceLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.equals(normalizedDate))
          ..where((table) => table.periodStart.equals(periodStart))
          ..where((table) => table.isAbsent.equals(true)))
        .go();
  }

  /// Makes the attendance of [date] say what WebUntis recorded.
  ///
  /// [absences] maps the absent students to whether their day is excused,
  /// [late] holds those who came late; every other student in [studentIds]
  /// was present. Only [studentIds] are touched, which keeps students
  /// WebUntis does not know about as the teacher left them. Present is
  /// written the way lesson mode writes it, by removing the absence rather
  /// than storing a present row.
  Future<void> applyAttendanceForDate({
    required DateTime date,
    int periodStart = 0,
    required Set<int> studentIds,
    required Map<int, bool> absences,
    Set<int> late = const {},
  }) async {
    if (studentIds.isEmpty) return;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    await _database.transaction(() async {
      final logs =
          await (_database.select(_database.attendanceLogsTable)
                ..where((t) => t.studentId.isIn(studentIds))
                ..where((t) => t.date.equals(normalizedDate))
                ..where((t) => t.periodStart.equals(periodStart))
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
      final byStudent = <int, List<AttendanceLog>>{};
      for (final log in logs) {
        byStudent.putIfAbsent(log.studentId, () => []).add(log);
      }

      for (final studentId in studentIds) {
        final existing = byStudent[studentId] ?? const <AttendanceLog>[];
        final excused = absences[studentId];

        if (excused == null && late.contains(studentId)) {
          final alreadyLate =
              existing.length == 1 &&
              !existing.single.isAbsent &&
              existing.single.isLate;
          if (!alreadyLate) {
            await (_database.delete(_database.attendanceLogsTable)
                  ..where((t) => t.studentId.equals(studentId))
                  ..where((t) => t.date.equals(normalizedDate))
                  ..where((t) => t.periodStart.equals(periodStart)))
                .go();
            await _database
                .into(_database.attendanceLogsTable)
                .insert(
                  AttendanceLogsTableCompanion.insert(
                    studentId: studentId,
                    date: normalizedDate,
                    periodStart: Value(periodStart),
                    isAbsent: const Value(false),
                    isLate: const Value(true),
                  ),
                );
          }
          continue;
        }

        if (excused == null) {
          if (existing.any((log) => log.isAbsent || log.isLate)) {
            await (_database.delete(_database.attendanceLogsTable)
                  ..where((t) => t.studentId.equals(studentId))
                  ..where((t) => t.date.equals(normalizedDate))
                  ..where((t) => t.periodStart.equals(periodStart)))
                .go();
          }
          continue;
        }

        if (existing.isEmpty) {
          await _database
              .into(_database.attendanceLogsTable)
              .insert(
                AttendanceLogsTableCompanion.insert(
                  studentId: studentId,
                  date: normalizedDate,
                  periodStart: Value(periodStart),
                  isAbsent: const Value(true),
                  isExcused: Value(excused),
                ),
              );
          continue;
        }

        // Same folding as [markAbsent]: keep the first row, drop duplicates.
        final kept = existing.first;
        if (!kept.isAbsent || kept.isExcused != excused || kept.isLate) {
          await (_database.update(
            _database.attendanceLogsTable,
          )..where((t) => t.id.equals(kept.id))).write(
            AttendanceLogsTableCompanion(
              isAbsent: const Value(true),
              isExcused: Value(excused),
              isLate: const Value(false),
            ),
          );
        }
        for (final duplicate in existing.skip(1)) {
          await (_database.delete(
            _database.attendanceLogsTable,
          )..where((t) => t.id.equals(duplicate.id))).go();
        }
      }
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

  /// Every attendance entry of the students in [groupId], oldest first.
  Stream<List<AttendanceLog>> watchAttendanceForGroup(int groupId) {
    final query = _database.select(_database.attendanceLogsTable).join([
      innerJoin(
        _database.studentsTable,
        _database.studentsTable.id.equalsExp(
          _database.attendanceLogsTable.studentId,
        ),
      ),
    ])
      ..where(_database.studentsTable.groupId.equals(groupId))
      ..orderBy([OrderingTerm.asc(_database.attendanceLogsTable.date)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows) row.readTable(_database.attendanceLogsTable),
      ],
    );
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
