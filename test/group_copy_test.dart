import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/seating_plan/seating_plan_repository.dart';
import 'package:classi/features/seating_plan/student_relation_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late SeatingPlanRepository seatingPlanRepository;
  late StudentRelationRepository relationRepository;

  setUp(() {
    // Rules cascade off their students, which needs foreign keys on, the way
    // the app opens a library.
    database = AppDatabase.test(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    seatingPlanRepository = SeatingPlanRepository(database);
    relationRepository = StudentRelationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createGroup(String name) {
    return groupRepository.createGroup(
      name: name,
      gradeScale: defaultGradeScaleEntries,
    );
  }

  test('copying a group brings its students along', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
      callName: 'Addy',
      avatarJson: '{"top":"hat"}',
    );
    await studentRepository.addStudent(
      groupId: german,
      firstName: 'Grace',
      lastName: 'Hopper',
    );

    final result = await studentRepository.copyStudentsFromGroup(
      sourceGroupId: german,
      targetGroupId: history,
    );

    expect(result.added, 2);
    expect(result.updated, 0);
    expect(result.notInSource, isEmpty);
    final copied = await studentRepository.watchByGroup(history).first;
    expect(copied.map((s) => s.lastName), ['Hopper', 'Lovelace']);
    expect(copied.firstWhere((s) => s.lastName == 'Lovelace').callName, 'Addy');
  });

  test('copying again fills students in instead of doubling them', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    final adaId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    await studentRepository.addStudent(
      groupId: history,
      firstName: '  ada ',
      lastName: 'LOVELACE',
    );

    // The avatar was drawn in the German group weeks after the class was set
    // up in both subjects.
    await studentRepository.updateStudent(
      id: adaId,
      firstName: 'Ada',
      lastName: 'Lovelace',
      avatarJson: '{"top":"hat"}',
    );
    final result = await studentRepository.copyStudentsFromGroup(
      sourceGroupId: german,
      targetGroupId: history,
    );

    final students = await studentRepository.watchByGroup(history).first;
    expect(students, hasLength(1), reason: 'the same person, differently typed');
    expect(students.single.avatarJson, '{"top":"hat"}');
    expect(students.single.lastName, 'LOVELACE', reason: 'their own spelling');
    expect(result.added, 0);
    expect(result.updated, 1);
  });

  test('a copy never erases what the target already knows', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    await studentRepository.addStudent(
      groupId: history,
      firstName: 'Ada',
      lastName: 'Lovelace',
      callName: 'Addy',
      originNote: 'moved from 9b',
    );

    final result = await studentRepository.copyStudentsFromGroup(
      sourceGroupId: german,
      targetGroupId: history,
    );

    final student = (await studentRepository.watchByGroup(history).first).single;
    expect(student.callName, 'Addy');
    expect(student.originNote, 'moved from 9b');
    expect(result.updated, 0, reason: 'nothing to fill in');
  });

  test('a seating rule follows the students it names', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    final adaId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    final graceId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    await relationRepository.upsertRelation(
      studentAId: adaId,
      studentBId: graceId,
      isPositive: false,
      comment: 'talk all lesson',
    );
    await studentRepository.copyStudentsFromGroup(
      sourceGroupId: german,
      targetGroupId: history,
    );

    final copied = await relationRepository.copyRelationsBetweenGroups(
      sourceGroupId: german,
      targetGroupId: history,
    );

    expect(copied, 1);
    final students = await studentRepository.watchByGroup(history).first;
    final rules = await relationRepository
        .watchRelationsForGroup(history)
        .first;
    expect(rules, hasLength(1));
    expect(
      {rules.single.studentAId, rules.single.studentBId},
      students.map((s) => s.id).toSet(),
    );
    expect(rules.single.isPositive, isFalse);
    expect(rules.single.comment, 'talk all lesson');
  });

  test('copying rules again updates them instead of doubling', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    final adaId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    final graceId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    await relationRepository.upsertRelation(
      studentAId: adaId,
      studentBId: graceId,
      isPositive: false,
    );
    await studentRepository.copyStudentsFromGroup(
      sourceGroupId: german,
      targetGroupId: history,
    );
    await relationRepository.copyRelationsBetweenGroups(
      sourceGroupId: german,
      targetGroupId: history,
    );

    // The rule was softened in the other subject after the first copy.
    await relationRepository.upsertRelation(
      studentAId: adaId,
      studentBId: graceId,
      isPositive: true,
    );
    await relationRepository.copyRelationsBetweenGroups(
      sourceGroupId: german,
      targetGroupId: history,
    );

    final rules = await relationRepository
        .watchRelationsForGroup(history)
        .first;
    expect(rules, hasLength(1));
    expect(rules.single.isPositive, isTrue);
  });

  test('a rule naming somebody the other group lacks is skipped', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    final adaId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    final graceId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    await relationRepository.upsertRelation(
      studentAId: adaId,
      studentBId: graceId,
      isPositive: true,
    );
    await studentRepository.addStudent(
      groupId: history,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );

    final copied = await relationRepository.copyRelationsBetweenGroups(
      sourceGroupId: german,
      targetGroupId: history,
    );

    expect(copied, 0);
    expect(
      await relationRepository.watchRelationsForGroup(history).first,
      isEmpty,
    );
  });

  test('students the source no longer has are reported, not removed', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    await studentRepository.addStudent(
      groupId: history,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    // Left the class after the plan was copied over the first time.
    await studentRepository.addStudent(
      groupId: history,
      firstName: 'Alan',
      lastName: 'Turing',
    );

    final result = await studentRepository.copyStudentsFromGroup(
      sourceGroupId: german,
      targetGroupId: history,
    );

    expect(result.notInSource.map((s) => s.lastName), ['Turing']);
    expect(
      await studentRepository.watchByGroup(history).first,
      hasLength(2),
      reason: 'a copy on its own never takes a student out',
    );
  });

  test('copying a plan seats the same people in the other group', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    final adaId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    final graceId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    await studentRepository.copyStudentsFromGroup(
      sourceGroupId: german,
      targetGroupId: history,
    );

    final planId = await seatingPlanRepository.createPlan(
      groupId: german,
      name: 'Window row',
      columns: 4,
    );
    await seatingPlanRepository.upsertPosition(
      planId: planId,
      studentId: adaId,
      col: 3,
      row: 1,
    );
    await seatingPlanRepository.upsertPosition(
      planId: planId,
      studentId: graceId,
      col: 0,
      row: 2,
    );

    final result = await seatingPlanRepository.copyPlanToGroup(
      sourcePlanId: planId,
      targetGroupId: history,
    );

    expect(result.seated, 2);
    expect(result.missing, 0);
    final plans = await seatingPlanRepository.watchPlansForGroup(history).first;
    expect(plans.single.name, 'Window row');
    expect(plans.single.columns, 4);

    final students = await studentRepository.watchByGroup(history).first;
    final ada = students.firstWhere((s) => s.lastName == 'Lovelace');
    final grace = students.firstWhere((s) => s.lastName == 'Hopper');
    expect(
      await seatingPlanRepository.watchPositionsForPlan(result.planId).first,
      {ada.id: (col: 3, row: 1), grace.id: (col: 0, row: 2)},
    );
  });

  test('a seat with nobody to fill it is reported, not dropped', () async {
    final german = await createGroup('9a German');
    final history = await createGroup('9a History');
    final adaId = await studentRepository.addStudent(
      groupId: german,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    await studentRepository.addStudent(
      groupId: history,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    final planId = await seatingPlanRepository.createPlan(
      groupId: german,
      name: 'Window row',
    );
    await seatingPlanRepository.upsertPosition(
      planId: planId,
      studentId: adaId,
      col: 0,
      row: 0,
    );

    final result = await seatingPlanRepository.copyPlanToGroup(
      sourcePlanId: planId,
      targetGroupId: history,
      name: 'Copied plan',
    );

    expect(result.seated, 0);
    expect(result.missing, 1);
    expect(
      await seatingPlanRepository.watchPositionsForPlan(result.planId).first,
      isEmpty,
    );
    final plans = await seatingPlanRepository.watchPlansForGroup(history).first;
    expect(plans.single.name, 'Copied plan');
  });

  test('a student is matched by name across groups', () {
    expect(
      studentMatchKey(firstName: ' ada ', lastName: 'Von  Neumann'),
      studentMatchKey(firstName: 'Ada', lastName: 'von Neumann'),
    );
    expect(
      studentMatchKey(firstName: 'Ada', lastName: 'Lovelace'),
      isNot(studentMatchKey(firstName: 'Grace', lastName: 'Lovelace')),
    );
  });
}
