import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/lists/list_item_links.dart';
import 'package:classi/features/lists/list_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/features/students/student_sorting.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late ListRepository repository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    repository = ListRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('global lists appear in overview but not in group streams', () async {
    final groupId = await groupRepository.createGroup(
      name: '8A',
      gradeScale: defaultGradeScaleEntries,
    );

    final globalListId = await repository.createListWithOptions(
      name: 'General',
    );
    final groupListId = await repository.createList(
      groupId: groupId,
      name: 'HW',
    );

    final allLists = await repository.watchAllLists().first;
    expect(
      allLists.map((list) => list.id),
      containsAll([globalListId, groupListId]),
    );
    expect(
      allLists.firstWhere((list) => list.id == globalListId).groupId,
      isNull,
    );

    final groupLists = await repository.watchLists(groupId).first;
    expect(groupLists.map((list) => list.id).toList(), [groupListId]);
  });

  test('global list items can link multiple students across groups', () async {
    final firstGroupId = await groupRepository.createGroup(
      name: '8A',
      gradeScale: defaultGradeScaleEntries,
    );
    final secondGroupId = await groupRepository.createGroup(
      name: '8B',
      gradeScale: defaultGradeScaleEntries,
    );
    final firstStudentId = await studentRepository.addStudent(
      groupId: firstGroupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    final secondStudentId = await studentRepository.addStudent(
      groupId: secondGroupId,
      firstName: 'Alan',
      lastName: 'Turing',
    );
    final listId = await repository.createListWithOptions(name: 'Forms');

    await repository.addItem(
      listId: listId,
      label: 'Bring signed consent form',
      studentIds: [firstStudentId, secondStudentId],
    );

    final item = (await repository.watchItems(listId).first).single;
    expect(item.studentId, firstStudentId);
    expect(listItemStudentIds(item), [firstStudentId, secondStudentId]);
  });

  test('group lists reject linked students from other groups', () async {
    final firstGroupId = await groupRepository.createGroup(
      name: '8A',
      gradeScale: defaultGradeScaleEntries,
    );
    final secondGroupId = await groupRepository.createGroup(
      name: '8B',
      gradeScale: defaultGradeScaleEntries,
    );
    final localStudentId = await studentRepository.addStudent(
      groupId: firstGroupId,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    final foreignStudentId = await studentRepository.addStudent(
      groupId: secondGroupId,
      firstName: 'Katherine',
      lastName: 'Johnson',
    );
    final listId = await repository.createList(
      groupId: firstGroupId,
      name: 'Quiz',
    );

    await expectLater(
      () => repository.addItem(
        listId: listId,
        label: 'Prepare quiz',
        studentIds: [localStudentId, foreignStudentId],
      ),
      throwsArgumentError,
    );
  });

  test('group lists can create one item per student automatically', () async {
    final groupId = await groupRepository.createGroup(
      name: '8C',
      gradeScale: defaultGradeScaleEntries,
    );
    final firstStudentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Max',
      lastName: 'Mustermann',
    );
    final secondStudentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Erika',
      lastName: 'Musterfrau',
    );

    final listId = await repository.createListWithOptions(
      groupId: groupId,
      name: 'Presentations',
      populateFromGroupStudents: true,
      sortField: StudentSortField.firstName,
    );

    final items = await repository.watchItems(listId).first;
    expect(items, hasLength(2));
    expect(items.map((item) => item.label).toList(), [
      'Erika Musterfrau',
      'Max Mustermann',
    ]);
    expect(items.map(listItemStudentIds).toList(), [
      [secondStudentId],
      [firstStudentId],
    ]);
  });
}
