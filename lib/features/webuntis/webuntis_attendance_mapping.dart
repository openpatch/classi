import 'webuntis_models.dart';

/// One student's absence on one day, which is the granularity Classi records
/// attendance at.
typedef WebUntisAbsenceDay = ({
  int webUntisStudentId,
  DateTime date,
  bool excused,
});

/// Flattens WebUntis absences into per-day records.
///
/// WebUntis stores an absence as a half-open time range that can run over
/// several days, and a student can have more than one on the same day (two
/// separate lessons, say). Classi has a single absent/excused pair per student
/// per day, so overlapping absences have to collapse:
///
/// * A day counts as excused only when *every* absence covering it is
///   excused. A student excused for the morning but not the afternoon has an
///   unexcused day, and reporting it as excused would quietly hide it.
/// * A range that ends exactly at midnight does not reach into that last day.
///   Untis writes full-day absences as `…T00:00` on the following day.
///
/// [from] and [to] clamp the result to the range the teacher asked for, so an
/// absence that started before the window only contributes the days inside it.
/// [klasseIds], when given, keeps only absences recorded for those classes.
List<WebUntisAbsenceDay> expandAbsenceDays(
  Iterable<WebUntisAbsence> absences, {
  required DateTime from,
  required DateTime to,
  Set<int>? klasseIds,
}) {
  final windowStart = _atMidnight(from);
  final windowEnd = _atMidnight(to);
  if (windowEnd.isBefore(windowStart)) {
    return const [];
  }

  // (student, day) -> excused so far. `false` wins, per the rule above.
  final collected = <int, Map<DateTime, bool>>{};

  for (final absence in absences) {
    if (klasseIds != null && !klasseIds.contains(absence.klasseId)) {
      continue;
    }
    if (absence.studentId == 0) {
      continue;
    }

    var day = _atMidnight(absence.startDateTime);
    var lastDay = _atMidnight(absence.endDateTime);

    // An end stamp at midnight belongs to the previous day.
    final endsAtMidnight =
        absence.endDateTime.hour == 0 &&
        absence.endDateTime.minute == 0 &&
        absence.endDateTime.second == 0;
    if (endsAtMidnight && lastDay.isAfter(day)) {
      lastDay = lastDay.subtract(const Duration(days: 1));
      lastDay = DateTime(lastDay.year, lastDay.month, lastDay.day);
    }

    if (lastDay.isBefore(day)) {
      lastDay = day;
    }

    while (!day.isAfter(lastDay)) {
      if (!day.isBefore(windowStart) && !day.isAfter(windowEnd)) {
        final perStudent = collected.putIfAbsent(
          absence.studentId,
          () => <DateTime, bool>{},
        );
        final existing = perStudent[day];
        perStudent[day] = existing == null
            ? absence.excused
            : existing && absence.excused;
      }
      day = _nextDay(day);
    }
  }

  final result = <WebUntisAbsenceDay>[];
  for (final studentEntry in collected.entries) {
    for (final dayEntry in studentEntry.value.entries) {
      result.add((
        webUntisStudentId: studentEntry.key,
        date: dayEntry.key,
        excused: dayEntry.value,
      ));
    }
  }

  result.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) {
      return byDate;
    }
    return a.webUntisStudentId.compareTo(b.webUntisStudentId);
  });

  return result;
}

/// Rewrites [days] onto Classi student ids using [studentIdsByWebUntisId],
/// dropping absences for students the group does not contain.
///
/// The dropped ones are reported back as [unmatchedStudentIds] so the import
/// sheet can tell a teacher that their roster is out of date rather than
/// silently importing a partial picture.
({
  List<({int studentId, DateTime date, bool excused})> entries,
  Set<int> unmatchedStudentIds,
})
resolveAbsenceDays(
  List<WebUntisAbsenceDay> days,
  Map<int, int> studentIdsByWebUntisId,
) {
  final entries = <({int studentId, DateTime date, bool excused})>[];
  final unmatched = <int>{};

  for (final day in days) {
    final studentId = studentIdsByWebUntisId[day.webUntisStudentId];
    if (studentId == null) {
      unmatched.add(day.webUntisStudentId);
      continue;
    }
    entries.add((studentId: studentId, date: day.date, excused: day.excused));
  }

  return (entries: entries, unmatchedStudentIds: unmatched);
}

DateTime _atMidnight(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Adds a day without tripping over daylight saving: `add(Duration(days: 1))`
/// lands on 23:00 the same evening in the hour a clock goes back.
DateTime _nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);
