import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/schedule/lesson_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

Session _session({
  required DateTime date,
  int periodStart = 0,
  int periodEnd = 0,
  String categoryId = 'sonstige-mitarbeit',
}) {
  return Session(
    id: date.millisecondsSinceEpoch ~/ 1000 + periodStart,
    groupId: 1,
    date: date,
    label: '',
    categoryId: categoryId,
    categoryName: 'Sonstige Mitarbeit',
    periodStart: periodStart,
    periodEnd: periodEnd,
    createdAt: date,
  );
}

const _monday = DateTime.monday;
const _wednesday = DateTime.wednesday;
const _friday = DateTime.friday;

void main() {
  group('formatPeriodRange', () {
    test('renders single, double and longer blocks', () {
      expect(formatPeriodRange(3, 3), '3');
      expect(formatPeriodRange(1, 2), '1+2');
      expect(formatPeriodRange(1, 4), '1–4');
    });

    test('is empty when the lesson has no period', () {
      expect(formatPeriodRange(0, 0), '');
      expect(formatPeriodRange(0, 5), '');
    });

    test('treats an end before the start as a single period', () {
      expect(formatPeriodRange(4, 2), '4');
    });
  });

  group('nextDateForWeekday', () {
    // 2026-08-21 is a Friday.
    final friday = DateTime(2026, 8, 21);

    test('returns the same day when it already matches', () {
      expect(nextDateForWeekday(_friday, from: friday), friday);
    });

    test('rolls into the next week', () {
      expect(nextDateForWeekday(_monday, from: friday), DateTime(2026, 8, 24));
      expect(
        nextDateForWeekday(_wednesday, from: friday),
        DateTime(2026, 8, 26),
      );
    });

    test('steps over a daylight-saving change without slipping a day', () {
      // Late October: adding a raw Duration would land on the Sunday before.
      final lessons = lessonsInRange(
        [
          const LessonSlotDraft(
            weekday: _monday,
            periodStart: 1,
            periodEnd: 2,
            categoryId: 'sonstige-mitarbeit',
          ),
        ],
        start: DateTime(2026, 10, 19),
        end: DateTime(2026, 11, 9),
      );

      expect(lessons.map((l) => l.date.weekday), everyElement(_monday));
      expect(lessons.map((l) => l.date), [
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 26),
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 9),
      ]);
    });

    test('drops the time of day', () {
      expect(
        nextDateForWeekday(_friday, from: DateTime(2026, 8, 21, 14, 30)),
        DateTime(2026, 8, 21),
      );
    });
  });

  group('upcomingLessons', () {
    final slots = [
      const LessonSlotDraft(
        weekday: _monday,
        periodStart: 1,
        periodEnd: 2,
        categoryId: 'sonstige-mitarbeit',
      ),
      const LessonSlotDraft(
        weekday: _friday,
        periodStart: 3,
        periodEnd: 4,
        categoryId: 'sonstige-mitarbeit',
      ),
    ];

    test('orders the next lessons by date', () {
      // Starting on a Wednesday, Friday comes before the following Monday.
      final lessons = upcomingLessons(
        slots,
        from: DateTime(2026, 8, 19),
        weeks: 2,
      );

      expect(lessons.map((l) => l.date), [
        DateTime(2026, 8, 21),
        DateTime(2026, 8, 24),
        DateTime(2026, 8, 28),
        DateTime(2026, 8, 31),
      ]);
      expect(lessons.first.periodStart, 3);
      expect(lessons.first.periodEnd, 4);
    });

    test('orders same-day lessons by period', () {
      final lessons = upcomingLessons([
        const LessonSlotDraft(
          weekday: _monday,
          periodStart: 5,
          periodEnd: 5,
          categoryId: 'a',
        ),
        const LessonSlotDraft(
          weekday: _monday,
          periodStart: 1,
          periodEnd: 2,
          categoryId: 'b',
        ),
      ], from: DateTime(2026, 8, 24));

      expect(lessons.map((l) => l.periodStart), [1, 5]);
    });
  });

  group('suggestionAnchor', () {
    // 2026-08-21 is a Friday.
    final today = DateTime(2026, 8, 21);

    test('starts at today when nothing is planned yet', () {
      expect(suggestionAnchor(plannedDates: const [], today: today), today);
    });

    test('continues the day after the last planned lesson', () {
      expect(
        suggestionAnchor(
          plannedDates: [
            DateTime(2026, 9, 7),
            DateTime(2026, 9, 21),
            DateTime(2026, 9, 14),
          ],
          today: today,
        ),
        DateTime(2026, 9, 22),
      );
    });

    test('does not fall back into the past for a dormant group', () {
      expect(
        suggestionAnchor(plannedDates: [DateTime(2025, 12, 15)], today: today),
        today,
      );
    });

    test('moves past a lesson planned for today', () {
      expect(
        suggestionAnchor(plannedDates: [today], today: today),
        DateTime(2026, 8, 22),
      );
    });

    test('ignores the time of day on either side', () {
      expect(
        suggestionAnchor(
          plannedDates: [DateTime(2026, 9, 7, 18, 45)],
          today: DateTime(2026, 8, 21, 9, 30),
        ),
        DateTime(2026, 9, 8),
      );
    });
  });

  group('suggestions continue the series', () {
    final slots = [
      const LessonSlotDraft(
        weekday: _monday,
        periodStart: 1,
        periodEnd: 2,
        categoryId: 'sonstige-mitarbeit',
      ),
      const LessonSlotDraft(
        weekday: _friday,
        periodStart: 3,
        periodEnd: 4,
        categoryId: 'sonstige-mitarbeit',
      ),
    ];

    test('picks up after the last lesson rather than filling a gap', () {
      // Planned solidly into September, except that one Friday was skipped.
      // The next suggestion continues the series, it does not go back to
      // fill the hole.
      final planned = [
        DateTime(2026, 8, 24),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 4),
        DateTime(2026, 9, 7),
      ];

      final anchor = suggestionAnchor(
        plannedDates: planned,
        today: DateTime(2026, 8, 21),
      );
      final next = upcomingLessons(slots, from: anchor, weeks: 4).first;

      expect(anchor, DateTime(2026, 9, 8));
      expect(next.date, DateTime(2026, 9, 11));
      expect(next.periodStart, 3);
    });

    test('a group with nothing planned starts from today', () {
      final anchor = suggestionAnchor(
        plannedDates: const [],
        today: DateTime(2026, 8, 21),
      );

      expect(
        upcomingLessons(slots, from: anchor, weeks: 4).first.date,
        DateTime(2026, 8, 21),
      );
    });
  });

  group('lessonsInRange', () {
    final slots = [
      const LessonSlotDraft(
        weekday: _monday,
        periodStart: 1,
        periodEnd: 2,
        categoryId: 'sonstige-mitarbeit',
      ),
    ];

    test('covers every matching weekday in the range, inclusive', () {
      final lessons = lessonsInRange(
        slots,
        start: DateTime(2026, 8, 24),
        end: DateTime(2026, 9, 14),
      );

      expect(lessons.map((l) => l.date), [
        DateTime(2026, 8, 24),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 14),
      ]);
    });

    test('is empty when the range runs backwards', () {
      expect(
        lessonsInRange(
          slots,
          start: DateTime(2026, 9, 14),
          end: DateTime(2026, 8, 24),
        ),
        isEmpty,
      );
    });
  });

  group('inferSlotsFromSessions', () {
    test('finds the dominant weekdays and their periods', () {
      // Four weeks of "Monday 1+2, Friday 3+4".
      final sessions = [
        for (var week = 0; week < 4; week++) ...[
          _session(
            date: DateTime(2026, 8, 3 + 7 * week),
            periodStart: 1,
            periodEnd: 2,
          ),
          _session(
            date: DateTime(2026, 8, 7 + 7 * week),
            periodStart: 3,
            periodEnd: 4,
          ),
        ],
      ];

      final slots = inferSlotsFromSessions(sessions);

      expect(slots, [
        const LessonSlotDraft(
          weekday: _monday,
          periodStart: 1,
          periodEnd: 2,
          categoryId: 'sonstige-mitarbeit',
        ),
        const LessonSlotDraft(
          weekday: _friday,
          periodStart: 3,
          periodEnd: 4,
          categoryId: 'sonstige-mitarbeit',
        ),
      ]);
    });

    test('ignores a one-off make-up lesson on another weekday', () {
      final sessions = [
        for (var week = 0; week < 6; week++)
          _session(
            date: DateTime(2026, 8, 3 + 7 * week),
            periodStart: 1,
            periodEnd: 2,
          ),
        // A single Wednesday stand-in.
        _session(date: DateTime(2026, 8, 12), periodStart: 5, periodEnd: 5),
      ];

      expect(inferSlotsFromSessions(sessions).map((s) => s.weekday), [_monday]);
    });

    test('keeps two distinct periods on the same weekday', () {
      final sessions = [
        for (var week = 0; week < 3; week++) ...[
          _session(
            date: DateTime(2026, 8, 3 + 7 * week),
            periodStart: 1,
            periodEnd: 2,
          ),
          _session(
            date: DateTime(2026, 8, 3 + 7 * week),
            periodStart: 6,
            periodEnd: 6,
          ),
        ],
      ];

      expect(inferSlotsFromSessions(sessions).map((s) => s.periodStart), [
        1,
        6,
      ]);
    });

    test('gives up when there is too little history', () {
      expect(inferSlotsFromSessions(const []), isEmpty);
      expect(
        inferSlotsFromSessions([_session(date: DateTime(2026, 8, 3))]),
        isEmpty,
      );
    });

    test('carries the category the weekday most often ran with', () {
      final sessions = [
        for (var week = 0; week < 3; week++)
          _session(
            date: DateTime(2026, 8, 3 + 7 * week),
            periodStart: 1,
            periodEnd: 2,
            categoryId: 'klassenarbeit',
          ),
      ];

      expect(
        inferSlotsFromSessions(sessions).single.categoryId,
        'klassenarbeit',
      );
    });

    test('only looks at the most recent lessons', () {
      // Last year the group met on Wednesdays, this year on Mondays. The
      // window is inferenceSessionLimit lessons, so the old rhythm is out of
      // sight once enough new ones exist.
      final sessions = [
        for (var week = 0; week < inferenceSessionLimit; week++)
          _session(
            date: DateTime(2026, 8, 3 + 7 * week),
            periodStart: 1,
            periodEnd: 2,
          ),
        for (var week = 0; week < 10; week++)
          _session(
            date: DateTime(2025, 9, 3 + 7 * week),
            periodStart: 5,
            periodEnd: 6,
          ),
      ];

      expect(inferSlotsFromSessions(sessions).map((s) => s.weekday), [_monday]);
    });
  });
}
