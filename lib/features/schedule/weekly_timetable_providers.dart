import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import 'lesson_schedule.dart';
import 'weekly_timetable.dart';

/// Every active group, for the weekly timetable. Kept local so the schedule
/// feature does not depend on the groups screen.
final _timetableGroupsProvider = StreamProvider.autoDispose<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).watchActiveGroups(),
);

/// One week of sessions across all groups, keyed by that week's Monday.
final _timetableSessionsProvider = StreamProvider.autoDispose
    .family<List<Session>, DateTime>(
      (ref, monday) => ref
          .watch(sessionRepositoryProvider)
          .watchSessionsInRange(start: monday, end: addDays(monday, 6)),
    );

/// The weekly timetable for the week the given date falls in: every lesson
/// each active group's weekly schedule calls for, with whether a session
/// already covers it. Highlights the ones still unplanned.
final weeklyTimetableProvider = Provider.autoDispose
    .family<AsyncValue<WeeklyTimetable>, DateTime>((ref, weekStart) {
      final monday = mondayOf(weekStart);
      final groupsValue = ref.watch(_timetableGroupsProvider);
      final slotsValue = ref.watch(lessonSlotsByGroupProvider);
      final sessionsValue = ref.watch(_timetableSessionsProvider(monday));

      return groupsValue.whenData((groups) {
        final slotsByGroup =
            slotsValue.value ?? const <int, List<LessonSlot>>{};
        final sessions = sessionsValue.value ?? const <Session>[];

        final timetableGroups = <TimetableGroup>[];
        for (final group in groups) {
          final slots = slotsByGroup[group.id] ?? const <LessonSlot>[];
          if (slots.isEmpty) continue;
          final categories = parseGradeCategories(group.gradeCategoriesJson);
          timetableGroups.add((
            id: group.id,
            name: group.name,
            colorHex: group.colorHex,
            slots: [
              for (final slot in slots) LessonSlotDraft.fromSlot(slot),
            ],
            categoryNames: {
              for (final category in categories) category.id: category.name,
            },
          ));
        }

        return buildWeeklyTimetable(
          weekStart: monday,
          groups: timetableGroups,
          sessions: sessions,
        );
      });
    });
