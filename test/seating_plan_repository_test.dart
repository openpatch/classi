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

  test(
    'a student who joins later gets a free cell, not an occupied one',
    () async {
      final groupId = await groupRepository.createGroup(
        name: '8A',
        gradeScale: defaultGradeScaleEntries,
      );
      for (final firstName in ['Ada', 'Grace', 'Alan']) {
        await studentRepository.addStudent(
          groupId: groupId,
          firstName: firstName,
          lastName: 'Doe',
        );
      }
      final planId = await repository.createPlan(
        groupId: groupId,
        name: 'Main',
        columns: 3,
      );
      await repository.initializePositionsForPlan(
        planId: planId,
        students: await studentRepository.watchByGroup(groupId).first,
        columns: 3,
      );

      await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Katherine',
        lastName: 'Doe',
      );
      await repository.initializePositionsForPlan(
        planId: planId,
        students: await studentRepository.watchByGroup(groupId).first,
        columns: 3,
      );

      final positions = await repository.watchPositionsForPlan(planId).first;
      expect(positions, hasLength(4));
      final cells = positions.values.map((p) => (p.col, p.row)).toList();
      expect(cells.toSet(), hasLength(4), reason: 'two students share a cell');
    },
  );

  test('students already stacked on one cell are moved apart', () async {
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

    // The state an older build could leave behind.
    await repository.upsertPosition(
      planId: planId,
      studentId: firstStudentId,
      col: 0,
      row: 0,
    );
    await repository.upsertPosition(
      planId: planId,
      studentId: secondStudentId,
      col: 0,
      row: 0,
    );

    await repository.initializePositionsForPlan(
      planId: planId,
      students: await studentRepository.watchByGroup(groupId).first,
      columns: 2,
    );

    final positions = await repository.watchPositionsForPlan(planId).first;
    expect(positions[firstStudentId], isNot(positions[secondStudentId]));
  });

  test('moving onto a cell two students share does not fail', () async {
    final groupId = await groupRepository.createGroup(
      name: '8A',
      gradeScale: defaultGradeScaleEntries,
    );
    final ids = [
      for (final firstName in ['Ada', 'Grace', 'Alan'])
        await studentRepository.addStudent(
          groupId: groupId,
          firstName: firstName,
          lastName: 'Doe',
        ),
    ];
    final planId = await repository.createPlan(
      groupId: groupId,
      name: 'Main',
      columns: 3,
    );
    for (final id in ids.take(2)) {
      await repository.upsertPosition(
        planId: planId,
        studentId: id,
        col: 0,
        row: 0,
      );
    }
    await repository.upsertPosition(
      planId: planId,
      studentId: ids[2],
      col: 2,
      row: 0,
    );

    await repository.moveStudent(
      planId: planId,
      studentId: ids[2],
      col: 0,
      row: 0,
    );

    final positions = await repository.watchPositionsForPlan(planId).first;
    expect(positions[ids[2]], (col: 0, row: 0));
    // Both former occupants swapped out to the cell that was vacated.
    expect(positions[ids[0]], (col: 2, row: 0));
    expect(positions[ids[1]], (col: 2, row: 0));
  });

  test('applyPositions writes a whole rearrangement at once', () async {
    final groupId = await groupRepository.createGroup(
      name: '8A',
      gradeScale: defaultGradeScaleEntries,
    );
    final adaId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    final graceId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    final planId = await repository.createPlan(groupId: groupId, name: 'Main');
    await repository.upsertPosition(
      planId: planId,
      studentId: adaId,
      col: 0,
      row: 0,
    );
    await repository.upsertPosition(
      planId: planId,
      studentId: graceId,
      col: 1,
      row: 0,
    );

    // The two trade seats, which is what a suggestion hands back.
    await repository.applyPositions(
      planId: planId,
      positions: {
        adaId: (col: 1, row: 0),
        graceId: (col: 0, row: 0),
      },
    );

    expect(await repository.watchPositionsForPlan(planId).first, {
      adaId: (col: 1, row: 0),
      graceId: (col: 0, row: 0),
    });
  });
}
