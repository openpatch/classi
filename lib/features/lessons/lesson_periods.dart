import '../../core/database/app_database.dart';

/// The school periods a lesson covers, e.g. 5 to 6. A lesson that is not
/// tied to periods, a whole-day entry, has none.
typedef LessonPeriods = ({int start, int end});

/// Bell times: which minutes of the day each period spans, per ISO weekday.
///
/// Classi has no bell schedule of its own; it takes the school's from
/// WebUntis. Without one, lessons are only known by their period numbers.
typedef BellTimes = Map<int, List<({int start, int end})>>;

/// Reads [value] (`"5"`, `"5-6"`) as periods, or `null`.
LessonPeriods? parseLessonPeriods(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  final start = int.tryParse(parts.first.trim());
  final end = int.tryParse(parts.last.trim());
  if (start == null || end == null || start < 1) return null;
  return (start: start, end: end < start ? start : end);
}

String encodeLessonPeriods(LessonPeriods periods) =>
    periods.start == periods.end
    ? '${periods.start}'
    : '${periods.start}-${periods.end}';

/// The lessons a group holds on [date]: its weekly slots for that weekday and
/// whatever lessons are already on the books that day, each once, in order.
List<LessonPeriods> lessonsOnDate({
  required DateTime date,
  required List<LessonSlot> slots,
  required List<Session> sessions,
}) {
  final byStart = <int, LessonPeriods>{};
  for (final slot in slots) {
    if (slot.weekday != date.weekday || slot.periodStart < 1) continue;
    byStart[slot.periodStart] = (start: slot.periodStart, end: slot.periodEnd);
  }
  for (final session in sessions) {
    final day = session.date;
    if (day.year != date.year ||
        day.month != date.month ||
        day.day != date.day ||
        session.periodStart < 1) {
      continue;
    }
    byStart[session.periodStart] = (
      start: session.periodStart,
      end: session.periodEnd < session.periodStart
          ? session.periodStart
          : session.periodEnd,
    );
  }
  return byStart.values.toList()..sort((a, b) => a.start.compareTo(b.start));
}

/// The minutes of the day [periods] span on [weekday], or `null` when the
/// bell times do not cover them.
({int start, int end})? lessonMinutes(
  LessonPeriods periods,
  int weekday,
  BellTimes bellTimes,
) {
  final units = bellTimes[weekday];
  if (units == null ||
      periods.start < 1 ||
      periods.end > units.length ||
      periods.start > periods.end) {
    return null;
  }
  return (
    start: units[periods.start - 1].start,
    end: units[periods.end - 1].end,
  );
}

/// Which of [lessons] on [date] lesson mode should open.
///
/// On the day itself with bell times known, it is the lesson running at
/// [now], else the next one to start, else the last one. Otherwise it is the
/// first lesson of the day. `null` when the group has no lesson that day.
LessonPeriods? pickCurrentLesson({
  required List<LessonPeriods> lessons,
  required DateTime date,
  required DateTime now,
  required BellTimes bellTimes,
}) {
  if (lessons.isEmpty) return null;
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (!isToday) return lessons.first;

  final minute = now.hour * 60 + now.minute;
  for (final lesson in lessons) {
    final span = lessonMinutes(lesson, date.weekday, bellTimes);
    if (span == null) return lessons.first;
    if (minute < span.end) return lesson;
  }
  return lessons.last;
}
