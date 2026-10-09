import '../lessons/lesson_support.dart';
import 'webuntis_link.dart';
import 'webuntis_models.dart';

typedef WebUntisScheduledLesson = ({
  DateTime date,
  int periodStart,
  int periodEnd,
});

/// A timetable together with the bell times needed to read school periods.
class WebUntisTimetable {
  const WebUntisTimetable({required this.periods, required this.timeGrid});

  final List<WebUntisPeriod> periods;
  final WebUntisTimeGrid timeGrid;

  /// Resolves a group's dated lessons, joining adjacent periods into blocks.
  /// Cancelled lessons are excluded. Lessons outside the bell times are
  /// counted separately so the import can explain why they were left out.
  ({List<WebUntisScheduledLesson> lessons, int unmapped}) lessonsFor({
    required WebUntisGroupLink link,
    required DateTime start,
    required DateTime end,
  }) {
    final from = normalizeLessonDate(start);
    final to = normalizeLessonDate(end);
    final byDate = <DateTime, Set<int>>{};
    var unmapped = 0;

    for (final period in periods) {
      if (period.cancelled || !link.includes(period)) continue;
      final date = normalizeLessonDate(period.startDateTime);
      if (date.isBefore(from) || date.isAfter(to)) continue;
      final units = timeGrid.unitsByWeekday[date.weekday] ?? const [];
      final first = timeGrid.periodAt(period.startDateTime);
      final last = timeGrid.periodAt(
        period.endDateTime.subtract(const Duration(milliseconds: 1)),
      );
      if (first == null ||
          last == null ||
          last < first ||
          !period.endDateTime.isAfter(period.startDateTime) ||
          normalizeLessonDate(period.endDateTime) != date ||
          last > units.length) {
        unmapped++;
        continue;
      }
      byDate.putIfAbsent(date, () => {}).addAll([
        for (var number = first; number <= last; number++) number,
      ]);
    }

    final lessons = <WebUntisScheduledLesson>[];
    final dates = byDate.keys.toList()..sort();
    for (final date in dates) {
      final numbers = byDate[date]!.toList()..sort();
      var first = numbers.first;
      var last = first;
      for (final number in numbers.skip(1)) {
        if (number == last + 1) {
          last = number;
        } else {
          lessons.add((date: date, periodStart: first, periodEnd: last));
          first = last = number;
        }
      }
      lessons.add((date: date, periodStart: first, periodEnd: last));
    }
    return (lessons: lessons, unmapped: unmapped);
  }
}
