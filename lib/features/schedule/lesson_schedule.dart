import '../../core/database/app_database.dart';
import '../lessons/lesson_support.dart';

/// A slot in a group's weekly timetable, detached from the database so it can
/// also describe a pattern that was inferred but not saved yet.
class LessonSlotDraft {
  const LessonSlotDraft({
    required this.weekday,
    required this.periodStart,
    required this.periodEnd,
    required this.categoryId,
  });

  LessonSlotDraft.fromSlot(LessonSlot slot)
    : weekday = slot.weekday,
      periodStart = slot.periodStart,
      periodEnd = slot.periodEnd,
      categoryId = slot.categoryId;

  /// ISO weekday, [DateTime.monday] (1) through [DateTime.sunday] (7).
  final int weekday;

  /// First school period, 1-based.
  final int periodStart;

  /// Last school period, inclusive.
  final int periodEnd;

  final String categoryId;

  LessonSlotDraft copyWith({
    int? weekday,
    int? periodStart,
    int? periodEnd,
    String? categoryId,
  }) {
    return LessonSlotDraft(
      weekday: weekday ?? this.weekday,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LessonSlotDraft &&
      other.weekday == weekday &&
      other.periodStart == periodStart &&
      other.periodEnd == periodEnd &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(weekday, periodStart, periodEnd, categoryId);
}

/// A concrete lesson the schedule proposes for a date, ready to be saved as a
/// session once the teacher confirms it.
typedef PlannedLesson = ({
  DateTime date,
  int periodStart,
  int periodEnd,
  String categoryId,
});

/// Orders slots the way a timetable reads: by weekday, then by period.
int compareSlots(LessonSlotDraft a, LessonSlotDraft b) {
  final byWeekday = a.weekday.compareTo(b.weekday);
  if (byWeekday != 0) return byWeekday;
  return a.periodStart.compareTo(b.periodStart);
}

List<LessonSlotDraft> sortedSlots(Iterable<LessonSlotDraft> slots) =>
    slots.toList()..sort(compareSlots);

/// Renders a period range the way a timetable does: `3` for a single period,
/// `1+2` for two adjacent ones, `1–4` for a longer block. Returns an empty
/// string when the lesson carries no period.
String formatPeriodRange(int periodStart, int periodEnd) {
  if (periodStart <= 0) return '';
  final end = periodEnd < periodStart ? periodStart : periodEnd;
  if (end == periodStart) return '$periodStart';
  if (end == periodStart + 1) return '$periodStart+$end';
  return '$periodStart–$end';
}

/// [days] calendar days after [date], keeping the date at midnight local time.
///
/// Adding a [Duration] would drift by an hour across a daylight-saving change
/// and could land a Monday slot on the Sunday before it, so the arithmetic is
/// done on the calendar fields, which [DateTime] normalizes for us.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// The first date on or after [from] that falls on [weekday].
DateTime nextDateForWeekday(int weekday, {required DateTime from}) {
  final start = normalizeLessonDate(from);
  return addDays(start, (weekday - start.weekday + 7) % 7);
}

/// The next lesson each slot in [slots] proposes on or after [from], ordered
/// by date and then by period, so the first entry is the next lesson due.
///
/// Slots are a weekly pattern, so every slot contributes exactly one date per
/// week; [weeks] decides how far ahead to look.
List<PlannedLesson> upcomingLessons(
  Iterable<LessonSlotDraft> slots, {
  required DateTime from,
  int weeks = 1,
}) {
  final start = normalizeLessonDate(from);
  final lessons = <PlannedLesson>[];
  for (final slot in slots) {
    final first = nextDateForWeekday(slot.weekday, from: start);
    for (var week = 0; week < weeks; week++) {
      lessons.add((
        date: addDays(first, 7 * week),
        periodStart: slot.periodStart,
        periodEnd: slot.periodEnd,
        categoryId: slot.categoryId,
      ));
    }
  }
  lessons.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.periodStart.compareTo(b.periodStart);
  });
  return lessons;
}

/// The date planning suggestions should start from: the day after the group's
/// last planned lesson, so planning a lesson repeatedly walks forward through
/// the schedule instead of proposing whatever slot happens to sit nearest
/// today and filling gaps behind it.
///
/// Never earlier than [today]: a group left alone since last term would
/// otherwise be offered dates that have long since passed.
DateTime suggestionAnchor({
  required Iterable<DateTime> plannedDates,
  required DateTime today,
}) {
  var anchor = normalizeLessonDate(today);
  for (final date in plannedDates) {
    final afterLesson = addDays(normalizeLessonDate(date), 1);
    if (afterLesson.isAfter(anchor)) anchor = afterLesson;
  }
  return anchor;
}

/// Every lesson the schedule calls for between [start] and [end], inclusive,
/// ordered by date and period. Used to fill a whole term in one go.
List<PlannedLesson> lessonsInRange(
  Iterable<LessonSlotDraft> slots, {
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = normalizeLessonDate(start);
  final rangeEnd = normalizeLessonDate(end);
  if (rangeEnd.isBefore(rangeStart)) return const [];

  final lessons = <PlannedLesson>[];
  for (final slot in slots) {
    var date = nextDateForWeekday(slot.weekday, from: rangeStart);
    while (!date.isAfter(rangeEnd)) {
      lessons.add((
        date: date,
        periodStart: slot.periodStart,
        periodEnd: slot.periodEnd,
        categoryId: slot.categoryId,
      ));
      date = addDays(date, 7);
    }
  }
  lessons.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.periodStart.compareTo(b.periodStart);
  });
  return lessons;
}

/// How many past lessons a pattern is inferred from. Far enough back to see a
/// fortnightly rhythm, close enough that last year's timetable is ignored.
const int inferenceSessionLimit = 24;

/// The share of the busiest weekday's lesson count a weekday needs to reach to
/// count as part of the pattern. Keeps one-off make-up lessons out.
const double _inferenceWeekdayThreshold = 0.4;

/// Guesses a group's weekly timetable from the lessons it already holds.
///
/// Looks at the most recent [inferenceSessionLimit] lessons, keeps the
/// weekdays that carry a meaningful share of them, and gives each weekday the
/// periods and category it most often ran with. Returns an empty list when
/// there is too little history to see a pattern in.
List<LessonSlotDraft> inferSlotsFromSessions(Iterable<Session> sessions) {
  final recent = sessions.toList()..sort((a, b) => b.date.compareTo(a.date));
  final considered = recent.take(inferenceSessionLimit).toList();
  if (considered.length < 2) return const [];

  final byWeekday = <int, List<Session>>{};
  for (final session in considered) {
    byWeekday.putIfAbsent(session.date.weekday, () => []).add(session);
  }

  final busiest = byWeekday.values
      .map((sessions) => sessions.length)
      .reduce((a, b) => a > b ? a : b);
  final minimum = busiest * _inferenceWeekdayThreshold;

  final slots = <LessonSlotDraft>[];
  for (final entry in byWeekday.entries) {
    if (entry.value.length < 2 || entry.value.length < minimum) continue;
    // A weekday can hold several distinct periods (e.g. a double on Monday
    // morning and a single after lunch), so each period that recurs on that
    // weekday becomes its own slot.
    final periodCounts = <(int, int), int>{};
    for (final session in entry.value) {
      final key = (session.periodStart, session.periodEnd);
      periodCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    final periods = periodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final kept = [
      for (final period in periods)
        if (period.value >= 2 || periods.length == 1) period.key,
    ];

    for (final period in kept.isEmpty ? [periods.first.key] : kept) {
      slots.add(
        LessonSlotDraft(
          weekday: entry.key,
          periodStart: period.$1,
          periodEnd: period.$2,
          categoryId: _mostCommonCategory(entry.value, period),
        ),
      );
    }
  }

  return sortedSlots(slots);
}

String _mostCommonCategory(List<Session> sessions, (int, int) period) {
  final counts = <String, int>{};
  for (final session in sessions) {
    if ((session.periodStart, session.periodEnd) != period) continue;
    counts.update(session.categoryId, (count) => count + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) return sessions.first.categoryId;
  return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      .first
      .key;
}
