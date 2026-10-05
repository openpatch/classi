import '../../core/database/app_database.dart';
import 'attendance_state.dart';

/// Attendance of one student over the lessons a group held.
class StudentAttendanceStats {
  const StudentAttendanceStats({
    required this.studentId,
    required this.lessons,
    required this.absent,
    required this.excused,
    required this.late,
    this.activity = 0,
    this.exam = 0,
  });

  final int studentId;

  /// Lessons the group held in the period looked at.
  final int lessons;

  /// Lessons missed, excused ones included. Lessons away at a school
  /// activity are not missed and not counted here.
  final int absent;
  final int excused;

  /// Lessons the student came late to. Late counts as present.
  final int late;

  /// Lessons the student spent at a school activity. They do not count
  /// against [attendanceRate].
  final int activity;

  /// Lessons the student spent writing an exam elsewhere. Like [activity],
  /// they do not count against [attendanceRate].
  final int exam;

  int get unexcused => absent - excused;

  /// Share of [lessons] attended, 0–1. `null` when no lesson was held.
  double? get attendanceRate =>
      lessons == 0 ? null : (lessons - absent) / lessons;
}

/// Attendance of a whole group: per student, and summed up for the class.
class GroupAttendanceStats {
  const GroupAttendanceStats({required this.lessons, required this.students});

  /// Lessons the group held: every lesson attendance was taken in.
  final int lessons;

  /// One entry per student, most absences first.
  final List<StudentAttendanceStats> students;

  int get absent => students.fold(0, (sum, s) => sum + s.absent);
  int get excused => students.fold(0, (sum, s) => sum + s.excused);
  int get late => students.fold(0, (sum, s) => sum + s.late);
  int get activity => students.fold(0, (sum, s) => sum + s.activity);
  int get exam => students.fold(0, (sum, s) => sum + s.exam);

  /// The class's attendance rate: the mean of the students' rates. `null`
  /// when no lesson was held or the group has no students.
  double? get attendanceRate {
    final rates = [for (final student in students) ?student.attendanceRate];
    if (rates.isEmpty) return null;
    return rates.reduce((a, b) => a + b) / rates.length;
  }
}

/// Counts [logs] per student of [studentIds].
///
/// A lesson counts as held when any student has an entry for it, keyed by day
/// and first period the way attendance is kept. A student without an entry
/// for a held lesson was present: lesson mode only writes presence rows when
/// a lesson is saved, and absences always.
GroupAttendanceStats computeGroupAttendanceStats({
  required List<int> studentIds,
  required Iterable<AttendanceLog> logs,
}) {
  final lessons = <(DateTime, int)>{};
  final absent = <int, int>{};
  final excused = <int, int>{};
  final late = <int, int>{};
  final activity = <int, int>{};
  final exam = <int, int>{};
  final known = studentIds.toSet();
  // Two rows for one student and lesson (from a sync merge) count once.
  final seen = <(int, DateTime, int)>{};

  for (final log in logs) {
    final day = DateTime(log.date.year, log.date.month, log.date.day);
    lessons.add((day, log.periodStart));
    if (!known.contains(log.studentId) ||
        !seen.add((log.studentId, day, log.periodStart))) {
      continue;
    }
    if (log.isAwayAtExam) {
      exam.update(log.studentId, (n) => n + 1, ifAbsent: () => 1);
    } else if (log.isAwayAtActivity) {
      activity.update(log.studentId, (n) => n + 1, ifAbsent: () => 1);
    } else if (log.isMissed) {
      absent.update(log.studentId, (n) => n + 1, ifAbsent: () => 1);
      if (log.isExcused) {
        excused.update(log.studentId, (n) => n + 1, ifAbsent: () => 1);
      }
    } else if (log.isLate) {
      late.update(log.studentId, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  final students = [
    for (final id in studentIds)
      StudentAttendanceStats(
        studentId: id,
        lessons: lessons.length,
        absent: absent[id] ?? 0,
        excused: excused[id] ?? 0,
        late: late[id] ?? 0,
        activity: activity[id] ?? 0,
        exam: exam[id] ?? 0,
      ),
  ];
  final order = {for (var i = 0; i < studentIds.length; i++) studentIds[i]: i};
  students.sort((a, b) {
    final byAbsent = b.absent.compareTo(a.absent);
    if (byAbsent != 0) return byAbsent;
    final byUnexcused = b.unexcused.compareTo(a.unexcused);
    if (byUnexcused != 0) return byUnexcused;
    final byLate = b.late.compareTo(a.late);
    if (byLate != 0) return byLate;
    return order[a.studentId]!.compareTo(order[b.studentId]!);
  });

  return GroupAttendanceStats(lessons: lessons.length, students: students);
}
