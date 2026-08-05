import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

/// Snapshot of a single active group's activity for one calendar date, used
/// by the Today dashboard to show what still needs attention at a glance.
class TodayGroupOverview {
  const TodayGroupOverview({
    required this.group,
    required this.totalStudents,
    required this.attendanceRecordedCount,
    required this.absentCount,
    required this.gradeCount,
    required this.homeworkCount,
    required this.materialCount,
  });

  final Group group;

  /// Total number of students currently in the group.
  final int totalStudents;

  /// Students with an attendance entry (present or absent) for the date.
  final int attendanceRecordedCount;

  final int absentCount;

  /// Students with at least one grade entry recorded on the date.
  final int gradeCount;

  /// Students with a homework check recorded on the date.
  final int homeworkCount;

  /// Students with a material check recorded on the date.
  final int materialCount;

  /// Whether any lesson data has been logged for this group on the date.
  /// Used to distinguish "not started yet" from "already covered today".
  bool get hasActivity =>
      attendanceRecordedCount > 0 ||
      gradeCount > 0 ||
      homeworkCount > 0 ||
      materialCount > 0;
}

class TodayRepository {
  TodayRepository(this._database);

  final AppDatabase _database;

  /// Watches every active group enriched with [date]'s lesson activity,
  /// ordered by name. Recomputes whenever groups, students, or any of the
  /// tracked logs for [date] change.
  Stream<List<TodayGroupOverview>> watchTodayOverview(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT
        g.id AS g_id,
        g.name AS g_name,
        g.color_hex AS g_color_hex,
        g.grade_scale_json AS g_grade_scale_json,
        g.grade_categories_json AS g_grade_categories_json,
        g.created_at AS g_created_at,
        (SELECT COUNT(*) FROM students_table st WHERE st.group_id = g.id)
          AS total_students,
        (SELECT COUNT(*) FROM attendance_logs_table a
           JOIN students_table st ON st.id = a.student_id
           WHERE st.group_id = g.id AND a.date = ?)
          AS attendance_recorded_count,
        (SELECT COUNT(*) FROM attendance_logs_table a
           JOIN students_table st ON st.id = a.student_id
           WHERE st.group_id = g.id AND a.date = ? AND a.is_absent = 1)
          AS absent_count,
        (SELECT COUNT(DISTINCT ge.student_id) FROM grade_entries_table ge
           JOIN students_table st ON st.id = ge.student_id
           WHERE st.group_id = g.id AND ge.date = ?)
          AS grade_count,
        (SELECT COUNT(*) FROM homework_logs_table h
           JOIN students_table st ON st.id = h.student_id
           WHERE st.group_id = g.id AND h.date = ?)
          AS homework_count,
        (SELECT COUNT(*) FROM material_logs_table m
           JOIN students_table st ON st.id = m.student_id
           WHERE st.group_id = g.id AND m.date = ?)
          AS material_count
      FROM groups_table g
      WHERE g.archived_at IS NULL
      ORDER BY g.name ASC
      ''',
          variables: [
            Variable.withDateTime(normalizedDate),
            Variable.withDateTime(normalizedDate),
            Variable.withDateTime(normalizedDate),
            Variable.withDateTime(normalizedDate),
            Variable.withDateTime(normalizedDate),
          ],
          readsFrom: {
            _database.groupsTable,
            _database.studentsTable,
            _database.attendanceLogsTable,
            _database.gradeEntriesTable,
            _database.homeworkLogsTable,
            _database.materialLogsTable,
          },
        )
        .watch()
        .map((rows) => [for (final row in rows) _rowToOverview(row)]);
  }

  TodayGroupOverview _rowToOverview(QueryRow row) {
    final group = Group(
      id: row.read<int>('g_id'),
      name: row.read<String>('g_name'),
      colorHex: row.read<String>('g_color_hex'),
      gradeScaleJson: row.read<String>('g_grade_scale_json'),
      gradeCategoriesJson: row.read<String>('g_grade_categories_json'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('g_created_at') * 1000,
      ),
    );

    return TodayGroupOverview(
      group: group,
      totalStudents: row.read<int>('total_students'),
      attendanceRecordedCount: row.read<int>('attendance_recorded_count'),
      absentCount: row.read<int>('absent_count'),
      gradeCount: row.read<int>('grade_count'),
      homeworkCount: row.read<int>('homework_count'),
      materialCount: row.read<int>('material_count'),
    );
  }
}
