import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/attendance/attendance_repository.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late AttendanceRepository attendanceRepository;

  const gradeScale = [
    GradeScaleEntry(label: '1', numericValue: 1),
    GradeScaleEntry(label: '2', numericValue: 2),
  ];

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    attendanceRepository = AttendanceRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createGroup({int? klasseId}) => groupRepository.createGroup(
    name: '10a',
    gradeScale: gradeScale,
    webuntisKlasseId: klasseId,
  );

  group('group linking', () {
    test('remembers which WebUntis class a group came from', () async {
      final groupId = await createGroup(klasseId: 11);

      final byKlasse = await groupRepository.groupsByWebUntisKlasseId();
      expect(byKlasse.keys, [11]);
      expect(byKlasse[11]!.id, groupId);
    });

    test('links and unlinks an existing group', () async {
      final groupId = await createGroup();
      expect(await groupRepository.groupsByWebUntisKlasseId(), isEmpty);

      await groupRepository.setWebUntisKlasseId(groupId: groupId, klasseId: 11);
      expect(
        (await groupRepository.groupsByWebUntisKlasseId())[11]!.id,
        groupId,
      );

      await groupRepository.setWebUntisKlasseId(
        groupId: groupId,
        klasseId: null,
      );
      expect(await groupRepository.groupsByWebUntisKlasseId(), isEmpty);
    });
  });

  group('importWebUntisStudents', () {
    test('adds students that are not in the group yet', () async {
      final groupId = await createGroup(klasseId: 11);

      final result = await studentRepository.importWebUntisStudents(
        groupId: groupId,
        students: const [
          (firstName: 'Ada', lastName: 'Lovelace', webuntisStudentId: 100),
          (firstName: 'Alan', lastName: 'Turing', webuntisStudentId: 200),
        ],
      );

      expect(result, (added: 2, linked: 0, skipped: 0));
      expect(await studentRepository.webUntisStudentIds(groupId), hasLength(2));
    });

    test('is idempotent: a second import changes nothing', () async {
      final groupId = await createGroup(klasseId: 11);
      const roster = [
        (firstName: 'Ada', lastName: 'Lovelace', webuntisStudentId: 100),
      ];

      await studentRepository.importWebUntisStudents(
        groupId: groupId,
        students: roster,
      );
      final second = await studentRepository.importWebUntisStudents(
        groupId: groupId,
        students: roster,
      );

      expect(second, (added: 0, linked: 0, skipped: 1));
      expect(await studentRepository.watchByGroup(groupId).first, hasLength(1));
    });

    test('links a student typed in by hand instead of duplicating', () async {
      final groupId = await createGroup(klasseId: 11);
      final existingId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'Lovelace',
        originNote: 'typed in before connecting WebUntis',
      );

      final result = await studentRepository.importWebUntisStudents(
        groupId: groupId,
        students: const [
          (firstName: ' ada ', lastName: 'LOVELACE', webuntisStudentId: 100),
        ],
      );

      expect(result, (added: 0, linked: 1, skipped: 0));
      final students = await studentRepository.watchByGroup(groupId).first;
      expect(students, hasLength(1));
      // The existing record survives, notes and all: only the id was added.
      expect(students.single.id, existingId);
      expect(students.single.originNote, isNotNull);
      expect(await studentRepository.webUntisStudentIds(groupId), {
        100: existingId,
      });
    });

    test('adds a namesake rather than stealing an already linked id', () async {
      final groupId = await createGroup(klasseId: 11);
      await studentRepository.importWebUntisStudents(
        groupId: groupId,
        students: const [
          (firstName: 'Ada', lastName: 'Lovelace', webuntisStudentId: 100),
        ],
      );

      final result = await studentRepository.importWebUntisStudents(
        groupId: groupId,
        students: const [
          (firstName: 'Ada', lastName: 'Lovelace', webuntisStudentId: 300),
        ],
      );

      expect(result, (added: 1, linked: 0, skipped: 0));
      expect(await studentRepository.watchByGroup(groupId).first, hasLength(2));
    });
  });

  group('importAbsences', () {
    late int groupId;
    late int studentId;

    setUp(() async {
      groupId = await createGroup(klasseId: 11);
      studentId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'Lovelace',
      );
    });

    Future<AttendanceLog?> logOn(DateTime date) async {
      final logs = await attendanceRepository.watchStudentLogs(studentId).first;
      return logs.where((log) => log.date == date).firstOrNull;
    }

    test('writes days that had no record', () async {
      final result = await attendanceRepository.importAbsences(
        absences: [
          (studentId: studentId, date: DateTime(2026, 9, 3), excused: true),
        ],
      );

      expect(result.created, 1);
      final log = await logOn(DateTime(2026, 9, 3));
      expect(log!.isAbsent, isTrue);
      expect(log.isExcused, isTrue);
    });

    test('corrects the excuse status of a day already marked absent', () async {
      await attendanceRepository.markAbsent(
        studentId: studentId,
        date: DateTime(2026, 9, 3),
      );

      final result = await attendanceRepository.importAbsences(
        absences: [
          (studentId: studentId, date: DateTime(2026, 9, 3), excused: true),
        ],
      );

      expect(
        result,
        isA<AttendanceImportResult>()
            .having((r) => r.updated, 'updated', 1)
            .having((r) => r.created, 'created', 0),
      );
      expect((await logOn(DateTime(2026, 9, 3)))!.isExcused, isTrue);
    });

    test('reports a day that already says the same as unchanged', () async {
      await attendanceRepository.importAbsences(
        absences: [
          (studentId: studentId, date: DateTime(2026, 9, 3), excused: false),
        ],
      );

      final result = await attendanceRepository.importAbsences(
        absences: [
          (studentId: studentId, date: DateTime(2026, 9, 3), excused: false),
        ],
      );

      expect(result.unchanged, 1);
      expect(result.changedAnything, isFalse);
    });

    test('leaves a day the teacher marked present alone by default', () async {
      await attendanceRepository.savePresenceForDate(
        groupId: groupId,
        date: DateTime(2026, 9, 3),
      );

      final result = await attendanceRepository.importAbsences(
        absences: [
          (studentId: studentId, date: DateTime(2026, 9, 3), excused: false),
        ],
      );

      expect(result.skipped, 1);
      expect((await logOn(DateTime(2026, 9, 3)))!.isAbsent, isFalse);
    });

    test('overwrites a present day when asked to', () async {
      await attendanceRepository.savePresenceForDate(
        groupId: groupId,
        date: DateTime(2026, 9, 3),
      );

      final result = await attendanceRepository.importAbsences(
        absences: [
          (studentId: studentId, date: DateTime(2026, 9, 3), excused: true),
        ],
        overwriteExisting: true,
      );

      expect(result.updated, 1);
      final log = await logOn(DateTime(2026, 9, 3));
      expect(log!.isAbsent, isTrue);
      expect(log.isExcused, isTrue);
    });

    test('never deletes an absence WebUntis does not know about', () async {
      await attendanceRepository.markAbsent(
        studentId: studentId,
        date: DateTime(2026, 9, 4),
      );

      await attendanceRepository.importAbsences(
        absences: [
          (studentId: studentId, date: DateTime(2026, 9, 3), excused: false),
        ],
        overwriteExisting: true,
      );

      expect((await logOn(DateTime(2026, 9, 4)))!.isAbsent, isTrue);
    });

    test('normalizes the time of day away', () async {
      await attendanceRepository.importAbsences(
        absences: [
          (
            studentId: studentId,
            date: DateTime(2026, 9, 3, 14, 30),
            excused: false,
          ),
        ],
      );

      expect(await logOn(DateTime(2026, 9, 3)), isNotNull);
    });

    test('does nothing for an empty import', () async {
      final result = await attendanceRepository.importAbsences(absences: []);

      expect(result.total, 0);
      expect(
        await attendanceRepository.watchStudentLogs(studentId).first,
        isEmpty,
      );
    });
  });
}
