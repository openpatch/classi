import '../../core/database/app_database.dart';
import '../lessons/lesson_support.dart';
import 'lesson_schedule.dart';

/// A group whose weekly slots feed the timetable.
typedef TimetableGroup = ({
  int id,
  String name,
  String colorHex,
  List<LessonSlotDraft> slots,

  /// slot categoryId -> display name, so a lesson planned from here carries a
  /// readable category name without the screen re-parsing the group.
  Map<String, String> categoryNames,
});

/// One lesson the weekly timetable shows: a slot from a group's weekly
/// schedule resolved to a concrete date in the shown week, plus whether a
/// session already covers it.
class TimetableLesson {
  const TimetableLesson({
    required this.groupId,
    required this.groupName,
    required this.groupColorHex,
    required this.date,
    required this.weekday,
    required this.periodStart,
    required this.periodEnd,
    required this.categoryId,
    required this.categoryName,
    required this.label,
    required this.planned,
  });

  final int groupId;
  final String groupName;
  final String groupColorHex;

  /// The concrete date in the shown week this slot falls on.
  final DateTime date;

  /// ISO weekday, [DateTime.monday] (1) through [DateTime.sunday] (7).
  final int weekday;
  final int periodStart;
  final int periodEnd;
  final String categoryId;
  final String categoryName;

  /// The label of the session covering this slot, empty when the slot is
  /// unplanned or the session carries no label.
  final String label;

  /// Whether a session already exists for this slot in the shown week.
  final bool planned;
}

/// The timetable for one week: every lesson the groups' weekly schedules call
/// for, with the grid dimensions a screen needs to lay them out.
class WeeklyTimetable {
  const WeeklyTimetable({
    required this.weekStart,
    required this.lessons,
    required this.weekdays,
    required this.periodCount,
  });

  /// Monday of the shown week, at midnight local time.
  final DateTime weekStart;

  /// Every lesson in the week, ordered by weekday, then period, then group.
  final List<TimetableLesson> lessons;

  /// The weekday columns to show: always Monday–Friday, extended to Saturday
  /// or Sunday only when a lesson falls there. ISO weekday values.
  final List<int> weekdays;

  /// How many period rows the grid shows: the highest period any lesson runs
  /// to, never fewer than [minVisiblePeriods].
  final int periodCount;

  bool get isEmpty => lessons.isEmpty;

  List<TimetableLesson> get unplanned =>
      [for (final lesson in lessons) if (!lesson.planned) lesson];

  List<TimetableLesson> lessonsOn(int weekday) =>
      [for (final lesson in lessons) if (lesson.weekday == weekday) lesson];
}

/// The fewest period rows the grid shows even for a short timetable, so it
/// still reads as a school timetable.
const int minVisiblePeriods = 6;

/// Builds the timetable for the week [weekStart] falls in from each group's
/// weekly [slots][TimetableGroup.slots] and the [sessions] already on the
/// books for that week (any group).
WeeklyTimetable buildWeeklyTimetable({
  required DateTime weekStart,
  required List<TimetableGroup> groups,
  required List<Session> sessions,
}) {
  final monday = mondayOf(weekStart);

  // Index sessions by group and date so covering a slot is a cheap lookup.
  final sessionsByGroupDate = <int, Map<DateTime, List<Session>>>{};
  for (final session in sessions) {
    final date = normalizeLessonDate(session.date);
    sessionsByGroupDate
        .putIfAbsent(session.groupId, () => <DateTime, List<Session>>{})
        .putIfAbsent(date, () => <Session>[])
        .add(session);
  }

  final lessons = <TimetableLesson>[];
  for (final group in groups) {
    for (final slot in group.slots) {
      final date = addDays(monday, slot.weekday - 1);
      final periodEnd = slot.periodEnd < slot.periodStart
          ? slot.periodStart
          : slot.periodEnd;
      final daySessions =
          sessionsByGroupDate[group.id]?[date] ?? const <Session>[];
      final covering = _coveringSession(daySessions, slot);
      lessons.add(
        TimetableLesson(
          groupId: group.id,
          groupName: group.name,
          groupColorHex: group.colorHex,
          date: date,
          weekday: slot.weekday,
          periodStart: slot.periodStart,
          periodEnd: periodEnd,
          categoryId: slot.categoryId,
          categoryName: group.categoryNames[slot.categoryId] ?? slot.categoryId,
          label: covering?.label ?? '',
          planned: covering != null,
        ),
      );
    }
  }

  lessons.sort((a, b) {
    final byWeekday = a.weekday.compareTo(b.weekday);
    if (byWeekday != 0) return byWeekday;
    final byPeriod = a.periodStart.compareTo(b.periodStart);
    if (byPeriod != 0) return byPeriod;
    return a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase());
  });

  var maxWeekday = DateTime.friday;
  var maxPeriod = minVisiblePeriods;
  for (final lesson in lessons) {
    if (lesson.weekday > maxWeekday) maxWeekday = lesson.weekday;
    if (lesson.periodEnd > maxPeriod) maxPeriod = lesson.periodEnd;
  }

  return WeeklyTimetable(
    weekStart: monday,
    lessons: lessons,
    weekdays: [for (var d = DateTime.monday; d <= maxWeekday; d++) d],
    periodCount: maxPeriod,
  );
}

/// The session in [daySessions] that covers [slot]: one whose period block
/// overlaps the slot's, or — failing that — one that carries no period at all,
/// in which case sharing the date is taken as covering the slot. Returns null
/// when nothing covers it.
Session? _coveringSession(List<Session> daySessions, LessonSlotDraft slot) {
  final slotEnd =
      slot.periodEnd < slot.periodStart ? slot.periodStart : slot.periodEnd;
  Session? periodless;
  for (final session in daySessions) {
    if (session.periodStart <= 0) {
      periodless ??= session;
      continue;
    }
    final sessionEnd = session.periodEnd < session.periodStart
        ? session.periodStart
        : session.periodEnd;
    if (session.periodStart <= slotEnd && slot.periodStart <= sessionEnd) {
      return session;
    }
  }
  return periodless;
}

/// Monday of the week [date] falls in, at midnight local time.
DateTime mondayOf(DateTime date) {
  final normalized = normalizeLessonDate(date);
  return addDays(normalized, -(normalized.weekday - DateTime.monday));
}
