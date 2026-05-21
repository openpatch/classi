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
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Returns the session for [groupId], [date] and [categoryId], if one exists.
  Future<Session?> getSession({
    required int groupId,
    required DateTime date,
    required String categoryId,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return (_database.select(_database.sessionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.date.equals(normalizedDate))
          ..where((t) => t.categoryId.equals(categoryId)))
        .getSingleOrNull();
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

  /// Creates a session or returns the existing one for the (group, date,
  /// category) combination. Returns the session id.
  Future<Session> upsertSession({
    required int groupId,
    required DateTime date,
    required String categoryId,
    required String categoryName,
    String label = '',
    String? description,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing = await getSession(
      groupId: groupId,
      date: normalizedDate,
      categoryId: categoryId,
    );
    if (existing != null) {
      await (_database.update(_database.sessionsTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(
            SessionsTableCompanion(
              label: Value(label),
              categoryName: Value(categoryName),
            ),
          );
      return existing.copyWith(label: label, categoryName: categoryName);
    }

    final id = await _database.into(_database.sessionsTable).insert(
      SessionsTableCompanion.insert(
        groupId: groupId,
        date: normalizedDate,
        label: label,
        categoryId: Value(categoryId),
        categoryName: Value(categoryName),
        description: Value(description),
      ),
    );

    return (_database.select(_database.sessionsTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> updateSession({
    required int id,
    required String label,
    required String? description,
  }) {
    return (_database.update(_database.sessionsTable)
          ..where((t) => t.id.equals(id)))
        .write(
          SessionsTableCompanion(
            label: Value(label),
            description: Value(description),
          ),
        );
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
      ORDER BY s.date DESC
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
        isUtc: true,
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
    final date = DateTime.fromMillisecondsSinceEpoch(rawDate * 1000, isUtc: true);
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at') * 1000,
        isUtc: true,
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
