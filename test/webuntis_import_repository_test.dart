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

  group('course link', () {
    test('linking a course replaces a class link, and back', () async {
      final groupId = await createGroup(klasseId: 11);

      await groupRepository.setWebUntisLessonIds(
        groupId: groupId,
        lessonIds: '4,5',
      );
      var group = (await groupRepository.watchGroup(groupId).first)!;
      expect(group.webuntisLessonIds, '4,5');
      expect(group.webuntisKlasseId, isNull);

      await groupRepository.setWebUntisKlasseId(groupId: groupId, klasseId: 12);
      group = (await groupRepository.watchGroup(groupId).first)!;
      expect(group.webuntisKlasseId, 12);
      expect(group.webuntisLessonIds, isNull);
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

  group('applyAttendanceForDate', () {
    final day = DateTime(2026, 9, 25);
    late int groupId;
    late int ada;
    late int ben;
    late int cem;

    setUp(() async {
      groupId = await createGroup();
      ada = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'A',
      );
      ben = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ben',
        lastName: 'B',
      );
      cem = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Cem',
        lastName: 'C',
      );
    });

    Future<Set<int>> absent() => attendanceRepository
        .watchGroupSelections(groupId: groupId, date: day)
        .first;
    Future<Set<int>> excused() => attendanceRepository
        .watchExcusedSelections(groupId: groupId, date: day)
        .first;

    test('marks absent and excused as WebUntis says', () async {
      await attendanceRepository.applyAttendanceForDate(
        date: DateTime(2026, 9, 25, 10, 30),
        studentIds: {ada, ben},
        absences: {ada: true, ben: false},
      );

      expect(await absent(), {ada, ben});
      expect(await excused(), {ada});
    });

    test('clears an absence WebUntis does not have', () async {
      await attendanceRepository.markAbsent(studentId: ada, date: day);

      await attendanceRepository.applyAttendanceForDate(
        date: day,
        studentIds: {ada, ben},
        absences: const {},
      );

      expect(await absent(), isEmpty);
    });

    test('leaves students WebUntis does not know alone', () async {
      await attendanceRepository.markAbsent(studentId: cem, date: day);

      await attendanceRepository.applyAttendanceForDate(
        date: day,
        studentIds: {ada, ben},
        absences: {ada: false},
      );

      expect(await absent(), {ada, cem});
    });

    test('corrects the excuse and folds duplicate rows', () async {
      for (var i = 0; i < 2; i++) {
        await database
            .into(database.attendanceLogsTable)
            .insert(
              AttendanceLogsTableCompanion.insert(studentId: ada, date: day),
            );
      }

      await attendanceRepository.applyAttendanceForDate(
        date: day,
        studentIds: {ada},
        absences: {ada: true},
      );

      final rows = await (database.select(
        database.attendanceLogsTable,
      )..where((t) => t.studentId.equals(ada))).get();
      expect(rows, hasLength(1));
      expect(rows.single.isExcused, isTrue);
    });
  });

  group('late', () {
    final day = DateTime(2026, 9, 25);
    late int groupId;
    late int ada;

    setUp(() async {
      groupId = await createGroup();
      ada = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'A',
      );
    });

    Future<Set<int>> late() => attendanceRepository
        .watchLateSelections(groupId: groupId, date: day)
        .first;
    Future<Set<int>> absent() => attendanceRepository
        .watchGroupSelections(groupId: groupId, date: day)
        .first;

    test('late is present, and replaces an absence', () async {
      await attendanceRepository.markAbsent(studentId: ada, date: day);
      await attendanceRepository.markLate(studentId: ada, date: day);

      expect(await late(), {ada});
      expect(await absent(), isEmpty);
    });

    test('absent replaces late', () async {
      await attendanceRepository.markLate(studentId: ada, date: day);
      await attendanceRepository.markAbsent(studentId: ada, date: day);

      expect(await late(), isEmpty);
      expect(await absent(), {ada});
    });

    test('present clears late', () async {
      await attendanceRepository.markLate(studentId: ada, date: day);
      await attendanceRepository.clearAbsence(studentId: ada, date: day);

      expect(await late(), isEmpty);
    });

    test('taking over WebUntis attendance brings late along', () async {
      await attendanceRepository.markAbsent(studentId: ada, date: day);

      await attendanceRepository.applyAttendanceForDate(
        date: day,
        studentIds: {ada},
        absences: const {},
        late: {ada},
      );
      expect(await late(), {ada});
      expect(await absent(), isEmpty);

      await attendanceRepository.applyAttendanceForDate(
        date: day,
        studentIds: {ada},
        absences: const {},
      );
      expect(await late(), isEmpty);
    });
  });
}
