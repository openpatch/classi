import 'dart:math';

import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/lessons/group_builder/random_student_groups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 10, 9);
  final roster = [
    for (var id = 1; id <= 30; id++)
      Student(
        id: id,
        groupId: 1,
        firstName: 'Student $id',
        lastName: 'Test',
        createdAt: date,
        updatedAt: date,
      ),
  ];

  List<List<Student>> build({
    int count = 7,
    int size = 3,
    Set<int> absent = const {},
    int seed = 42,
  }) => buildRandomStudentGroups(
    students: roster.take(count).toList(),
    absentStudentIds: absent,
    studentsPerGroup: size,
    random: Random(seed),
  );

  test('includes every present student once and excludes absences', () {
    final students = roster.take(7).toList();
    final originalIds = students.map((student) => student.id).toList();
    final groups = buildRandomStudentGroups(
      students: students,
      absentStudentIds: {2, 5, 999},
      studentsPerGroup: 3,
      random: Random(42),
    );
    expect(
      groups.expand((group) => group).map((student) => student.id),
      unorderedEquals([1, 3, 4, 6, 7]),
    );
    expect(groups.map((group) => group.length), [3, 2]);
    expect(students.map((student) => student.id), originalIds);
  });

  test('balances a remainder rather than leaving a singleton group', () {
    expect(build().map((group) => group.length), [3, 2, 2]);
    expect(build(count: 10, size: 4).map((group) => group.length), [4, 3, 3]);
  });

  test('covers all class and group sizes with balanced, bounded groups', () {
    for (var count = 1; count <= roster.length; count++) {
      for (var size = 1; size <= count + 2; size++) {
        final groups = build(count: count, size: size);
        final sizes = groups.map((group) => group.length).toList();
        expect(groups, hasLength((count / size).ceil()));
        expect(sizes, everyElement(inInclusiveRange(1, size)));
        expect(sizes.reduce(max) - sizes.reduce(min), lessThanOrEqualTo(1));
        expect(
          groups.expand((group) => group).map((student) => student.id),
          unorderedEquals(roster.take(count).map((student) => student.id)),
        );
      }
    }
  });

  test('shuffles assignments with the supplied random source', () {
    List<List<int>> ids(int seed) => [
      for (final group in build(count: 12, seed: seed))
        [for (final student in group) student.id],
    ];
    expect(ids(1), ids(1));
    expect(ids(1), isNot(ids(2)));
  });

  test('handles an empty class and a class with everyone absent', () {
    expect(build(count: 0), isEmpty);
    expect(build(absent: {1, 2, 3, 4, 5, 6, 7}), isEmpty);
  });

  test('rejects a non-positive group size', () {
    expect(() => build(size: 0), throwsArgumentError);
    expect(() => build(size: -1), throwsArgumentError);
  });
}
