import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/webuntis/webuntis_link.dart';
import 'package:classi/features/webuntis/webuntis_models.dart';
import 'package:classi/features/webuntis/webuntis_roster.dart';
import 'package:flutter_test/flutter_test.dart';

WebUntisPeriod period({
  required int id,
  required int lessonId,
  required DateTime start,
  required List<int> klasseIds,
  List<int> subjectIds = const [],
}) {
  return WebUntisPeriod(
    id: id,
    lessonId: lessonId,
    startDateTime: start,
    endDateTime: start.add(const Duration(minutes: 45)),
    elements: [
      for (final id in klasseIds)
        WebUntisPeriodElement(type: WebUntisElementType.klasse, id: id),
      for (final id in subjectIds)
        WebUntisPeriodElement(type: WebUntisElementType.subject, id: id),
      const WebUntisPeriodElement(type: WebUntisElementType.teacher, id: 7),
    ],
  );
}

Group groupRow({int? klasseId, String? lessonIds}) => Group(
  id: 1,
  name: 'G',
  colorHex: '#FF1E88E5',
  gradeScaleJson: '[]',
  gradeCategoriesJson: '[]',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  webuntisKlasseId: klasseId,
  webuntisLessonIds: lessonIds,
);

void main() {
  const userData = WebUntisUserData(
    displayName: 'T',
    schoolName: 'S',
    elementId: 7,
    elementType: WebUntisElementType.teacher,
    klassenIds: [],
    rights: [],
    masterDataTimestamp: 0,
    klassen: [
      WebUntisKlasse(id: 11, name: '10a', longName: '', active: true),
      WebUntisKlasse(id: 12, name: '10b', longName: '', active: true),
    ],
    schoolYears: [],
    subjects: [
      WebUntisSubject(id: 1, name: 'M', longName: 'Mathematik'),
      WebUntisSubject(id: 2, name: 'IF', longName: 'Informatik'),
    ],
  );

  group('lesson ids', () {
    test('round-trip through storage, sorted', () {
      expect(encodeLessonIds({30, 4, 12}), '4,12,30');
      expect(decodeLessonIds('4,12,30'), {4, 12, 30});
      expect(encodeLessonIds(const {}), isNull);
      expect(decodeLessonIds(null), isEmpty);
      expect(decodeLessonIds('4, x ,5'), {4, 5});
    });
  });

  group('WebUntisGroupLink.ofGroup', () {
    test('prefers a course over a class', () {
      final link = WebUntisGroupLink.ofGroup(
        groupRow(klasseId: 11, lessonIds: '4,5'),
      )!;
      expect(link.isCourse, isTrue);
      expect(link.lessonIds, {4, 5});
    });

    test('falls back to the class, and to nothing', () {
      expect(WebUntisGroupLink.ofGroup(groupRow(klasseId: 11))!.klasseId, 11);
      expect(WebUntisGroupLink.ofGroup(groupRow()), isNull);
    });

    test('a course includes its lessons only, whatever the classes', () {
      const link = WebUntisGroupLink.course({4});
      final mine = period(
        id: 1,
        lessonId: 4,
        start: DateTime(2026, 9, 1),
        klasseIds: [11, 12],
      );
      final other = period(
        id: 2,
        lessonId: 5,
        start: DateTime(2026, 9, 1),
        klasseIds: [11],
      );
      expect(link.includes(mine), isTrue);
      expect(link.includes(other), isFalse);
    });

    test('is a value, so it can key a provider', () {
      expect(
        const WebUntisGroupLink.course({4, 5}),
        const WebUntisGroupLink.course({5, 4}),
      );
      expect(
        const WebUntisGroupLink.klasse(11),
        isNot(const WebUntisGroupLink.course({11})),
      );
    });
  });

  group('coursesFromTimetable', () {
    test('joins lessons of one subject and set of classes', () {
      final courses = coursesFromTimetable([
        period(
          id: 1,
          lessonId: 40,
          start: DateTime(2026, 9, 21, 8), // Monday
          klasseIds: [11],
          subjectIds: [1],
        ),
        period(
          id: 2,
          lessonId: 41,
          start: DateTime(2026, 9, 24, 9, 45), // Thursday
          klasseIds: [11],
          subjectIds: [1],
        ),
        period(
          id: 3,
          lessonId: 40,
          start: DateTime(2026, 9, 28, 8), // next Monday, same slot
          klasseIds: [11],
          subjectIds: [1],
        ),
      ], userData);

      expect(courses, hasLength(1));
      expect(courses.single.displayName, 'M 10a');
      expect(courses.single.lessonIds, {40, 41});
      expect(courses.single.slots.map((s) => (s.weekday, s.hour)), [
        (DateTime.monday, 8),
        (DateTime.thursday, 9),
      ]);
    });

    test('keeps a course across classes apart from a class course', () {
      final courses = coursesFromTimetable([
        period(
          id: 1,
          lessonId: 50,
          start: DateTime(2026, 9, 21, 8),
          klasseIds: [11, 12],
          subjectIds: [2],
        ),
        period(
          id: 2,
          lessonId: 51,
          start: DateTime(2026, 9, 21, 10),
          klasseIds: [11],
          subjectIds: [2],
        ),
      ], userData);

      expect(courses.map((c) => c.displayName), ['IF 10a', 'IF 10a, 10b']);
    });

    test('leaves out duties without subject or class', () {
      expect(
        coursesFromTimetable([
          period(
            id: 1,
            lessonId: 60,
            start: DateTime(2026, 9, 21, 8),
            klasseIds: [],
          ),
        ], userData),
        isEmpty,
      );
    });
  });

  group('selectRosterPeriods for a course', () {
    test('reads shared registers, since the course is the shared part', () {
      final periods = [
        period(
          id: 1,
          lessonId: 50,
          start: DateTime(2026, 9, 21, 8),
          klasseIds: [11, 12],
        ),
        period(
          id: 2,
          lessonId: 51,
          start: DateTime(2026, 9, 21, 10),
          klasseIds: [11],
        ),
      ];

      expect(
        selectRosterPeriods(
          periods,
          link: const WebUntisGroupLink.course({50}),
        ).map((p) => p.id),
        [1],
      );
    });
  });
}
