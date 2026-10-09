import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../groups/group_repository.dart';
import '../schedule/lesson_slot_repository.dart';
import '../sessions/session_repository.dart';
import 'webuntis_link.dart';
import 'webuntis_service.dart';
import 'webuntis_timetable.dart';

final webUntisLessonSyncProvider = Provider<WebUntisLessonSync>(
  (ref) => WebUntisLessonSync(
    service: ref.watch(webUntisServiceProvider),
    database: ref.watch(databaseProvider),
  ),
);

typedef WebUntisLessonImport = ({
  int groupId,
  String groupName,
  WebUntisScheduledLesson lesson,
  String categoryId,
  String categoryName,
  bool alreadyExists,
});

typedef WebUntisLessonPreview = ({
  List<WebUntisLessonImport> lessons,
  int unmapped,
  bool hasLinkedGroups,
});

class WebUntisLessonSync {
  WebUntisLessonSync({
    required WebUntisService service,
    required AppDatabase database,
  }) : _service = service,
       _database = database,
       _groups = GroupRepository(database),
       _slots = LessonSlotRepository(database),
       _sessions = SessionRepository(database);

  final WebUntisService _service;
  final AppDatabase _database;
  final GroupRepository _groups;
  final LessonSlotRepository _slots;
  final SessionRepository _sessions;

  Future<WebUntisLessonPreview> load({
    required DateTime start,
    required DateTime end,
    int? groupId,
    int? schoolYearId,
  }) async {
    final groups = groupId == null
        ? await _groups.watchActiveGroups(schoolYearId: schoolYearId).first
        : [?await _groups.watchGroup(groupId).first];
    final linked = <({Group group, WebUntisGroupLink link})>[
      for (final group in groups)
        if (group.archivedAt == null)
          if (WebUntisGroupLink.ofGroup(group) case final link?)
            (group: group, link: link),
    ];
    if (linked.isEmpty) {
      return (
        lessons: const <WebUntisLessonImport>[],
        unmapped: 0,
        hasLinkedGroups: false,
      );
    }

    final timetable = await _service.loadTimetable(
      start: start,
      end: end,
      link: linked.length == 1 ? linked.single.link : null,
    );
    final lessons = <WebUntisLessonImport>[];
    final existingByGroupAndDate = <(int, DateTime), List<Session>>{};
    final existing = await _sessions
        .watchSessionsInRange(start: start, end: end)
        .first;
    for (final session in existing) {
      existingByGroupAndDate
          .putIfAbsent((session.groupId, session.date), () => [])
          .add(session);
    }
    var unmapped = 0;
    for (final entry in linked) {
      final resolved = timetable.lessonsFor(
        link: entry.link,
        start: start,
        end: end,
      );
      unmapped += resolved.unmapped;
      final categories = gradableCategories(
        parseGradeCategories(entry.group.gradeCategoriesJson),
      );
      final fallback = categories.firstWhere(
        (category) => category.id == defaultGradeCategoryId,
        orElse: () => categories.first,
      );
      final slots = await _slots.slots(entry.group.id);
      for (final lesson in resolved.lessons) {
        final slot = slots
            .where(
              (slot) =>
                  slot.weekday == lesson.date.weekday &&
                  slot.periodStart <= lesson.periodEnd &&
                  lesson.periodStart <= slot.periodEnd,
            )
            .firstOrNull;
        final category =
            categories
                .where((category) => category.id == slot?.categoryId)
                .firstOrNull ??
            fallback;
        lessons.add((
          groupId: entry.group.id,
          groupName: entry.group.name,
          lesson: lesson,
          categoryId: category.id,
          categoryName: category.name,
          alreadyExists:
              existingByGroupAndDate[(entry.group.id, lesson.date)]?.any(
                (session) =>
                    session.periodStart == 0 ||
                    (session.periodStart <= lesson.periodEnd &&
                        lesson.periodStart <= session.periodEnd),
              ) ??
              false,
        ));
      }
    }
    lessons.sort((a, b) {
      final byDate = a.lesson.date.compareTo(b.lesson.date);
      if (byDate != 0) return byDate;
      final byPeriod = a.lesson.periodStart.compareTo(b.lesson.periodStart);
      if (byPeriod != 0) return byPeriod;
      return a.groupName.compareTo(b.groupName);
    });
    return (lessons: lessons, unmapped: unmapped, hasLinkedGroups: true);
  }

  Future<({int added, int skipped})> importLessons(
    List<WebUntisLessonImport> lessons,
  ) async {
    final byGroup = <int, List<WebUntisLessonImport>>{};
    for (final lesson in lessons) {
      byGroup.putIfAbsent(lesson.groupId, () => []).add(lesson);
    }
    var added = 0;
    await _database.transaction(() async {
      for (final entry in byGroup.entries) {
        added += await _sessions.planLessons(
          groupId: entry.key,
          skipOverlapping: true,
          lessons: [
            for (final item in entry.value)
              (
                date: item.lesson.date,
                periodStart: item.lesson.periodStart,
                periodEnd: item.lesson.periodEnd,
                categoryId: item.categoryId,
                categoryName: item.categoryName,
                label: '',
              ),
          ],
        );
      }
    });
    await _service.markSynced();
    return (added: added, skipped: lessons.length - added);
  }
}
