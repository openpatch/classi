import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/formatting.dart';

/// Aggregated statistics for a single session shown in the overview table.
class SessionSummary {
  const SessionSummary({
    required this.session,
    required this.totalStudents,
    required this.absentCount,
    required this.homeworkDoneCount,
    required this.homeworkTotalCount,
    required this.materialDoneCount,
    required this.materialTotalCount,
    required this.gradeMean,
  });

  final Session session;

  /// Total number of students currently in the group.
  final int totalStudents;

  /// Number of students marked absent on the session date.
  final int absentCount;

  /// Students whose homework was recorded as completed on the session date.
  final int homeworkDoneCount;

  /// Total students for whom homework was recorded on the session date.
  final int homeworkTotalCount;

  /// Students whose material was recorded as present on the session date.
  final int materialDoneCount;

  /// Total students for whom material was recorded on the session date.
  final int materialTotalCount;

  /// Mean numeric grade across all students for this session, or null if no
  /// grade entries exist yet.
  final double? gradeMean;

  double? get attendancePercent => totalStudents == 0
      ? null
      : ((totalStudents - absentCount) / totalStudents) * 100;

  double? get homeworkPercent => homeworkTotalCount == 0
      ? null
      : (homeworkDoneCount / homeworkTotalCount) * 100;

  double? get materialPercent => materialTotalCount == 0
      ? null
      : (materialDoneCount / materialTotalCount) * 100;
}

class SessionRepository {
  SessionRepository(this._database);

  final AppDatabase _database;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Watches all sessions for [groupId], ordered newest first.
  Stream<List<Session>> watchSessionsForGroup(int groupId) {
    return (_database.select(_database.sessionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.asc(t.periodStart),
          ]))
        .watch();
  }

  /// Returns the session for [groupId], [date], [categoryId] and
  /// [periodStart], if one exists. A group can hold several lessons on one
  /// day, so the period is part of what identifies a session; pass 0 for a
  /// lesson that is not tied to a period.
  Future<Session?> getSession({
    required int groupId,
    required DateTime date,
    required String categoryId,
    int periodStart = 0,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return (_database.select(_database.sessionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.date.equals(normalizedDate))
          ..where((t) => t.categoryId.equals(categoryId))
          ..where((t) => t.periodStart.equals(periodStart)))
        .getSingleOrNull();
  }

  /// The lesson a group holds on [date] for [categoryId], whichever period it
  /// sits in; the earliest one when the day holds several.
  ///
  /// Lesson mode works a day at a time — attendance, homework and material are
  /// all kept per day — so it looks a lesson up by date alone and must not
  /// miss one that was planned into a period.
  Future<Session?> sessionForDate({
    required int groupId,
    required DateTime date,
    required String categoryId,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return (_database.select(_database.sessionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.date.equals(normalizedDate))
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.asc(t.periodStart)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Every session of a group, newest first. Used to infer the group's weekly
  /// pattern from the lessons it already holds.
  Future<List<Session>> sessionsForGroup(int groupId) {
    return (_database.select(_database.sessionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Watches the sessions of a group on [date], ordered by period, so a screen
  /// can tell which of the day's planned lessons are already on the books.
  Stream<List<Session>> watchSessionsOnDate({
    required int groupId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return (_database.select(_database.sessionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.date.equals(normalizedDate))
          ..orderBy([(t) => OrderingTerm.asc(t.periodStart)]))
        .watch();
  }

  /// Watches sessions for [groupId] enriched with attendance, homework,
  /// material, and grade statistics.
  Stream<List<SessionSummary>> watchGroupSessionSummaries(int groupId) {
    return Stream.multi((controller) {
      var gradeScale = defaultGradeScaleEntries;
      var hasGroup = false;
      var hasSessions = false;
      var sessionRows = const <QueryRow>[];
      var gradeRows = const <QueryRow>[];

      void emit() {
        if (!hasGroup || !hasSessions) return;
        controller.add(
          _buildSummaries(sessionRows, gradeRows, gradeScale),
        );
      }

      final groupSub =
          (_database.select(_database.groupsTable)
                ..where((t) => t.id.equals(groupId)))
              .watchSingleOrNull()
              .listen(
                (group) {
                  hasGroup = true;
                  if (group != null) {
                    gradeScale = parseGradeScaleEntries(group.gradeScaleJson);
                  }
                  emit();
                },
                onError: controller.addError,
              );

      final sessionSub = _sessionStatsQuery(groupId).watch().listen(
        (rows) {
          hasSessions = true;
          sessionRows = rows;
          emit();
        },
        onError: controller.addError,
      );

      final gradeSub = _gradeEntriesQuery(groupId).watch().listen(
        (rows) {
          gradeRows = rows;
          emit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await groupSub.cancel();
        await sessionSub.cancel();
        await gradeSub.cancel();
      };
    });
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Creates a session or updates the existing one for the (group, date,
  /// category, period) combination.
  Future<Session> upsertSession({
    required int groupId,
    required DateTime date,
    required String categoryId,
    required String categoryName,
    String label = '',
    String? description,
    int periodStart = 0,
    int periodEnd = 0,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedEnd = periodStart <= 0
        ? 0
        : (periodEnd < periodStart ? periodStart : periodEnd);
    final normalizedStart = periodStart <= 0 ? 0 : periodStart;
    final existing = await getSession(
      groupId: groupId,
      date: normalizedDate,
      categoryId: categoryId,
      periodStart: normalizedStart,
    );
    if (existing != null) {
      await (_database.update(_database.sessionsTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(
            SessionsTableCompanion(
              label: Value(label),
              categoryName: Value(categoryName),
              periodEnd: Value(normalizedEnd),
            ),
          );
      return existing.copyWith(
        label: label,
        categoryName: categoryName,
        periodEnd: normalizedEnd,
      );
    }

    final id = await _database.into(_database.sessionsTable).insert(
      SessionsTableCompanion.insert(
        groupId: groupId,
        date: normalizedDate,
        label: label,
        categoryId: Value(categoryId),
        categoryName: Value(categoryName),
        description: Value(description),
        periodStart: Value(normalizedStart),
        periodEnd: Value(normalizedEnd),
      ),
    );

    return (_database.select(_database.sessionsTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  /// Records the lesson held on [date], attaching to the one already planned
  /// for that date and category whatever period it sits in, rather than
  /// adding a second lesson beside it. Used by lesson mode, which is a
  /// per-day view; [upsertSession] is the period-aware counterpart used when
  /// planning.
  Future<Session> upsertSessionForDate({
    required int groupId,
    required DateTime date,
    required String categoryId,
    required String categoryName,
    String label = '',
  }) async {
    final existing = await sessionForDate(
      groupId: groupId,
      date: date,
      categoryId: categoryId,
    );
    return upsertSession(
      groupId: groupId,
      date: date,
      categoryId: categoryId,
      categoryName: categoryName,
      label: label,
      periodStart: existing?.periodStart ?? 0,
      periodEnd: existing?.periodEnd ?? 0,
    );
  }

  Future<void> updateSession({
    required int id,
    required String label,
    required String? description,
    int? periodStart,
    int? periodEnd,
  }) {
    final normalizedStart = periodStart == null || periodStart <= 0
        ? 0
        : periodStart;
    final normalizedEnd = normalizedStart == 0
        ? 0
        : ((periodEnd ?? normalizedStart) < normalizedStart
              ? normalizedStart
              : periodEnd ?? normalizedStart);

    return (_database.update(_database.sessionsTable)
          ..where((t) => t.id.equals(id)))
        .write(
          SessionsTableCompanion(
            label: Value(label),
            description: Value(description),
            periodStart: periodStart == null
                ? const Value.absent()
                : Value(normalizedStart),
            periodEnd: periodStart == null
                ? const Value.absent()
                : Value(normalizedEnd),
          ),
        );
  }

  /// Creates every lesson in [lessons] that does not exist yet and returns how
  /// many were added. Lessons already on the books are left untouched, so
  /// filling a term twice is harmless and never overwrites what was recorded.
  Future<int> planLessons({
    required int groupId,
    required List<
      ({
        DateTime date,
        int periodStart,
        int periodEnd,
        String categoryId,
        String categoryName,
        String label,
      })
    >
    lessons,
  }) async {
    var created = 0;
    await _database.transaction(() async {
      for (final lesson in lessons) {
        final normalizedDate = DateTime(
          lesson.date.year,
          lesson.date.month,
          lesson.date.day,
        );
        final existing = await getSession(
          groupId: groupId,
          date: normalizedDate,
          categoryId: lesson.categoryId,
          periodStart: lesson.periodStart,
        );
        if (existing != null) continue;

        await _database.into(_database.sessionsTable).insert(
          SessionsTableCompanion.insert(
            groupId: groupId,
            date: normalizedDate,
            label: lesson.label,
            categoryId: Value(lesson.categoryId),
            categoryName: Value(lesson.categoryName),
            periodStart: Value(lesson.periodStart),
            periodEnd: Value(lesson.periodEnd),
          ),
        );
        created++;
      }
    });
    return created;
  }

  Future<void> deleteSession(int id) {
    return (_database.delete(_database.sessionsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Selectable<QueryRow> _sessionStatsQuery(int groupId) {
    return _database.customSelect(
      '''
      SELECT
        s.id,
        s.group_id,
        s.date,
        s.label,
        s.description,
        s.category_id,
        s.category_name,
        s.period_start,
        s.period_end,
        s.created_at,
        (SELECT COUNT(*) FROM students_table WHERE group_id = s.group_id)
          AS total_students,
        (SELECT COUNT(*)
         FROM attendance_logs_table a
         JOIN students_table st ON st.id = a.student_id
         WHERE st.group_id = s.group_id AND a.date = s.date AND a.is_absent = 1)
          AS absent_count,
        (SELECT COUNT(*)
         FROM homework_logs_table h
         JOIN students_table st ON st.id = h.student_id
         WHERE st.group_id = s.group_id AND h.date = s.date)
          AS homework_total_count,
        (SELECT COUNT(*)
         FROM homework_logs_table h
         JOIN students_table st ON st.id = h.student_id
         WHERE st.group_id = s.group_id AND h.date = s.date AND h.had_homework = 1)
          AS homework_done_count,
        (SELECT COUNT(*)
         FROM material_logs_table m
         JOIN students_table st ON st.id = m.student_id
         WHERE st.group_id = s.group_id AND m.date = s.date)
          AS material_total_count,
        (SELECT COUNT(*)
         FROM material_logs_table m
         JOIN students_table st ON st.id = m.student_id
         WHERE st.group_id = s.group_id AND m.date = s.date AND m.had_material = 1)
          AS material_done_count
      FROM sessions_table s
      WHERE s.group_id = ?
      ORDER BY s.date DESC, s.period_start ASC
      ''',
      variables: [Variable.withInt(groupId)],
      readsFrom: {
        _database.sessionsTable,
        _database.studentsTable,
        _database.attendanceLogsTable,
        _database.homeworkLogsTable,
        _database.materialLogsTable,
      },
    );
  }

  Selectable<QueryRow> _gradeEntriesQuery(int groupId) {
    return _database.customSelect(
      '''
      SELECT g.date, g.category_id, g.session_label, g.value
      FROM grade_entries_table g
      JOIN students_table s ON s.id = g.student_id
      WHERE s.group_id = ?
      ''',
      variables: [Variable.withInt(groupId)],
      readsFrom: {_database.gradeEntriesTable, _database.studentsTable},
    );
  }

  List<SessionSummary> _buildSummaries(
    List<QueryRow> sessionRows,
    List<QueryRow> gradeRows,
    List<GradeScaleEntry> gradeScale,
  ) {
    // Pre-index grade values by (date, categoryId, sessionLabel)
    final gradeIndex = <(DateTime, String, String), List<double>>{};
    for (final row in gradeRows) {
      final numericValue = gradeValueToNumber(
        row.read<String>('value'),
        gradeScale,
      );
      if (numericValue == null) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('date') * 1000,
      );
      final normalized = DateTime(date.year, date.month, date.day);
      final categoryId = row.read<String>('category_id');
      final sessionLabel = row.read<String>('session_label');
      gradeIndex
          .putIfAbsent((normalized, categoryId, sessionLabel), () => [])
          .add(numericValue);
    }

    return [
      for (final row in sessionRows)
        _rowToSummary(row, gradeIndex, gradeScale),
    ];
  }

  SessionSummary _rowToSummary(
    QueryRow row,
    Map<(DateTime, String, String), List<double>> gradeIndex,
    List<GradeScaleEntry> gradeScale,
  ) {
    final rawDate = row.read<int>('date');
    final date = DateTime.fromMillisecondsSinceEpoch(rawDate * 1000);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final categoryId = row.read<String>('category_id');
    final sessionLabel = row.read<String>('label');

    final values =
        gradeIndex[(normalizedDate, categoryId, sessionLabel)] ?? const [];
    final gradeMean = values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;

    final session = Session(
      id: row.read<int>('id'),
      groupId: row.read<int>('group_id'),
      date: normalizedDate,
      label: sessionLabel,
      description: row.readNullable<String>('description'),
      categoryId: categoryId,
      categoryName: row.read<String>('category_name'),
      periodStart: row.read<int>('period_start'),
      periodEnd: row.read<int>('period_end'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at') * 1000,
      ),
    );

    return SessionSummary(
      session: session,
      totalStudents: row.read<int>('total_students'),
      absentCount: row.read<int>('absent_count'),
      homeworkDoneCount: row.read<int>('homework_done_count'),
      homeworkTotalCount: row.read<int>('homework_total_count'),
      materialDoneCount: row.read<int>('material_done_count'),
      materialTotalCount: row.read<int>('material_total_count'),
      gradeMean: gradeMean,
    );
  }
}
