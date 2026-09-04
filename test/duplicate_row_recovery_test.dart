import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/attendance/attendance_repository.dart';
import 'package:classi/features/grades/grade_repository.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/homework/homework_repository.dart';
import 'package:classi/features/material_tracking/material_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sync merge inserts rows from a peer by primary key, so two devices that
/// logged the same student on the same day leave two rows behind a natural key
/// the schema never made unique. Saving over one used to hit
/// `getSingleOrNull`, which throws on the second row and left the teacher
/// unable to record anything for that day again.
void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late HomeworkRepository homeworkRepository;
  late MaterialRepository materialRepository;
  late AttendanceRepository attendanceRepository;
  late GradeRepository gradeRepository;

  late int studentId;

  final date = DateTime(2026, 5, 6);

  setUp(() async {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    homeworkRepository = HomeworkRepository(database);
    materialRepository = MaterialRepository(database);
    attendanceRepository = AttendanceRepository(database);
    gradeRepository = GradeRepository(database);

    final groupId = await groupRepository.createGroup(
      name: '10A',
      gradeScale: defaultGradeScaleEntries,
    );
    studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saving homework over a merged duplicate keeps one row', () async {
    for (var i = 0; i < 2; i++) {
      await database.into(database.homeworkLogsTable).insert(
            HomeworkLogsTableCompanion.insert(
              studentId: studentId,
              date: date,
              hadHomework: const Value(false),
            ),
          );
    }

    await homeworkRepository.saveLog(
      studentId: studentId,
      date: date,
      hadHomework: true,
    );

    final logs = await database.select(database.homeworkLogsTable).get();
    expect(logs, hasLength(1));
    expect(logs.single.hadHomework, isTrue);
  });

  test('saving material over a merged duplicate keeps one row', () async {
    for (var i = 0; i < 2; i++) {
      await database.into(database.materialLogsTable).insert(
            MaterialLogsTableCompanion.insert(
              studentId: studentId,
              date: date,
              hadMaterial: const Value(false),
            ),
          );
    }

    await materialRepository.saveLog(
      studentId: studentId,
      date: date,
      hadMaterial: true,
    );

    final logs = await database.select(database.materialLogsTable).get();
    expect(logs, hasLength(1));
    expect(logs.single.hadMaterial, isTrue);
  });

  test('marking absent over a merged duplicate keeps one row', () async {
    for (var i = 0; i < 2; i++) {
      await database.into(database.attendanceLogsTable).insert(
            AttendanceLogsTableCompanion.insert(
              studentId: studentId,
              date: date,
              isAbsent: const Value(false),
            ),
          );
    }

    await attendanceRepository.markAbsent(studentId: studentId, date: date);

    final logs = await database.select(database.attendanceLogsTable).get();
    expect(logs, hasLength(1));
    expect(logs.single.isAbsent, isTrue);
  });

  test('saving a grade over a merged duplicate keeps one entry', () async {
    for (var i = 0; i < 2; i++) {
      await database.into(database.gradeEntriesTable).insert(
            GradeEntriesTableCompanion.insert(
              studentId: studentId,
              date: date,
              sessionLabel: 'Mitarbeit',
              value: '2',
            ),
          );
    }

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: date,
      sessionLabel: 'Mitarbeit',
      value: '1',
    );

    final entries = await database.select(database.gradeEntriesTable).get();
    expect(entries, hasLength(1));
    expect(entries.single.value, '1');
  });
}
