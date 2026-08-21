import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/schedule/lesson_schedule.dart';
import 'package:classi/features/schedule/lesson_slot_repository.dart';
import 'package:classi/features/sessions/session_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late LessonSlotRepository slotRepository;
  late SessionRepository sessionRepository;
  late int groupId;

  setUp(() async {
    // Production opens the database with foreign keys on (see
    // cipher_opener.dart); the in-memory one has to be told, or cascading
    // deletes silently do nothing here.
    database = AppDatabase.test(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    groupRepository = GroupRepository(database);
    slotRepository = LessonSlotRepository(database);
    sessionRepository = SessionRepository(database);
    groupId = await groupRepository.createGroup(
      name: '10A',
      gradeScale: defaultGradeScaleEntries,
    );
  });

  tearDown(() async {
    await database.close();
  });

  const monday = LessonSlotDraft(
    weekday: DateTime.monday,
    periodStart: 1,
    periodEnd: 2,
    categoryId: 'sonstige-mitarbeit',
  );
  const friday = LessonSlotDraft(
    weekday: DateTime.friday,
    periodStart: 3,
    periodEnd: 4,
    categoryId: 'sonstige-mitarbeit',
  );

  group('LessonSlotRepository', () {
    test(
      'saves a weekly schedule and reads it back in timetable order',
      () async {
        await slotRepository.replaceSlots(
          groupId: groupId,
          drafts: const [friday, monday],
        );

        final slots = await slotRepository.slots(groupId);
        expect(slots.map((s) => s.weekday), [DateTime.monday, DateTime.friday]);
        expect(slots.first.periodStart, 1);
        expect(slots.first.periodEnd, 2);
      },
    );

    test('replacing the schedule drops what was there before', () async {
      await slotRepository.replaceSlots(
        groupId: groupId,
        drafts: const [monday, friday],
      );
      await slotRepository.replaceSlots(
        groupId: groupId,
        drafts: const [monday],
      );

      final slots = await slotRepository.slots(groupId);
      expect(slots, hasLength(1));
      expect(slots.single.weekday, DateTime.monday);
    });

    test('drops drafts that collide on weekday and period', () async {
      await slotRepository.replaceSlots(
        groupId: groupId,
        drafts: const [
          monday,
          LessonSlotDraft(
            weekday: DateTime.monday,
            periodStart: 1,
            periodEnd: 4,
            categoryId: 'klassenarbeit',
          ),
        ],
      );

      expect(await slotRepository.slots(groupId), hasLength(1));
    });

    test('an empty schedule clears the group', () async {
      await slotRepository.replaceSlots(
        groupId: groupId,
        drafts: const [monday],
      );
      await slotRepository.replaceSlots(groupId: groupId, drafts: const []);

      expect(await slotRepository.slots(groupId), isEmpty);
    });

    test('deleting the group takes its schedule with it', () async {
      await slotRepository.replaceSlots(
        groupId: groupId,
        drafts: const [monday],
      );
      await groupRepository.deleteGroup(groupId);

      expect(await slotRepository.slots(groupId), isEmpty);
    });

    test('watchSlotsByGroup keys the schedules by group', () async {
      final otherGroupId = await groupRepository.createGroup(
        name: '10B',
        gradeScale: defaultGradeScaleEntries,
      );
      await slotRepository.replaceSlots(
        groupId: groupId,
        drafts: const [monday],
      );
      await slotRepository.replaceSlots(
        groupId: otherGroupId,
        drafts: const [friday],
      );

      final byGroup = await slotRepository.watchSlotsByGroup().first;
      expect(byGroup[groupId]!.single.weekday, DateTime.monday);
      expect(byGroup[otherGroupId]!.single.weekday, DateTime.friday);
    });
  });

  group('sessions with periods', () {
    test(
      'two lessons on one day sit side by side when periods differ',
      () async {
        final date = DateTime(2026, 8, 24);

        await sessionRepository.upsertSession(
          groupId: groupId,
          date: date,
          categoryId: 'sonstige-mitarbeit',
          categoryName: 'Sonstige Mitarbeit',
          periodStart: 1,
          periodEnd: 2,
        );
        await sessionRepository.upsertSession(
          groupId: groupId,
          date: date,
          categoryId: 'sonstige-mitarbeit',
          categoryName: 'Sonstige Mitarbeit',
          periodStart: 5,
          periodEnd: 5,
        );

        final sessions = await sessionRepository.sessionsForGroup(groupId);
        expect(sessions, hasLength(2));
        expect(sessions.map((s) => s.periodStart).toList()..sort(), [1, 5]);
      },
    );

    test(
      'the same period on the same day updates instead of duplicating',
      () async {
        final date = DateTime(2026, 8, 24);

        await sessionRepository.upsertSession(
          groupId: groupId,
          date: date,
          categoryId: 'sonstige-mitarbeit',
          categoryName: 'Sonstige Mitarbeit',
          label: 'Draft',
          periodStart: 1,
          periodEnd: 2,
        );
        await sessionRepository.upsertSession(
          groupId: groupId,
          date: date,
          categoryId: 'sonstige-mitarbeit',
          categoryName: 'Sonstige Mitarbeit',
          label: 'Final',
          periodStart: 1,
          periodEnd: 3,
        );

        final sessions = await sessionRepository.sessionsForGroup(groupId);
        expect(sessions, hasLength(1));
        expect(sessions.single.label, 'Final');
        expect(sessions.single.periodEnd, 3);
      },
    );

    test('an end before the start collapses to a single period', () async {
      await sessionRepository.upsertSession(
        groupId: groupId,
        date: DateTime(2026, 8, 24),
        categoryId: 'sonstige-mitarbeit',
        categoryName: 'Sonstige Mitarbeit',
        periodStart: 4,
        periodEnd: 2,
      );

      final session = (await sessionRepository.sessionsForGroup(
        groupId,
      )).single;
      expect(session.periodStart, 4);
      expect(session.periodEnd, 4);
    });

    test('lesson mode attaches to the lesson planned into a period', () async {
      final date = DateTime(2026, 8, 24);
      await sessionRepository.upsertSession(
        groupId: groupId,
        date: date,
        categoryId: 'sonstige-mitarbeit',
        categoryName: 'Sonstige Mitarbeit',
        periodStart: 1,
        periodEnd: 2,
      );

      // Lesson mode knows only the date, not the period it was planned for.
      await sessionRepository.upsertSessionForDate(
        groupId: groupId,
        date: date,
        categoryId: 'sonstige-mitarbeit',
        categoryName: 'Sonstige Mitarbeit',
        label: 'Vectors',
      );

      final sessions = await sessionRepository.sessionsForGroup(groupId);
      expect(sessions, hasLength(1));
      expect(sessions.single.label, 'Vectors');
      expect(sessions.single.periodStart, 1);
      expect(sessions.single.periodEnd, 2);
    });
  });

  group('planLessons', () {
    test(
      'creates the missing lessons and leaves existing ones alone',
      () async {
        await sessionRepository.upsertSession(
          groupId: groupId,
          date: DateTime(2026, 8, 24),
          categoryId: 'sonstige-mitarbeit',
          categoryName: 'Sonstige Mitarbeit',
          label: 'Already there',
          periodStart: 1,
          periodEnd: 2,
        );

        final planned = lessonsInRange(
          const [monday],
          start: DateTime(2026, 8, 24),
          end: DateTime(2026, 9, 14),
        );

        final created = await sessionRepository.planLessons(
          groupId: groupId,
          lessons: [
            for (final lesson in planned)
              (
                date: lesson.date,
                periodStart: lesson.periodStart,
                periodEnd: lesson.periodEnd,
                categoryId: lesson.categoryId,
                categoryName: 'Sonstige Mitarbeit',
                label: '',
              ),
          ],
        );

        expect(created, 3);
        final sessions = await sessionRepository.sessionsForGroup(groupId);
        expect(sessions, hasLength(4));
        expect(
          sessions.firstWhere((s) => s.date == DateTime(2026, 8, 24)).label,
          'Already there',
        );
      },
    );

    test('running it twice adds nothing the second time', () async {
      final lessons = [
        for (final lesson in lessonsInRange(
          const [monday],
          start: DateTime(2026, 8, 24),
          end: DateTime(2026, 9, 14),
        ))
          (
            date: lesson.date,
            periodStart: lesson.periodStart,
            periodEnd: lesson.periodEnd,
            categoryId: lesson.categoryId,
            categoryName: 'Sonstige Mitarbeit',
            label: '',
          ),
      ];

      expect(
        await sessionRepository.planLessons(groupId: groupId, lessons: lessons),
        4,
      );
      expect(
        await sessionRepository.planLessons(groupId: groupId, lessons: lessons),
        0,
      );
    });
  });
}
