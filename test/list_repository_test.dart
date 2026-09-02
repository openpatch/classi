import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/lists/list_item_links.dart';
import 'package:classi/features/lists/list_repository.dart';
import 'package:classi/features/lists/list_sorting.dart';
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

  test('lists come back alphabetically unless asked otherwise', () async {
    await repository.createListWithOptions(name: 'Zoo trip');
    await repository.createListWithOptions(name: 'Ausflug');

    final lists = await repository.watchAllLists().first;

    expect(lists.map((list) => list.name), ['Ausflug', 'Zoo trip']);
  });

  test('newest first puts the list made last on top', () async {
    final first = await repository.createListWithOptions(name: 'Ausflug');
    await database
        .customStatement('UPDATE lists_table SET created_at = ? WHERE id = ?', [
          DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
          first,
        ]);
    await repository.createListWithOptions(name: 'Zoo trip');

    final lists = await repository
        .watchAllLists(sortField: ListSortField.newest)
        .first;

    expect(lists.map((list) => list.name), ['Zoo trip', 'Ausflug']);
  });

  test('ticking something off moves its list to the front', () async {
    final ausflug = await repository.createListWithOptions(name: 'Ausflug');
    final zoo = await repository.createListWithOptions(name: 'Zoo trip');
    await repository.addItem(listId: zoo, label: 'Tickets');
    await repository.addItem(listId: ausflug, label: 'Bus');
    // Both were set up in the same second, and a timestamp is only stored to
    // the second, so put yesterday's work behind them to start from.
    await database.customStatement('UPDATE lists_table SET touched_at = ?', [
      DateTime(2026, 6, 1).millisecondsSinceEpoch ~/ 1000,
    ]);

    Future<List<String>> recentlyUsed() async {
      final lists = await repository
          .watchAllLists(sortField: ListSortField.recentlyUsed)
          .first;
      return lists.map((list) => list.name).toList();
    }

    expect(await recentlyUsed(), ['Ausflug', 'Zoo trip']);

    final items = await repository.watchItems(zoo).first;
    await repository.toggleItem(itemId: items.single.id, checked: true);

    expect(await recentlyUsed(), ['Zoo trip', 'Ausflug']);
  });

  test('a list nobody has touched sorts by when it was made', () async {
    // Every list in a library from before the column existed looks like this.
    final old = await repository.createListWithOptions(name: 'Zoo trip');
    await database.customStatement(
      'UPDATE lists_table SET created_at = ?, touched_at = NULL WHERE id = ?',
      [DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000, old],
    );
    final recent = await repository.createListWithOptions(name: 'Ausflug');
    await database.customStatement(
      'UPDATE lists_table SET created_at = ?, touched_at = NULL WHERE id = ?',
      [DateTime(2026, 6, 1).millisecondsSinceEpoch ~/ 1000, recent],
    );

    final lists = await repository
        .watchAllLists(sortField: ListSortField.recentlyUsed)
        .first;

    expect(lists.map((list) => list.name), ['Ausflug', 'Zoo trip']);
  });

  test('entries keep the order they were typed in by default', () async {
    final listId = await repository.createListWithOptions(name: 'Ausflug');
    await repository.addItem(listId: listId, label: 'Tickets');
    await repository.addItem(listId: listId, label: 'Bus');

    final items = await repository.watchItems(listId).first;

    expect(items.map((item) => item.label), ['Tickets', 'Bus']);
  });

  test('entries can be read alphabetically, ignoring case', () async {
    final listId = await repository.createListWithOptions(name: 'Ausflug');
    await repository.addItem(listId: listId, label: 'tickets');
    await repository.addItem(listId: listId, label: 'Bus');

    final items = await repository
        .watchItems(listId, sortField: ListItemSortField.label)
        .first;

    expect(items.map((item) => item.label), ['Bus', 'tickets']);
  });

  test('open entries come before the ones ticked off', () async {
    final listId = await repository.createListWithOptions(name: 'Ausflug');
    await repository.addItem(listId: listId, label: 'Tickets');
    await repository.addItem(listId: listId, label: 'Bus');
    await repository.addItem(listId: listId, label: 'Snacks');
    final items = await repository.watchItems(listId).first;
    await repository.toggleItem(itemId: items.first.id, checked: true);

    final sorted = await repository
        .watchItems(listId, sortField: ListItemSortField.openFirst)
        .first;

    expect(sorted.map((item) => item.label), ['Bus', 'Snacks', 'Tickets']);
  });

  test('entries can follow the students they are about', () async {
    final groupId = await groupRepository.createGroup(
      name: '8A',
      gradeScale: defaultGradeScaleEntries,
    );
    final graceId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
    final adaId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    final listId = await repository.createList(
      groupId: groupId,
      name: 'Permission slips',
    );
    await repository.addItem(
      listId: listId,
      studentIds: [adaId],
      label: 'Ada handed it in',
    );
    await repository.addItem(listId: listId, label: 'Ask the office');
    await repository.addItem(
      listId: listId,
      studentIds: [graceId],
      label: 'Grace handed it in',
    );

    final byLastName = await repository
        .watchItems(listId, sortField: ListItemSortField.student)
        .first;
    expect(byLastName.map((item) => item.label), [
      'Grace handed it in',
      'Ada handed it in',
      // An entry about nobody has no name to sort by, so it follows.
      'Ask the office',
    ]);

    final byFirstName = await repository
        .watchItems(
          listId,
          sortField: ListItemSortField.student,
          studentSortField: StudentSortField.firstName,
        )
        .first;
    expect(byFirstName.map((item) => item.label), [
      'Ada handed it in',
      'Grace handed it in',
      'Ask the office',
    ]);
  });
}
