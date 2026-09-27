import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/attendance/attendance_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var nextId = 1;
  AttendanceLog log(
    int studentId,
    DateTime date, {
    int period = 0,
    bool absent = false,
    bool excused = false,
    bool late = false,
  }) => AttendanceLog(
    id: nextId++,
    studentId: studentId,
    date: date,
    periodStart: period,
    isAbsent: absent,
    isExcused: excused,
    isLate: late,
    createdAt: date,
    updatedAt: date,
  );

  final monday = DateTime(2026, 9, 7);
  final tuesday = DateTime(2026, 9, 8);

  test('counts lessons per day and period, and sorts by absences', () {
    final stats = computeGroupAttendanceStats(
      studentIds: [1, 2, 3],
      logs: [
        log(1, monday, period: 1),
        log(2, monday, period: 1, absent: true, excused: true),
        log(2, monday, period: 5, absent: true),
        log(3, tuesday, late: true),
      ],
    );

    expect(stats.lessons, 3);
    expect(stats.students.map((s) => s.studentId), [2, 3, 1]);
    final second = stats.students.first;
    expect(second.absent, 2);
    expect(second.excused, 1);
    expect(second.unexcused, 1);
    expect(second.attendanceRate, closeTo(1 / 3, 1e-9));
    expect(stats.students[1].late, 1);
    expect(stats.students[1].attendanceRate, 1);
    expect(stats.absent, 2);
    expect(stats.late, 1);
    expect(stats.attendanceRate, closeTo((1 / 3 + 1 + 1) / 3, 1e-9));
  });

  test('counts a duplicated row once', () {
    final stats = computeGroupAttendanceStats(
      studentIds: [1],
      logs: [log(1, monday, absent: true), log(1, monday, absent: true)],
    );

    expect(stats.students.single.absent, 1);
  });

  test('has no rate before any lesson was held', () {
    final stats = computeGroupAttendanceStats(studentIds: [1], logs: const []);

    expect(stats.lessons, 0);
    expect(stats.students.single.attendanceRate, isNull);
    expect(stats.attendanceRate, isNull);
  });
}
