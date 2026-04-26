import 'dart:async';

import 'package:clari/core/database/app_database.dart';
import 'package:clari/features/attendance/attendance_repository.dart';
import 'package:clari/features/grades/grade_repository.dart';
import 'package:clari/features/groups/group_repository.dart';
import 'package:clari/features/homework/homework_repository.dart';
import 'package:clari/features/lists/list_repository.dart';
import 'package:clari/features/material_tracking/material_repository.dart';
import 'package:clari/features/students/student_repository.dart';
import 'package:clari/features/students/student_sorting.dart';
import 'package:clari/shared/utils/grade_categories.dart';
import 'package:clari/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late GradeRepository gradeRepository;
  late MaterialRepository materialRepository;
  late HomeworkRepository homeworkRepository;
  late AttendanceRepository attendanceRepository;
  late ListRepository listRepository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    gradeRepository = GradeRepository(database);
    materialRepository = MaterialRepository(database);
    homeworkRepository = HomeworkRepository(database);
    attendanceRepository = AttendanceRepository(database);
    listRepository = ListRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('student avatar JSON can be stored and cleared', () async {
    final groupId = await groupRepository.createGroup(
      name: '11B',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Linus',
      lastName: 'Torvalds',
    );

    await studentRepository.updateAvatar(
      id: studentId,
      avatarJson: '{"HairColor":"Brown"}',
    );

    final savedStudent = await studentRepository.watchStudent(studentId).first;
    expect(savedStudent?.avatarJson, '{"HairColor":"Brown"}');

    await studentRepository.updateAvatar(id: studentId, avatarJson: null);

    final clearedStudent = await studentRepository
        .watchStudent(studentId)
        .first;
    expect(clearedStudent?.avatarJson, isNull);
  });

  test('students can be added in a batch', () async {
    final groupId = await groupRepository.createGroup(
      name: '6B',
      gradeScale: defaultGradeScaleEntries,
    );

    await studentRepository.addStudents(
      groupId: groupId,
      students: const [
        (
          firstName: 'Ada',
          lastName: 'Lovelace',
          originNote: null,
          avatarJson: null,
        ),
        (
          firstName: 'Alan',
          lastName: 'Turing',
          originNote: 'Imported',
          avatarJson: null,
        ),
      ],
    );

    final students = await studentRepository.watchByGroup(groupId).first;
    expect(students, hasLength(2));
    expect(
      students
          .map((student) => '${student.firstName} ${student.lastName}')
          .toList(),
      containsAll(['Ada Lovelace', 'Alan Turing']),
    );
    expect(
      students.firstWhere((student) => student.lastName == 'Turing').originNote,
      'Imported',
    );
  });

  test('grades and materials can be deleted', () async {
    final groupId = await groupRepository.createGroup(
      name: '9C',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Grace',
      lastName: 'Hopper',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 24),
      sessionLabel: 'Quiz',
      value: '2',
    );
    final grade =
        (await gradeRepository.watchStudentGrades(studentId).first).single;
    await gradeRepository.deleteEntry(grade.id);
    expect(await gradeRepository.watchStudentGrades(studentId).first, isEmpty);

    await materialRepository.saveLog(
      studentId: studentId,
      date: DateTime(2026, 4, 24),
      hadMaterial: true,
    );
    final log =
        (await materialRepository.watchStudentLogs(studentId).first).single;
    await materialRepository.deleteLog(log.id);
    expect(await materialRepository.watchStudentLogs(studentId).first, isEmpty);
  });

  test('grades and materials can be edited', () async {
    final groupId = await groupRepository.createGroup(
      name: '7A',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Katherine',
      lastName: 'Johnson',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 24),
      sessionLabel: 'Quiz',
      value: '3',
    );
    final savedGrade =
        (await gradeRepository.watchStudentGrades(studentId).first).single;
    await gradeRepository.updateEntry(
      id: savedGrade.id,
      studentId: studentId,
      date: DateTime(2026, 4, 25),
      sessionLabel: 'Exam',
      value: '1',
      categoryId: savedGrade.categoryId,
      categoryName: savedGrade.categoryName,
    );

    final updatedGrade =
        (await gradeRepository.watchStudentGrades(studentId).first).single;
    expect(updatedGrade.date, DateTime(2026, 4, 25));
    expect(updatedGrade.sessionLabel, 'Exam');
    expect(updatedGrade.value, '1');

    await materialRepository.saveLog(
      studentId: studentId,
      date: DateTime(2026, 4, 24),
      hadMaterial: true,
    );
    final savedLog =
        (await materialRepository.watchStudentLogs(studentId).first).single;
    await materialRepository.updateLog(
      id: savedLog.id,
      studentId: studentId,
      date: DateTime(2026, 4, 25),
      hadMaterial: false,
    );

    final updatedLog =
        (await materialRepository.watchStudentLogs(studentId).first).single;
    expect(updatedLog.date, DateTime(2026, 4, 25));
    expect(updatedLog.hadMaterial, isFalse);
  });

  test('homework logs can be saved, edited, and deleted', () async {
    final groupId = await groupRepository.createGroup(
      name: '7C',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Annie',
      lastName: 'Easley',
    );

    await homeworkRepository.saveLog(
      studentId: studentId,
      date: DateTime(2026, 4, 24),
      hadHomework: true,
    );
    final savedLog =
        (await homeworkRepository.watchStudentLogs(studentId).first).single;
    expect(savedLog.hadHomework, isTrue);

    await homeworkRepository.updateLog(
      id: savedLog.id,
      studentId: studentId,
      date: DateTime(2026, 4, 25),
      hadHomework: false,
    );
    final updatedLog =
        (await homeworkRepository.watchStudentLogs(studentId).first).single;
    expect(updatedLog.date, DateTime(2026, 4, 25));
    expect(updatedLog.hadHomework, isFalse);

    await homeworkRepository.deleteLog(updatedLog.id);
    expect(await homeworkRepository.watchStudentLogs(studentId).first, isEmpty);
  });

  test('material group selections stream reacts to saved logs', () async {
    final groupId = await groupRepository.createGroup(
      name: '6A',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Marie',
      lastName: 'Curie',
    );

    final expectation = expectLater(
      materialRepository.watchGroupSelections(
        groupId: groupId,
        date: DateTime(2026, 4, 24),
      ),
      emitsInOrder([
        isEmpty,
        {studentId: true},
      ]),
    );

    await Future<void>.delayed(Duration.zero);
    await materialRepository.saveLog(
      studentId: studentId,
      date: DateTime(2026, 4, 24),
      hadMaterial: true,
    );

    await expectation;
  });

  test(
    'absence tracking clears material and homework for the same date',
    () async {
      final groupId = await groupRepository.createGroup(
        name: '9A',
        gradeScale: defaultGradeScaleEntries,
      );
      final studentId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'Lovelace',
      );

      await materialRepository.saveLog(
        studentId: studentId,
        date: DateTime(2026, 4, 24),
        hadMaterial: true,
      );
      await homeworkRepository.saveLog(
        studentId: studentId,
        date: DateTime(2026, 4, 24),
        hadHomework: false,
      );

      await attendanceRepository.markAbsent(
        studentId: studentId,
        date: DateTime(2026, 4, 24),
      );

      expect(
        await (database.select(
          database.attendanceLogsTable,
        )..where((table) => table.studentId.equals(studentId))).get(),
        hasLength(1),
      );
      expect(
        await materialRepository.watchStudentLogs(studentId).first,
        isEmpty,
      );
      expect(
        await homeworkRepository.watchStudentLogs(studentId).first,
        isEmpty,
      );

      await attendanceRepository.clearAbsence(
        studentId: studentId,
        date: DateTime(2026, 4, 24),
      );

      expect(
        await (database.select(
          database.attendanceLogsTable,
        )..where((table) => table.studentId.equals(studentId))).get(),
        isEmpty,
      );
    },
  );

  test('grades can be saved without a label', () async {
    final groupId = await groupRepository.createGroup(
      name: '7B',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Dorothy',
      lastName: 'Vaughan',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 25),
      sessionLabel: '',
      value: '2',
    );

    final savedGrade =
        (await gradeRepository.watchStudentGrades(studentId).first).single;
    expect(savedGrade.sessionLabel, isEmpty);
    expect(
      await gradeRepository.getSessionSelections(
        groupId: groupId,
        date: DateTime(2026, 4, 25),
        sessionLabel: '',
        categoryId: savedGrade.categoryId,
      ),
      {studentId: '2'},
    );
  });

  test('session selections can be cleared for a student', () async {
    final groupId = await groupRepository.createGroup(
      name: '7D',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Sally',
      lastName: 'Ride',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 25),
      sessionLabel: 'Quiz',
      value: '2',
    );

    await gradeRepository.clearSessionSelection(
      studentId: studentId,
      date: DateTime(2026, 4, 25),
      sessionLabel: 'Quiz',
      categoryId: defaultGradeCategoryId,
    );

    expect(
      await gradeRepository.getSessionSelections(
        groupId: groupId,
        date: DateTime(2026, 4, 25),
        sessionLabel: 'Quiz',
        categoryId: defaultGradeCategoryId,
      ),
      isEmpty,
    );
    expect(await gradeRepository.watchStudentGrades(studentId).first, isEmpty);
  });

  test('lists can be archived and restored', () async {
    final groupId = await groupRepository.createGroup(
      name: '8C',
      gradeScale: defaultGradeScaleEntries,
    );

    final listId = await listRepository.createList(
      groupId: groupId,
      name: 'HW',
    );
    await listRepository.archiveList(listId);

    expect(await listRepository.watchLists(groupId).first, isEmpty);
    expect(
      await listRepository.watchArchivedLists(groupId).first,
      hasLength(1),
    );

    await listRepository.unarchiveList(listId);

    expect(await listRepository.watchLists(groupId).first, hasLength(1));
    expect(await listRepository.watchArchivedLists(groupId).first, isEmpty);
  });

  test('list progress tracks checked items', () async {
    final groupId = await groupRepository.createGroup(
      name: '8D',
      gradeScale: defaultGradeScaleEntries,
    );

    final listId = await listRepository.createList(
      groupId: groupId,
      name: 'Homework',
    );
    await listRepository.addItem(listId: listId, label: 'A');
    await listRepository.addItem(listId: listId, label: 'B');

    final initialProgress = await listRepository
        .watchListProgress(groupId: groupId)
        .first;
    expect(initialProgress[listId]?.checked, 0);
    expect(initialProgress[listId]?.total, 2);

    final firstItem = (await listRepository.watchItems(listId).first).first;
    await listRepository.toggleItem(itemId: firstItem.id, checked: true);

    final updatedProgress = await listRepository
        .watchListProgress(groupId: groupId)
        .first;
    expect(updatedProgress[listId]?.checked, 1);
    expect(updatedProgress[listId]?.total, 2);
  });

  test(
    'students can be edited and lists are visible in overview stream',
    () async {
      final firstGroupId = await groupRepository.createGroup(
        name: '8A',
        gradeScale: defaultGradeScaleEntries,
      );
      final secondGroupId = await groupRepository.createGroup(
        name: '8B',
        gradeScale: defaultGradeScaleEntries,
      );

      final studentId = await studentRepository.addStudent(
        groupId: firstGroupId,
        firstName: 'Alan',
        lastName: 'Kay',
        originNote: 'Original',
      );

      await studentRepository.updateStudent(
        id: studentId,
        firstName: 'Adele',
        lastName: 'Goldberg',
        originNote: 'Updated',
      );

      final updatedStudent = await studentRepository
          .watchStudent(studentId)
          .first;
      expect(updatedStudent?.firstName, 'Adele');
      expect(updatedStudent?.lastName, 'Goldberg');
      expect(updatedStudent?.originNote, 'Updated');

      await listRepository.createList(groupId: firstGroupId, name: 'Homework');
      await listRepository.createList(
        groupId: secondGroupId,
        name: 'Presentations',
      );

      final allLists = await listRepository.watchAllLists().first;
      expect(
        allLists.map((list) => list.name),
        containsAll(['Homework', 'Presentations']),
      );
    },
  );

  test('students can be sorted by last name or first name', () async {
    final groupId = await groupRepository.createGroup(
      name: '6C',
      gradeScale: defaultGradeScaleEntries,
    );

    await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Zoe',
      lastName: 'Alpha',
    );
    await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Ada',
      lastName: 'Zulu',
    );

    final byLastName = await studentRepository.watchByGroup(groupId).first;
    expect(byLastName.map((student) => student.lastName).toList(), [
      'Alpha',
      'Zulu',
    ]);

    final byFirstName = await studentRepository
        .watchByGroup(groupId, sortField: StudentSortField.firstName)
        .first;
    expect(byFirstName.map((student) => student.firstName).toList(), [
      'Ada',
      'Zoe',
    ]);
  });

  test('weighted group averages use grade category weights', () async {
    final groupId = await groupRepository.createGroup(
      name: '5B',
      gradeScale: defaultGradeScaleEntries,
      gradeCategories: const [
        GradeCategory(
          id: 'participation',
          name: 'Participation',
          weight: 1,
          colorHex: '#FF1E88E5',
        ),
        GradeCategory(
          id: 'exam',
          name: 'Exam',
          weight: 3,
          colorHex: '#FF8E24AA',
        ),
      ],
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Mary',
      lastName: 'Jackson',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 20),
      sessionLabel: 'Week 1',
      value: '4',
      categoryId: 'participation',
      categoryName: 'Participation',
    );
    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 21),
      sessionLabel: 'Exam 1',
      value: '2',
      categoryId: 'exam',
      categoryName: 'Exam',
    );

    final averages = await gradeRepository.getGroupAverages(groupId);
    expect(averages[studentId], 2.5);
  });

  test('extended grade systems use configured numeric values', () async {
    final groupId = await groupRepository.createGroup(
      name: '11A',
      gradeScale: defaultExtendedGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Lise',
      lastName: 'Meitner',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 20),
      sessionLabel: 'Talk',
      value: '1+',
    );
    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 21),
      sessionLabel: 'Quiz',
      value: '1-',
    );

    final averages = await gradeRepository.getGroupAverages(groupId);
    expect(averages[studentId], 1.0);
  });

  test('weighted group average stream updates after weight changes', () async {
    final groupId = await groupRepository.createGroup(
      name: '5C',
      gradeScale: defaultGradeScaleEntries,
      gradeCategories: const [
        GradeCategory(
          id: 'participation',
          name: 'Participation',
          weight: 1,
          colorHex: '#FF1E88E5',
        ),
        GradeCategory(
          id: 'exam',
          name: 'Exam',
          weight: 3,
          colorHex: '#FF8E24AA',
        ),
      ],
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Mae',
      lastName: 'Jemison',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 20),
      sessionLabel: 'Week 1',
      value: '4',
      categoryId: 'participation',
      categoryName: 'Participation',
    );
    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 21),
      sessionLabel: 'Exam 1',
      value: '2',
      categoryId: 'exam',
      categoryName: 'Exam',
    );

    final iterator = StreamIterator(
      gradeRepository.watchGroupAverages(groupId),
    );
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current[studentId], 2.5);

    await groupRepository.updateGroup(
      id: groupId,
      name: '5C',
      gradeScale: defaultGradeScaleEntries,
      gradeCategories: const [
        GradeCategory(
          id: 'participation',
          name: 'Participation',
          weight: 1,
          colorHex: '#FF1E88E5',
        ),
        GradeCategory(
          id: 'exam',
          name: 'Exam',
          weight: 1,
          colorHex: '#FF8E24AA',
        ),
      ],
    );

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current[studentId], 3);
    await iterator.cancel();
  });

  test('group average streams react to student grade edits', () async {
    final groupId = await groupRepository.createGroup(
      name: '5D',
      gradeScale: defaultGradeScaleEntries,
      gradeCategories: const [
        GradeCategory(
          id: 'oral',
          name: 'Oral',
          weight: 1,
          colorHex: '#FF43A047',
        ),
      ],
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Valentina',
      lastName: 'Tereshkova',
    );

    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 4, 20),
      sessionLabel: 'Participation',
      value: '3',
      categoryId: 'oral',
      categoryName: 'Oral',
    );

    final savedGrade =
        (await gradeRepository.watchStudentGrades(studentId).first).single;
    final averageIterator = StreamIterator(
      gradeRepository.watchGroupAverages(groupId),
    );
    final categoryIterator = StreamIterator(
      gradeRepository.watchGroupCategoryAverages(groupId),
    );

    expect(await averageIterator.moveNext(), isTrue);
    expect(averageIterator.current[studentId], 3);
    expect(await categoryIterator.moveNext(), isTrue);
    expect(categoryIterator.current[studentId]?['oral'], 3);

    await gradeRepository.updateEntry(
      id: savedGrade.id,
      studentId: studentId,
      date: savedGrade.date,
      sessionLabel: savedGrade.sessionLabel,
      value: '1',
      categoryId: savedGrade.categoryId,
      categoryName: savedGrade.categoryName,
    );

    expect(await averageIterator.moveNext(), isTrue);
    expect(averageIterator.current[studentId], 1);
    expect(await categoryIterator.moveNext(), isTrue);
    expect(categoryIterator.current[studentId]?['oral'], 1);

    await averageIterator.cancel();
    await categoryIterator.cancel();
  });

  test(
    'group category averages are returned per student and category',
    () async {
      final groupId = await groupRepository.createGroup(
        name: '4A',
        gradeScale: defaultGradeScaleEntries,
        gradeCategories: const [
          GradeCategory(
            id: 'oral',
            name: 'Oral',
            weight: 1,
            colorHex: '#FF43A047',
          ),
          GradeCategory(
            id: 'written',
            name: 'Written',
            weight: 2,
            colorHex: '#FFE53935',
          ),
        ],
      );
      final studentId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Sally',
        lastName: 'Ride',
      );

      await gradeRepository.saveEntry(
        studentId: studentId,
        date: DateTime(2026, 4, 10),
        sessionLabel: 'Oral 1',
        value: '2',
        categoryId: 'oral',
        categoryName: 'Oral',
      );
      await gradeRepository.saveEntry(
        studentId: studentId,
        date: DateTime(2026, 4, 12),
        sessionLabel: 'Oral 2',
        value: '4',
        categoryId: 'oral',
        categoryName: 'Oral',
      );
      await gradeRepository.saveEntry(
        studentId: studentId,
        date: DateTime(2026, 4, 14),
        sessionLabel: 'Written 1',
        value: '1',
        categoryId: 'written',
        categoryName: 'Written',
      );

      final categoryAverages = await gradeRepository.getGroupCategoryAverages(
        groupId,
      );
      expect(categoryAverages[studentId]?['oral'], 3);
      expect(categoryAverages[studentId]?['written'], 1);
    },
  );
}
