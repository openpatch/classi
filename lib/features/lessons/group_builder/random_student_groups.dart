import 'dart:math';

import '../../../core/database/app_database.dart';

List<List<Student>> buildRandomStudentGroups({
  required List<Student> students,
  required Set<int> absentStudentIds,
  required int studentsPerGroup,
  Random? random,
}) {
  if (studentsPerGroup < 1) {
    throw ArgumentError.value(studentsPerGroup, 'studentsPerGroup');
  }

  final present = [
    for (final student in students)
      if (!absentStudentIds.contains(student.id)) student,
  ]..shuffle(random);
  if (present.isEmpty) return const [];

  final groupCount = (present.length / studentsPerGroup).ceil();
  final groups = List.generate(groupCount, (_) => <Student>[]);
  // Spread the remainder across groups so their sizes differ by at most one.
  for (var index = 0; index < present.length; index++) {
    groups[index % groupCount].add(present[index]);
  }
  return groups;
}
