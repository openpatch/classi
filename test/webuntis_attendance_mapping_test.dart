import 'package:classi/features/webuntis/webuntis_attendance_mapping.dart';
import 'package:classi/features/webuntis/webuntis_models.dart';
import 'package:flutter_test/flutter_test.dart';

WebUntisAbsence absence({
  int id = 1,
  int studentId = 1,
  int klasseId = 11,
  required DateTime start,
  required DateTime end,
  bool excused = false,
}) {
  return WebUntisAbsence(
    id: id,
    studentId: studentId,
    klasseId: klasseId,
    startDateTime: start,
    endDateTime: end,
    excused: excused,
    absenceReason: '',
    text: '',
  );
}

void main() {
  final windowStart = DateTime(2026, 9, 1);
  final windowEnd = DateTime(2026, 9, 30);

  group('expandAbsenceDays', () {
    test('turns a single lesson absence into one day', () {
      final days = expandAbsenceDays(
        [
          absence(
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 8, 45),
          ),
        ],
        from: windowStart,
        to: windowEnd,
      );

      expect(days, hasLength(1));
      expect(days.single.date, DateTime(2026, 9, 3));
      expect(days.single.webUntisStudentId, 1);
      expect(days.single.excused, isFalse);
    });

    test('spreads a multi-day absence over every day it covers', () {
      final days = expandAbsenceDays(
        [
          absence(
            start: DateTime(2026, 9, 7, 8),
            end: DateTime(2026, 9, 9, 13),
          ),
        ],
        from: windowStart,
        to: windowEnd,
      );

      expect(days.map((day) => day.date), [
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 8),
        DateTime(2026, 9, 9),
      ]);
    });

    test('does not reach into a day a range only touches at midnight', () {
      // Untis writes a full day off as ending at 00:00 the next morning.
      final days = expandAbsenceDays(
        [absence(start: DateTime(2026, 9, 7), end: DateTime(2026, 9, 8))],
        from: windowStart,
        to: windowEnd,
      );

      expect(days.map((day) => day.date), [DateTime(2026, 9, 7)]);
    });

    test('clamps to the requested window', () {
      final days = expandAbsenceDays(
        [
          absence(
            start: DateTime(2026, 8, 28, 8),
            end: DateTime(2026, 9, 2, 13),
          ),
        ],
        from: windowStart,
        to: windowEnd,
      );

      expect(days.map((day) => day.date), [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
      ]);
    });

    test('counts a day as excused only when every absence on it is', () {
      final days = expandAbsenceDays(
        [
          absence(
            id: 1,
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 9),
            excused: true,
          ),
          absence(
            id: 2,
            start: DateTime(2026, 9, 3, 11),
            end: DateTime(2026, 9, 3, 12),
            excused: false,
          ),
          absence(
            id: 3,
            start: DateTime(2026, 9, 4, 8),
            end: DateTime(2026, 9, 4, 9),
            excused: true,
          ),
        ],
        from: windowStart,
        to: windowEnd,
      );

      expect(days, hasLength(2));
      expect(days.first.date, DateTime(2026, 9, 3));
      expect(days.first.excused, isFalse);
      expect(days.last.excused, isTrue);
    });

    test('keeps students apart', () {
      final days = expandAbsenceDays(
        [
          absence(
            id: 1,
            studentId: 1,
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 9),
          ),
          absence(
            id: 2,
            studentId: 2,
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 9),
            excused: true,
          ),
        ],
        from: windowStart,
        to: windowEnd,
      );

      expect(days, hasLength(2));
      expect(
        {for (final day in days) day.webUntisStudentId: day.excused},
        {1: false, 2: true},
      );
    });

    test('keeps only the requested classes when asked', () {
      final days = expandAbsenceDays(
        [
          absence(
            id: 1,
            klasseId: 11,
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 9),
          ),
          absence(
            id: 2,
            klasseId: 12,
            studentId: 2,
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 9),
          ),
        ],
        from: windowStart,
        to: windowEnd,
        klasseIds: {11},
      );

      expect(days.single.webUntisStudentId, 1);
    });

    test('survives a daylight saving change', () {
      // Whatever the local zone, stepping a day must land on the next
      // calendar day rather than 23:00 the same evening.
      final days = expandAbsenceDays(
        [
          absence(
            start: DateTime(2026, 10, 24, 8),
            end: DateTime(2026, 10, 26, 13),
          ),
        ],
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
      );

      expect(days.map((day) => day.date), [
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 26),
      ]);
    });

    test('returns nothing for an inverted window', () {
      final days = expandAbsenceDays(
        [absence(start: DateTime(2026, 9, 3, 8), end: DateTime(2026, 9, 3, 9))],
        from: windowEnd,
        to: windowStart,
      );

      expect(days, isEmpty);
    });
  });

  group('resolveAbsenceDays', () {
    test('rewrites WebUntis ids onto Classi students', () {
      final days = expandAbsenceDays(
        [
          absence(
            id: 1,
            studentId: 100,
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 9),
          ),
          absence(
            id: 2,
            studentId: 200,
            start: DateTime(2026, 9, 3, 8),
            end: DateTime(2026, 9, 3, 9),
          ),
        ],
        from: windowStart,
        to: windowEnd,
      );

      final resolved = resolveAbsenceDays(days, {100: 7});

      expect(resolved.entries, hasLength(1));
      expect(resolved.entries.single.studentId, 7);
      expect(resolved.entries.single.date, DateTime(2026, 9, 3));
      // A student with absences who is not in the group is reported rather
      // than dropped silently, so the teacher can import the class list.
      expect(resolved.unmatchedStudentIds, {200});
    });
  });
}
