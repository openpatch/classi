import 'dart:io';

import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/attendance/attendance_repository.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/homework/homework_repository.dart';
import 'package:classi/features/lessons/lesson_periods.dart';
import 'package:classi/features/sessions/session_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

const _logTables = [
  'attendance_logs_table',
  'homework_logs_table',
  'material_logs_table',
];

const _gradeScale = [
  GradeScaleEntry(label: '1', numericValue: 1),
  GradeScaleEntry(label: '2', numericValue: 2),
];

/// Builds a library that looks like schema v32: logs kept per day, with no
/// period. [seed] runs against the current schema first.
Future<String> _buildV32Library(
  Directory directory,
  Future<void> Function(AppDatabase database) seed,
) async {
  final path = '${directory.path}/v32.db';
  final database = AppDatabase.test(NativeDatabase(File(path)));
  await database.customSelect('SELECT 1').getSingle();
  await seed(database);
  await database.close();

  final raw = sqlite3.sqlite3.open(path);
  try {
    for (final table in _logTables) {
      final base = table.replaceAll('_table', '');
      raw.execute('DROP INDEX IF EXISTS idx_${base}_student_id_date_period');
      raw.execute('ALTER TABLE $table DROP COLUMN period_start');
    }
    raw.execute('PRAGMA user_version = 32');
  } finally {
    raw.close();
  }
  return path;
}

void main() {
  group('lesson periods', () {
    test('parse and encode', () {
      expect(parseLessonPeriods('5-6'), (start: 5, end: 6));
      expect(parseLessonPeriods('3'), (start: 3, end: 3));
      expect(parseLessonPeriods('6-5'), (start: 6, end: 6));
      expect(parseLessonPeriods('x'), isNull);
      expect(parseLessonPeriods(null), isNull);
      expect(encodeLessonPeriods((start: 5, end: 6)), '5-6');
      expect(encodeLessonPeriods((start: 3, end: 3)), '3');
    });

    // Monday: 1 = 08:00–08:45, 2 = 08:50–09:35, 3 = 09:55–10:40.
    final BellTimes bellTimes = {
      DateTime.monday: [
        (start: 480, end: 525),
        (start: 530, end: 575),
        (start: 595, end: 640),
      ],
    };
    final monday = DateTime(2026, 9, 21);

    test('a lesson spans its first to its last period', () {
      expect(lessonMinutes((start: 1, end: 2), DateTime.monday, bellTimes), (
        start: 480,
        end: 575,
      ));
      expect(
        lessonMinutes((start: 3, end: 4), DateTime.monday, bellTimes),
        isNull,
      );
    });

    test('picks the lesson running now, then the next, then the last', () {
      final lessons = [(start: 1, end: 2), (start: 3, end: 3)];
      LessonPeriods? at(int hour, int minute) => pickCurrentLesson(
        lessons: lessons,
        date: monday,
        now: DateTime(2026, 9, 21, hour, minute),
        bellTimes: bellTimes,
      );

      expect(at(7, 30), (start: 1, end: 2));
      expect(at(9, 0), (start: 1, end: 2));
      expect(at(9, 45), (start: 3, end: 3));
      expect(at(15, 0), (start: 3, end: 3));
    });

    test('on another day, or without bell times, the first lesson', () {
      final lessons = [(start: 1, end: 2), (start: 3, end: 3)];
      expect(
        pickCurrentLesson(
          lessons: lessons,
          date: monday,
          now: DateTime(2026, 9, 22, 10),
          bellTimes: bellTimes,
        ),
        (start: 1, end: 2),
      );
      expect(
        pickCurrentLesson(
          lessons: lessons,
          date: monday,
          now: DateTime(2026, 9, 21, 10),
          bellTimes: const {},
        ),
        (start: 1, end: 2),
      );
      expect(
        pickCurrentLesson(
          lessons: const [],
          date: monday,
          now: monday,
          bellTimes: bellTimes,
        ),
        isNull,
      );
    });
  });

  group('two lessons of one group on one day', () {
    late AppDatabase database;
    late AttendanceRepository attendance;
    late HomeworkRepository homework;
    late int groupId;
    late int ada;
    final day = DateTime(2026, 9, 21);

    setUp(() async {
      database = AppDatabase.test(NativeDatabase.memory());
      attendance = AttendanceRepository(database);
      homework = HomeworkRepository(database);
      groupId = await GroupRepository(
        database,
      ).createGroup(name: '10a', gradeScale: _gradeScale);
      ada = await StudentRepository(
        database,
      ).addStudent(groupId: groupId, firstName: 'Ada', lastName: 'A');
    });

    tearDown(() => database.close());

    test('keep their attendance apart', () async {
      await attendance.markAbsent(studentId: ada, date: day, periodStart: 1);
      await attendance.markLate(studentId: ada, date: day, periodStart: 5);

      Future<Set<int>> absent(int period) => attendance
          .watchGroupSelections(
            groupId: groupId,
            date: day,
            periodStart: period,
          )
          .first;
      Future<Set<int>> late(int period) => attendance
          .watchLateSelections(groupId: groupId, date: day, periodStart: period)
          .first;

      expect(await absent(1), {ada});
      expect(await absent(5), isEmpty);
      expect(await late(5), {ada});
      expect(await late(1), isEmpty);

      await attendance.clearAbsence(studentId: ada, date: day, periodStart: 1);
      expect(await absent(1), isEmpty);
      expect(await late(5), {ada});
    });

    test('keep their homework apart', () async {
      await homework.saveLog(
        studentId: ada,
        date: day,
        periodStart: 1,
        hadHomework: true,
      );
      await homework.saveLog(
        studentId: ada,
        date: day,
        periodStart: 5,
        hadHomework: false,
      );

      Future<Map<int, bool>> logs(int period) => homework
          .watchGroupSelections(
            groupId: groupId,
            date: day,
            periodStart: period,
          )
          .first;
      expect(await logs(1), {ada: true});
      expect(await logs(5), {ada: false});
    });

    test(
      'recording homework takes back an absence but not a lateness',
      () async {
        await attendance.markLate(studentId: ada, date: day, periodStart: 1);
        await attendance.clearAbsenceOnly(
          studentId: ada,
          date: day,
          periodStart: 1,
        );
        expect(
          await attendance
              .watchLateSelections(groupId: groupId, date: day, periodStart: 1)
              .first,
          {ada},
        );

        await attendance.markAbsent(studentId: ada, date: day, periodStart: 1);
        await attendance.clearAbsenceOnly(
          studentId: ada,
          date: day,
          periodStart: 1,
        );
        expect(
          await attendance
              .watchGroupSelections(groupId: groupId, date: day, periodStart: 1)
              .first,
          isEmpty,
        );
      },
    );

    test('are summarized each with its own absences', () async {
      final sessions = SessionRepository(database);
      for (final period in [1, 5]) {
        await sessions.upsertSession(
          groupId: groupId,
          date: day,
          categoryId: 'sonstige-mitarbeit',
          categoryName: 'Sonstige Mitarbeit',
          periodStart: period,
          periodEnd: period,
        );
      }
      await attendance.markAbsent(studentId: ada, date: day, periodStart: 1);

      final summaries = await sessions
          .watchGroupSessionSummaries(groupId)
          .first;
      final absentByPeriod = {
        for (final summary in summaries)
          summary.session.periodStart: summary.absentCount,
      };
      expect(absentByPeriod, {1: 1, 5: 0});
    });
  });

  test('upgrading to 33 moves day logs onto the day\'s only lesson', () async {
    final directory = await Directory.systemTemp.createTemp('classi-v33');
    addTearDown(() => directory.delete(recursive: true));

    late int single;
    late int double_;
    final lessonDay = DateTime(2026, 9, 21);
    final busyDay = DateTime(2026, 9, 22);
    final freeDay = DateTime(2026, 9, 23);

    final path = await _buildV32Library(directory, (database) async {
      final groups = GroupRepository(database);
      final students = StudentRepository(database);
      final sessions = SessionRepository(database);
      final groupId = await groups.createGroup(
        name: '10a',
        gradeScale: _gradeScale,
      );
      single = await students.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'A',
      );
      double_ = await students.addStudent(
        groupId: groupId,
        firstName: 'Ben',
        lastName: 'B',
      );
      Future<void> lesson(DateTime date, int period) => sessions.upsertSession(
        groupId: groupId,
        date: date,
        categoryId: 'sonstige-mitarbeit',
        categoryName: 'Sonstige Mitarbeit',
        periodStart: period,
        periodEnd: period + 1,
      );
      await lesson(lessonDay, 3);
      await lesson(busyDay, 1);
      await lesson(busyDay, 5);

      final attendance = AttendanceRepository(database);
      await attendance.markAbsent(studentId: single, date: lessonDay);
      await attendance.markAbsent(studentId: double_, date: busyDay);
      await attendance.markAbsent(studentId: single, date: freeDay);
      await HomeworkRepository(
        database,
      ).saveLog(studentId: single, date: lessonDay, hadHomework: true);
    });

    final database = AppDatabase.test(NativeDatabase(File(path)));
    addTearDown(database.close);

    final attendance = await database
        .select(database.attendanceLogsTable)
        .get();
    int periodOf(int studentId, DateTime date) => attendance
        .singleWhere((log) => log.studentId == studentId && log.date == date)
        .periodStart;

    // One lesson that day: the entry belongs to it.
    expect(periodOf(single, lessonDay), 3);
    // Two lessons: which one is unknowable, so it stays a day entry.
    expect(periodOf(double_, busyDay), 0);
    // No lesson at all: a day entry as recorded.
    expect(periodOf(single, freeDay), 0);

    final homework = await database.select(database.homeworkLogsTable).get();
    expect(homework.single.periodStart, 3);
  });
}
