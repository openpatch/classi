import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'lesson_schedule.dart';

/// A group's weekly timetable: the slots it saved, or — when it has none —
/// the pattern inferred from the lessons it already holds. Lets a teacher who
/// never opened the schedule editor still get a useful date suggestion.
final groupScheduleProvider = Provider.autoDispose
    .family<AsyncValue<List<LessonSlotDraft>>, int>((ref, groupId) {
      final slotsValue = ref.watch(groupLessonSlotsProvider(groupId));
      final sessionsValue = ref.watch(groupSessionsProvider(groupId));

      return slotsValue.whenData((slots) {
        if (slots.isNotEmpty) {
          return [for (final slot in slots) LessonSlotDraft.fromSlot(slot)];
        }
        return inferSlotsFromSessions(sessionsValue.value ?? const []);
      });
    });

/// Whether the group's schedule was set up by hand rather than guessed. Drives
/// the wording of the schedule card: a guess is presented as a suggestion.
final groupHasSavedScheduleProvider = Provider.autoDispose.family<bool, int>(
  (ref, groupId) =>
      ref.watch(groupLessonSlotsProvider(groupId)).value?.isNotEmpty ?? false,
);

/// The next lessons the schedule proposes, continuing on from the group's last
/// planned lesson rather than from today, so planning several in a row walks
/// the series forward instead of circling back to fill gaps.
final upcomingLessonSuggestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<PlannedLesson>>, int>((ref, groupId) {
      final scheduleValue = ref.watch(groupScheduleProvider(groupId));
      final sessionsValue = ref.watch(groupSessionsProvider(groupId));

      return scheduleValue.whenData((slots) {
        if (slots.isEmpty) return const <PlannedLesson>[];

        final anchor = suggestionAnchor(
          plannedDates: [
            for (final session in sessionsValue.value ?? const []) session.date,
          ],
          today: DateTime.now(),
        );

        // Every slot yields one date per week, so looking suggestionCount
        // weeks ahead always covers the wanted number of suggestions.
        return upcomingLessons(
          slots,
          from: anchor,
          weeks: suggestionCount,
        ).take(suggestionCount).toList();
      });
    });

/// How many upcoming lessons the quick-add offers as one-tap chips.
const int suggestionCount = 4;
