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
    bool activity = false,
    bool exam = false,
  }) => AttendanceLog(
    id: nextId++,
    studentId: studentId,
    date: date,
    periodStart: period,
    isAbsent: absent,
    isExcused: excused,
    isLate: late,
    isActivity: activity,
    isExam: exam,
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

  test('counts an activity apart, not as a missed lesson', () {
    final stats = computeGroupAttendanceStats(
      studentIds: [1],
      logs: [
        log(1, monday, period: 1, absent: true, excused: true, activity: true),
        log(1, monday, period: 3, absent: true),
        log(1, tuesday),
        log(
          1,
          tuesday,
          period: 2,
          absent: true,
          excused: true,
          activity: true,
          exam: true,
        ),
      ],
    );

    final student = stats.students.single;
    expect(student.absent, 1);
    expect(student.excused, 0);
    expect(student.activity, 1);
    expect(student.exam, 1);
    expect(student.attendanceRate, closeTo(3 / 4, 1e-9));
    expect(stats.activity, 1);
    expect(stats.exam, 1);
  });

  test('counts a duplicated row once', () {
    final stats = computeGroupAttendanceStats(
      studentIds: [1],
      logs: [log(1, monday, absent: true), log(1, monday, absent: true)],
    );

    expect(stats.students.single.absent, 1);
  });

  test('counts a student against every lesson the group held', () {
    // Attendance taken over from WebUntis only writes absences: student 1
    // has an entry for the one lesson they missed and none for the three
    // they attended, which the group still held.
    final logs = [
      log(1, monday, period: 1, absent: true),
      log(2, monday, period: 3, absent: true),
      log(2, tuesday, period: 1, absent: true, excused: true),
      log(3, tuesday, period: 5, late: true),
    ];
    final stats = studentAttendanceStats(studentId: 1, groupLogs: logs);
    expect(stats.lessons, 4);
    expect(stats.absent, 1);
    expect(stats.present, 3);
    expect(stats.attendanceRate, 0.75);
    final groupRate = computeGroupAttendanceStats(
      studentIds: [1, 2, 3],
      logs: logs,
    ).students.firstWhere((student) => student.studentId == 1).attendanceRate;
    expect(stats.attendanceRate, groupRate);
  });

  test('has no rate before any lesson was held', () {
    final stats = computeGroupAttendanceStats(studentIds: [1], logs: const []);

    expect(stats.lessons, 0);
    expect(stats.students.single.attendanceRate, isNull);
    expect(stats.attendanceRate, isNull);
  });
}
