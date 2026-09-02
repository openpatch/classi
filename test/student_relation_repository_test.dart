import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/seating_plan/student_relation_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late StudentRelationRepository repository;

  setUp(() {
    // The app turns foreign keys on when it opens a library, so the test
    // database has to as well for the cascading deletes to fire.
    database = AppDatabase.test(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    repository = StudentRelationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<(int groupId, int adaId, int graceId)> seedGroup() async {
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
    return (groupId, adaId, graceId);
  }

  test('a rule is stored with the lower student id first', () async {
    final (groupId, adaId, graceId) = await seedGroup();

    await repository.upsertRelation(
      studentAId: graceId,
      studentBId: adaId,
      isPositive: false,
      comment: '  chatty  ',
    );

    final relations = await repository.watchRelationsForGroup(groupId).first;
    expect(relations, hasLength(1));
    expect(relations.single.studentAId, adaId);
    expect(relations.single.studentBId, graceId);
    expect(relations.single.isPositive, isFalse);
    expect(relations.single.comment, 'chatty');
  });

  test('writing the same pair again updates instead of duplicating', () async {
    final (groupId, adaId, graceId) = await seedGroup();

    await repository.upsertRelation(
      studentAId: adaId,
      studentBId: graceId,
      isPositive: false,
      comment: 'chatty',
    );
    // Swapped order, so this only stays a single rule if the pair is
    // normalized before writing.
    await repository.upsertRelation(
      studentAId: graceId,
      studentBId: adaId,
      isPositive: true,
      comment: '',
    );

    final relations = await repository.watchRelationsForGroup(groupId).first;
    expect(relations, hasLength(1));
    expect(relations.single.isPositive, isTrue);
    expect(relations.single.comment, isNull);
  });

  test('a rule with a student on both sides is rejected', () async {
    final (_, adaId, _) = await seedGroup();

    expect(
      () => repository.upsertRelation(
        studentAId: adaId,
        studentBId: adaId,
        isPositive: true,
      ),
      throwsArgumentError,
    );
  });

  test('deleting a student removes the rules that mention them', () async {
    final (groupId, adaId, graceId) = await seedGroup();

    await repository.upsertRelation(
      studentAId: adaId,
      studentBId: graceId,
      isPositive: true,
    );
    await studentRepository.deleteStudent(graceId);

    expect(await repository.watchRelationsForGroup(groupId).first, isEmpty);
  });

  test('rules of another group are not returned', () async {
    final (groupId, adaId, graceId) = await seedGroup();
    final otherGroupId = await groupRepository.createGroup(
      name: '9B',
      gradeScale: defaultGradeScaleEntries,
    );
    final firstOtherId = await studentRepository.addStudent(
      groupId: otherGroupId,
      firstName: 'Alan',
      lastName: 'Turing',
    );
    final secondOtherId = await studentRepository.addStudent(
      groupId: otherGroupId,
      firstName: 'Katherine',
      lastName: 'Johnson',
    );

    await repository.upsertRelation(
      studentAId: adaId,
      studentBId: graceId,
      isPositive: true,
    );
    await repository.upsertRelation(
      studentAId: firstOtherId,
      studentBId: secondOtherId,
      isPositive: false,
    );

    final relations = await repository.watchRelationsForGroup(groupId).first;
    expect(relations, hasLength(1));
    expect(relations.single.studentAId, adaId);
  });
}
