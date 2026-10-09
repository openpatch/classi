import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/schedule/lesson_schedule.dart';
import 'package:classi/features/schedule/lesson_slot_repository.dart';
import 'package:classi/features/sessions/session_repository.dart';
import 'package:classi/features/webuntis/webuntis_lesson_sync.dart';
import 'package:classi/features/webuntis/webuntis_link.dart';
import 'package:classi/features/webuntis/webuntis_models.dart';
import 'package:classi/features/webuntis/webuntis_service.dart';
import 'package:classi/features/webuntis/webuntis_settings_service.dart';
import 'package:classi/features/webuntis/webuntis_timetable.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _monday = DateTime(2026, 10, 5);
const _grid = WebUntisTimeGrid({
  DateTime.monday: [
    (start: 480, end: 525),
    (start: 530, end: 575),
    (start: 590, end: 635),
    (start: 640, end: 685),
    (start: 700, end: 745),
  ],
});

WebUntisPeriod _period({
  int id = 1,
  int lessonId = 50,
  int start = 480,
  int end = 525,
  bool cancelled = false,
  DateTime? date,
}) {
  final day = date ?? _monday;
  return WebUntisPeriod(
    id: id,
    lessonId: lessonId,
    startDateTime: DateTime(
      day.year,
      day.month,
      day.day,
      start ~/ 60,
      start % 60,
    ),
    endDateTime: DateTime(day.year, day.month, day.day, end ~/ 60, end % 60),
    elements: const [
      WebUntisPeriodElement(type: WebUntisElementType.klasse, id: 11),
    ],
    cancelled: cancelled,
  );
}

class _FakeService extends WebUntisService {
  _FakeService()
    : super(
        keyService: KeyService(),
        databasePathService: DatabasePathService(),
        settingsService: WebUntisSettingsService(),
      );

  WebUntisTimetable timetable = WebUntisTimetable(periods: [], timeGrid: _grid);
  int loads = 0;
  int syncs = 0;

  @override
  Future<WebUntisTimetable> loadTimetable({
    required DateTime start,
    required DateTime end,
    WebUntisGroupLink? link,
  }) async {
    loads++;
    return timetable;
  }

  @override
  Future<void> markSynced() async => syncs++;
}

void main() {
  group('WebUntisTimetable', () {
    test('joins adjacent periods, deduplicates and keeps separate blocks', () {
      final timetable = WebUntisTimetable(
        periods: [
          _period(start: 700, end: 745),
          _period(start: 530, end: 575),
          _period(),
          _period(id: 2),
        ],
        timeGrid: _grid,
      );
      final result = timetable.lessonsFor(
        link: const WebUntisGroupLink.course({50}),
        start: _monday,
        end: _monday,
      );
      expect(result.lessons, [
        (date: _monday, periodStart: 1, periodEnd: 2),
        (date: _monday, periodStart: 5, periodEnd: 5),
      ]);
      expect(result.unmapped, 0);
    });

    test(
      'maps a double period and excludes cancelled, unrelated and old lessons',
      () {
        final result =
            WebUntisTimetable(
              periods: [
                _period(end: 575),
                _period(start: 590, end: 635, cancelled: true),
                _period(start: 640, end: 685, lessonId: 99),
                _period(date: DateTime(2026, 9, 28)),
              ],
              timeGrid: _grid,
            ).lessonsFor(
              link: const WebUntisGroupLink.course({50}),
              start: _monday,
              end: _monday,
            );
        expect(result.lessons, [(date: _monday, periodStart: 1, periodEnd: 2)]);
      },
    );

    test('reports missing bell times without inventing period numbers', () {
      final result =
          WebUntisTimetable(
            periods: [_period()],
            timeGrid: const WebUntisTimeGrid({}),
          ).lessonsFor(
            link: const WebUntisGroupLink.klasse(11),
            start: _monday,
            end: _monday,
          );
      expect(result.lessons, isEmpty);
      expect(result.unmapped, 1);
    });

    test('rejects backwards times and lessons outside the bell times', () {
      final result =
          WebUntisTimetable(
            periods: [_period(end: 470), _period(start: 900, end: 945)],
            timeGrid: _grid,
          ).lessonsFor(
            link: const WebUntisGroupLink.klasse(11),
            start: _monday,
            end: _monday,
          );
      expect(result.lessons, isEmpty);
      expect(result.unmapped, 2);
    });
  });

  group('WebUntisLessonSync', () {
    late AppDatabase database;
    late GroupRepository groups;
    late LessonSlotRepository slots;
    late SessionRepository sessions;
    late _FakeService service;
    late WebUntisLessonSync sync;
    late int groupId;

    setUp(() async {
      database = AppDatabase.test(NativeDatabase.memory());
      groups = GroupRepository(database);
      slots = LessonSlotRepository(database);
      sessions = SessionRepository(database);
      service = _FakeService();
      sync = WebUntisLessonSync(service: service, database: database);
      groupId = await groups.createGroup(
        name: 'Maths 10a',
        gradeScale: defaultGradeScaleEntries,
        webuntisLessonIds: '50',
        schoolYearId: 1,
      );
      service.timetable = WebUntisTimetable(
        periods: [_period(), _period(start: 530, end: 575)],
        timeGrid: _grid,
      );
    });

    tearDown(() => database.close());

    test(
      'previews without writing, then imports once with the slot category',
      () async {
        await slots.replaceSlots(
          groupId: groupId,
          drafts: const [
            LessonSlotDraft(
              weekday: DateTime.monday,
              periodStart: 1,
              periodEnd: 2,
              categoryId: 'klassenarbeit',
            ),
          ],
        );
        final preview = await sync.load(
          start: _monday,
          end: _monday,
          groupId: groupId,
        );
        expect(await sessions.sessionsForGroup(groupId), isEmpty);
        expect(preview.lessons.single.categoryId, 'klassenarbeit');
        expect(preview.lessons.single.alreadyExists, isFalse);
        expect(await sync.importLessons(preview.lessons), (
          added: 1,
          skipped: 0,
        ));
        final imported = (await sessions.sessionsForGroup(groupId)).single;
        expect((imported.periodStart, imported.periodEnd), (1, 2));
        expect(await sync.importLessons(preview.lessons), (
          added: 0,
          skipped: 1,
        ));
        expect(await sessions.sessionsForGroup(groupId), hasLength(1));
        final repeatedPreview = await sync.load(
          start: _monday,
          end: _monday,
          groupId: groupId,
        );
        expect(repeatedPreview.lessons.single.alreadyExists, isTrue);
        expect(service.syncs, 2);
      },
    );

    test(
      'keeps overlapping local lessons in another category and their notes',
      () async {
        final local = await sessions.upsertSession(
          groupId: groupId,
          date: _monday,
          periodStart: 2,
          periodEnd: 2,
          categoryId: 'klassenarbeit',
          categoryName: 'Exam',
          label: 'Fractions test',
          description: 'Keep this record',
        );
        final preview = await sync.load(
          start: _monday,
          end: _monday,
          groupId: groupId,
        );
        expect(await sync.importLessons(preview.lessons), (
          added: 0,
          skipped: 1,
        ));
        expect(preview.lessons.single.alreadyExists, isTrue);
        expect((await sessions.sessionsForGroup(groupId)).single, local);
      },
    );

    test(
      'only marks existing lessons in the same group, date and periods',
      () async {
        await sessions.upsertSession(
          groupId: groupId,
          date: _monday,
          categoryId: 'klassenarbeit',
          categoryName: 'Exam',
          periodStart: 1,
          periodEnd: 2,
        );
        final otherGroup = await groups.createGroup(
          name: 'History 10a',
          gradeScale: defaultGradeScaleEntries,
          webuntisLessonIds: '60',
          schoolYearId: 1,
        );
        final next = DateTime(2026, 10, 12);
        service.timetable = WebUntisTimetable(
          periods: [
            _period(),
            _period(start: 700, end: 745),
            _period(date: next),
            _period(lessonId: 60),
          ],
          timeGrid: _grid,
        );
        final preview = await sync.load(
          start: _monday,
          end: next,
          schoolYearId: 1,
        );
        expect(
          preview.lessons.map(
            (item) => (
              item.groupId,
              item.lesson.date,
              item.lesson.periodStart,
              item.alreadyExists,
            ),
          ),
          [
            (otherGroup, _monday, 1, false),
            (groupId, _monday, 1, true),
            (groupId, _monday, 5, false),
            (groupId, next, 1, false),
          ],
        );
        expect(await sync.importLessons(preview.lessons), (
          added: 3,
          skipped: 1,
        ));
      },
    );

    test('keeps whole-day local records and imports other days', () async {
      await sessions.upsertSession(
        groupId: groupId,
        date: _monday,
        categoryId: 'klassenarbeit',
        categoryName: 'Exam',
      );
      final next = DateTime(2026, 10, 12);
      service.timetable = WebUntisTimetable(
        periods: [
          _period(),
          _period(date: next),
        ],
        timeGrid: _grid,
      );
      final preview = await sync.load(
        start: _monday,
        end: next,
        groupId: groupId,
      );
      expect(preview.lessons.map((item) => item.alreadyExists), [true, false]);
      expect(await sync.importLessons(preview.lessons), (added: 1, skipped: 1));
      expect(await sessions.sessionsForGroup(groupId), hasLength(2));
    });

    test(
      'timetable sync filters archived, unlinked and other-year groups',
      () async {
        final archived = await groups.createGroup(
          name: 'Archived',
          gradeScale: defaultGradeScaleEntries,
          webuntisLessonIds: '50',
          schoolYearId: 1,
        );
        await groups.archiveGroup(archived);
        await groups.createGroup(
          name: 'Other year',
          gradeScale: defaultGradeScaleEntries,
          webuntisLessonIds: '50',
          schoolYearId: 2,
        );
        await groups.createGroup(
          name: 'Unlinked',
          gradeScale: defaultGradeScaleEntries,
        );
        final preview = await sync.load(
          start: _monday,
          end: _monday,
          schoolYearId: 1,
        );
        expect(preview.lessons.single.groupId, groupId);
        expect(service.loads, 1);
      },
    );

    test('imports all linked groups using one timetable request', () async {
      final otherGroup = await groups.createGroup(
        name: 'History 10a',
        gradeScale: defaultGradeScaleEntries,
        webuntisLessonIds: '60',
        schoolYearId: 1,
      );
      service.timetable = WebUntisTimetable(
        periods: [_period(), _period(lessonId: 60, start: 700, end: 745)],
        timeGrid: _grid,
      );
      final preview = await sync.load(
        start: _monday,
        end: _monday,
        schoolYearId: 1,
      );
      expect(preview.lessons.map((lesson) => lesson.groupId), [
        groupId,
        otherGroup,
      ]);
      expect(service.loads, 1);
      expect(await sync.importLessons(preview.lessons), (added: 2, skipped: 0));
      expect(await sessions.sessionsForGroup(groupId), hasLength(1));
      expect(
        (await sessions.sessionsForGroup(otherGroup)).single.periodStart,
        5,
      );
    });

    test('rolls back the entire import if one group cannot be saved', () async {
      await database.customStatement('PRAGMA foreign_keys = ON');
      final preview = await sync.load(
        start: _monday,
        end: _monday,
        groupId: groupId,
      );
      final valid = preview.lessons.single;
      final invalid = (
        groupId: 99999,
        groupName: 'Deleted group',
        lesson: valid.lesson,
        categoryId: valid.categoryId,
        categoryName: valid.categoryName,
        alreadyExists: false,
      );
      await expectLater(
        sync.importLessons([valid, invalid]),
        throwsA(anything),
      );
      expect(await sessions.sessionsForGroup(groupId), isEmpty);
      expect(service.syncs, 0);
    });

    test(
      'explains missing group links without requesting a timetable',
      () async {
        await groups.setWebUntisKlasseId(groupId: groupId, klasseId: null);
        final preview = await sync.load(
          start: _monday,
          end: _monday,
          groupId: groupId,
        );
        expect(preview.hasLinkedGroups, isFalse);
        expect(preview.lessons, isEmpty);
        expect(service.loads, 0);
      },
    );
  });
}
