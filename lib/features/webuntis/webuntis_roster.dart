import 'webuntis_models.dart';

/// Picks the lessons whose class registers best describe a class.
///
/// WebUntis has no call that returns the students of a class, only a register
/// per lesson, so a roster has to be reconstructed from lessons. Two rules
/// keep that honest:
///
/// * A lesson held for this class **and another one** — a combined course, a
///   shared elective — has a register covering both, so it would pull in
///   students who are not in the group. Lessons held for this class alone are
///   used whenever there are any.
/// * The most recent lessons win, because a class roster changes over a
///   school year and the newest register is the one that is right today.
///
/// [limit] caps how many registers are fetched afterwards; several are read
/// rather than one because a single lesson can be a split group that only
/// half the class attends.
List<WebUntisPeriod> selectRosterPeriods(
  List<WebUntisPeriod> periods, {
  required int klasseId,
  int limit = 8,
}) {
  final forClass = periods
      .where((period) => period.klasseIds.contains(klasseId))
      .toList(growable: false);
  if (forClass.isEmpty) {
    return const [];
  }

  final exclusive = forClass
      .where((period) => period.klasseIds.length == 1)
      .toList(growable: false);
  final chosen = exclusive.isNotEmpty ? exclusive : forClass;

  final sorted = [...chosen]
    ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
  return sorted.take(limit).toList(growable: false);
}

/// Unions the students enrolled in the inspected lessons, sorted by name.
///
/// Falls back to every referenced student when no lesson reported a student
/// list: some servers omit `studentIds` but still name the students the
/// lessons refer to, and showing those beats showing nothing.
List<WebUntisPerson> studentsFromRegisters(WebUntisPeriodDataResult result) {
  final byId = {
    for (final person in result.referencedStudents) person.id: person,
  };

  final enrolled = <int>{};
  for (final data in result.dataByTtId.values) {
    enrolled.addAll(data.studentIds);
  }

  final ids = enrolled.isEmpty ? byId.keys.toSet() : enrolled;

  return [for (final id in ids) ?byId[id]]..sort((a, b) {
    final byLast = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
    if (byLast != 0) {
      return byLast;
    }
    return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
  });
}
