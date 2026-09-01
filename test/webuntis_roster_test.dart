import 'package:classi/features/webuntis/webuntis_models.dart';
import 'package:classi/features/webuntis/webuntis_roster.dart';
import 'package:flutter_test/flutter_test.dart';

WebUntisPeriod period({
  required int id,
  required DateTime start,
  required List<int> klasseIds,
}) {
  return WebUntisPeriod(
    id: id,
    lessonId: id,
    startDateTime: start,
    endDateTime: start.add(const Duration(minutes: 45)),
    elements: [
      for (final klasseId in klasseIds)
        WebUntisPeriodElement(type: WebUntisElementType.klasse, id: klasseId),
      const WebUntisPeriodElement(type: WebUntisElementType.teacher, id: 7),
    ],
  );
}

WebUntisPeriodData register({
  required int ttId,
  required List<int> studentIds,
}) {
  return WebUntisPeriodData(
    ttId: ttId,
    absenceChecked: true,
    studentIds: studentIds,
    absences: const [],
  );
}

void main() {
  group('selectRosterPeriods', () {
    test('ignores lessons of other classes', () {
      final periods = [
        period(id: 1, start: DateTime(2026, 9, 1, 8), klasseIds: [11]),
        period(id: 2, start: DateTime(2026, 9, 1, 9), klasseIds: [12]),
      ];

      expect(selectRosterPeriods(periods, klasseId: 11).map((p) => p.id), [1]);
    });

    test('prefers lessons held for this class alone', () {
      final periods = [
        // A combined course: its register covers both classes, so using it
        // would import students who are not in the group.
        period(id: 1, start: DateTime(2026, 9, 3, 8), klasseIds: [11, 12]),
        period(id: 2, start: DateTime(2026, 9, 1, 8), klasseIds: [11]),
      ];

      expect(selectRosterPeriods(periods, klasseId: 11).map((p) => p.id), [2]);
    });

    test('falls back to shared lessons when there are no exclusive ones', () {
      final periods = [
        period(id: 1, start: DateTime(2026, 9, 3, 8), klasseIds: [11, 12]),
      ];

      expect(selectRosterPeriods(periods, klasseId: 11).map((p) => p.id), [1]);
    });

    test('takes the most recent lessons up to the limit', () {
      final periods = [
        for (var day = 1; day <= 5; day++)
          period(id: day, start: DateTime(2026, 9, day, 8), klasseIds: [11]),
      ];

      expect(
        selectRosterPeriods(periods, klasseId: 11, limit: 3).map((p) => p.id),
        [5, 4, 3],
      );
    });

    test('returns nothing when the class has no lessons', () {
      expect(selectRosterPeriods(const [], klasseId: 11), isEmpty);
    });
  });

  group('studentsFromRegisters', () {
    test('unions the enrolled students and sorts them by name', () {
      final result = WebUntisPeriodDataResult(
        dataByTtId: {
          1: register(ttId: 1, studentIds: [100, 200]),
          // A split group: only half the class attends this lesson.
          2: register(ttId: 2, studentIds: [200, 300]),
        },
        referencedStudents: const [
          WebUntisPerson(id: 100, firstName: 'Alan', lastName: 'Turing'),
          WebUntisPerson(id: 200, firstName: 'Ada', lastName: 'Lovelace'),
          WebUntisPerson(id: 300, firstName: 'Grace', lastName: 'Hopper'),
        ],
      );

      expect(studentsFromRegisters(result).map((s) => s.fullName), [
        'Grace Hopper',
        'Ada Lovelace',
        'Alan Turing',
      ]);
    });

    test('drops enrolled ids the server did not describe', () {
      final result = WebUntisPeriodDataResult(
        dataByTtId: {
          1: register(ttId: 1, studentIds: [100, 999]),
        },
        referencedStudents: const [
          WebUntisPerson(id: 100, firstName: 'Ada', lastName: 'Lovelace'),
        ],
      );

      expect(studentsFromRegisters(result).map((s) => s.id), [100]);
    });

    test('falls back to referenced students when no list was sent', () {
      final result = WebUntisPeriodDataResult(
        dataByTtId: {1: register(ttId: 1, studentIds: const [])},
        referencedStudents: const [
          WebUntisPerson(id: 100, firstName: 'Ada', lastName: 'Lovelace'),
        ],
      );

      expect(studentsFromRegisters(result).map((s) => s.id), [100]);
    });

    test('is empty when the register could not be read at all', () {
      const result = WebUntisPeriodDataResult(
        dataByTtId: {},
        referencedStudents: [],
      );

      expect(studentsFromRegisters(result), isEmpty);
    });
  });
}
