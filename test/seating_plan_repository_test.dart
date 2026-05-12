import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/seating_plan/seating_plan_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late SeatingPlanRepository repository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    repository = SeatingPlanRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'moveStudent swaps with the existing student in the target cell',
    () async {
      final groupId = await groupRepository.createGroup(
        name: '8A',
        gradeScale: defaultGradeScaleEntries,
      );
      final firstStudentId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'Lovelace',
      );
      final secondStudentId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Grace',
        lastName: 'Hopper',
      );
      final planId = await repository.createPlan(
        groupId: groupId,
        name: 'Main',
        columns: 2,
      );

      await repository.upsertPosition(
        planId: planId,
        studentId: firstStudentId,
        col: 0,
        row: 0,
      );
      await repository.upsertPosition(
        planId: planId,
        studentId: secondStudentId,
        col: 1,
        row: 0,
      );

      await repository.moveStudent(
        planId: planId,
        studentId: firstStudentId,
        col: 1,
        row: 0,
      );

      final positions = await repository.watchPositionsForPlan(planId).first;
      expect(positions[firstStudentId], (col: 1, row: 0));
      expect(positions[secondStudentId], (col: 0, row: 0));
    },
  );
}
