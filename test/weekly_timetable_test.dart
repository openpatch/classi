import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/schedule/lesson_schedule.dart';
import 'package:classi/features/schedule/weekly_timetable.dart';
import 'package:flutter_test/flutter_test.dart';

const _monday = DateTime.monday;
const _wednesday = DateTime.wednesday;
const _saturday = DateTime.saturday;

// 2026-08-24 is a Monday.
final _weekMonday = DateTime(2026, 8, 24);
final _weekWednesday = DateTime(2026, 8, 26);

LessonSlotDraft _slot({
  int weekday = _monday,
  int periodStart = 1,
  int periodEnd = 2,
  String categoryId = 'sonstige-mitarbeit',
}) {
  return LessonSlotDraft(
    weekday: weekday,
    periodStart: periodStart,
    periodEnd: periodEnd,
    categoryId: categoryId,
  );
}

TimetableGroup _group({
  int id = 1,
  String name = 'Class 8a',
  required List<LessonSlotDraft> slots,
}) {
  return (
    id: id,
    name: name,
    colorHex: '#FF1E88E5',
    slots: slots,
    categoryNames: const {'sonstige-mitarbeit': 'Sonstige Mitarbeit'},
  );
}

Session _session({
  int groupId = 1,
  required DateTime date,
  int periodStart = 0,
  int periodEnd = 0,
}) {
  return Session(
    id: date.millisecondsSinceEpoch ~/ 1000 + periodStart,
    groupId: groupId,
    date: date,
    label: '',
    categoryId: 'sonstige-mitarbeit',
    categoryName: 'Sonstige Mitarbeit',
    periodStart: periodStart,
    periodEnd: periodEnd,
    createdAt: date,
  );
}

void main() {
  group('buildWeeklyTimetable', () {
    test('resolves each slot to its date in the shown week', () {
      final timetable = buildWeeklyTimetable(
        weekStart: _weekWednesday, // any day in the week
        groups: [
          _group(slots: [_slot(weekday: _monday), _slot(weekday: _wednesday)]),
        ],
        sessions: const [],
      );

      expect(timetable.weekStart, _weekMonday);
      expect(
        timetable.lessons.map((l) => l.date),
        [_weekMonday, _weekWednesday],
      );
    });

    test('marks a slot planned when a session covers its period block', () {
      final timetable = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(
            slots: [
              _slot(weekday: _monday, periodStart: 1, periodEnd: 2),
              _slot(weekday: _wednesday, periodStart: 3, periodEnd: 4),
            ],
          ),
        ],
        sessions: [
          _session(date: _weekMonday, periodStart: 2, periodEnd: 2),
        ],
      );

      final monday = timetable.lessons.firstWhere((l) => l.weekday == _monday);
      final wednesday = timetable.lessons.firstWhere(
        (l) => l.weekday == _wednesday,
      );
      expect(monday.planned, isTrue);
      expect(wednesday.planned, isFalse);
      expect(timetable.unplanned, [wednesday]);
    });

    test('a session without a period covers any slot that day', () {
      final timetable = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(slots: [_slot(weekday: _monday, periodStart: 5, periodEnd: 6)]),
        ],
        sessions: [_session(date: _weekMonday)],
      );

      expect(timetable.lessons.single.planned, isTrue);
    });

    test('does not match a session from another group or another day', () {
      final timetable = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(slots: [_slot(weekday: _monday, periodStart: 1, periodEnd: 2)]),
        ],
        sessions: [
          _session(groupId: 2, date: _weekMonday, periodStart: 1),
          _session(date: _weekWednesday, periodStart: 1),
        ],
      );

      expect(timetable.lessons.single.planned, isFalse);
    });

    test('columns cover Mon–Fri and stretch to a weekend slot', () {
      final weekdayOnly = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(slots: [_slot(weekday: _monday)]),
        ],
        sessions: const [],
      );
      expect(weekdayOnly.weekdays, [1, 2, 3, 4, 5]);

      final withSaturday = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(slots: [_slot(weekday: _saturday)]),
        ],
        sessions: const [],
      );
      expect(withSaturday.weekdays, [1, 2, 3, 4, 5, 6]);
    });

    test('period rows grow past the minimum for a late lesson', () {
      final short = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(slots: [_slot(periodStart: 1, periodEnd: 2)]),
        ],
        sessions: const [],
      );
      expect(short.periodCount, minVisiblePeriods);

      final long = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(slots: [_slot(periodStart: 8, periodEnd: 9)]),
        ],
        sessions: const [],
      );
      expect(long.periodCount, 9);
    });

    test('sorts lessons by weekday, then period, then group name', () {
      final timetable = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(id: 1, name: 'B', slots: [_slot(weekday: _wednesday)]),
          _group(
            id: 2,
            name: 'Z',
            slots: [_slot(weekday: _monday, periodStart: 1, periodEnd: 2)],
          ),
          _group(
            id: 3,
            name: 'A',
            slots: [_slot(weekday: _monday, periodStart: 1, periodEnd: 2)],
          ),
        ],
        sessions: const [],
      );

      expect(
        timetable.lessons.map((l) => (l.weekday, l.periodStart, l.groupName)),
        [(_monday, 1, 'A'), (_monday, 1, 'Z'), (_wednesday, 1, 'B')],
      );
    });

    test('carries the category display name from the group', () {
      final timetable = buildWeeklyTimetable(
        weekStart: _weekMonday,
        groups: [
          _group(slots: [_slot(categoryId: 'sonstige-mitarbeit')]),
        ],
        sessions: const [],
      );

      expect(timetable.lessons.single.categoryName, 'Sonstige Mitarbeit');
    });
  });
}
