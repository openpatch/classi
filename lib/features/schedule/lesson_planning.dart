import 'dart:developer' as developer;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/widgets/app_error_state.dart';
import '../lessons/lesson_support.dart';
import '../sessions/session_form.dart';
import 'lesson_schedule.dart';
import 'lesson_schedule_editor_sheet.dart';
import 'lesson_schedule_providers.dart';

/// The group's saved weekly timetable, or the pattern inferred from the
/// lessons it already holds when nothing is saved yet.
Future<List<LessonSlotDraft>> resolveLessonSlots(
  WidgetRef ref,
  int groupId,
) async {
  final saved = await ref.read(lessonSlotRepositoryProvider).slots(groupId);
  if (saved.isNotEmpty) {
    return [for (final slot in saved) LessonSlotDraft.fromSlot(slot)];
  }

  final sessions = await ref
      .read(sessionRepositoryProvider)
      .sessionsForGroup(groupId);
  return inferSlotsFromSessions(sessions);
}

/// The next lessons the schedule calls for, continuing on from the group's
/// last planned lesson. Reads the cached value where a screen is already
/// watching it and falls back to querying, so the quick-add works from
/// anywhere.
Future<List<PlannedLesson>> upcomingSuggestions({
  required WidgetRef ref,
  required int groupId,
}) async {
  final cached = ref.read(upcomingLessonSuggestionsProvider(groupId)).value;
  if (cached != null) return cached;

  // The lessons already on the books serve twice over: they say where the
  // series has got to, and they are what a missing schedule is inferred from.
  final sessions = await ref
      .read(sessionRepositoryProvider)
      .sessionsForGroup(groupId);
  final saved = await ref.read(lessonSlotRepositoryProvider).slots(groupId);
  final slots = saved.isNotEmpty
      ? [for (final slot in saved) LessonSlotDraft.fromSlot(slot)]
      : inferSlotsFromSessions(sessions);
  if (slots.isEmpty) return const [];

  return upcomingLessons(
    slots,
    from: suggestionAnchor(
      plannedDates: [for (final session in sessions) session.date],
      today: DateTime.now(),
    ),
    weeks: suggestionCount,
  ).take(suggestionCount).toList();
}

/// Opens the session form for the next lesson the schedule calls for, with
/// date, periods and category already filled in. Falls back to the plain form
/// when the group has neither a schedule nor enough history to infer one.
Future<void> planNextLesson({
  required BuildContext context,
  required WidgetRef ref,
  required int groupId,
  required List<GradeCategory> categories,
}) async {
  final suggestions = await upcomingSuggestions(ref: ref, groupId: groupId);
  if (!context.mounted) return;

  final next = suggestions.isEmpty ? null : suggestions.first;
  final result = await showSessionFormSheet(
    context: context,
    gradeCategories: categories,
    title: 'plan_session'.tr(),
    initialDate: next?.date,
    initialCategoryId: next?.categoryId,
    initialPeriodStart: next?.periodStart ?? 0,
    initialPeriodEnd: next?.periodEnd ?? 0,
    suggestions: suggestions,
  );
  if (result == null) return;

  try {
    await ref
        .read(sessionRepositoryProvider)
        .upsertSession(
          groupId: groupId,
          date: result.date,
          categoryId: result.categoryId,
          categoryName: result.categoryName,
          label: result.label,
          description: result.description,
          periodStart: result.periodStart,
          periodEnd: result.periodEnd,
        );
  } catch (e, st) {
    developer.log(
      'Failed to plan lesson',
      name: 'classi.lesson_planning',
      level: 1000,
      error: e,
      stackTrace: st,
    );
    if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
  }
}

/// Opens the weekly-schedule editor and saves the result.
Future<void> editLessonSchedule({
  required BuildContext context,
  required WidgetRef ref,
  required int groupId,
  required List<GradeCategory> categories,
}) async {
  final saved = await ref.read(lessonSlotRepositoryProvider).slots(groupId);
  final current = [for (final slot in saved) LessonSlotDraft.fromSlot(slot)];

  // Only offer an inferred pattern when there is no schedule yet — once a
  // teacher has set one up, guessing over it would be noise.
  final suggested = current.isNotEmpty
      ? const <LessonSlotDraft>[]
      : inferSlotsFromSessions(
          await ref.read(sessionRepositoryProvider).sessionsForGroup(groupId),
        );
  if (!context.mounted) return;

  final result = await showLessonScheduleEditorSheet(
    context: context,
    gradeCategories: categories,
    initialSlots: current,
    suggestedSlots: suggested,
  );
  if (result == null) return;

  try {
    await ref
        .read(lessonSlotRepositoryProvider)
        .replaceSlots(groupId: groupId, drafts: result);
  } catch (e, st) {
    developer.log(
      'Failed to save lesson schedule',
      name: 'classi.lesson_planning',
      level: 1000,
      error: e,
      stackTrace: st,
    );
    if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
  }
}

/// A date range the schedule can be rolled out across, e.g. the rest of the
/// school year or one timeframe.
typedef PlanningRange = ({String label, DateTime start, DateTime end});

/// Lets the teacher pick a range and creates every lesson the schedule calls
/// for in it. Lessons that already exist are left untouched.
Future<void> fillTermWithLessons({
  required BuildContext context,
  required WidgetRef ref,
  required int groupId,
  required int? schoolYearId,
  required List<GradeCategory> categories,
}) async {
  final slots = await resolveLessonSlots(ref, groupId);
  if (!context.mounted) return;
  if (slots.isEmpty) {
    showErrorSnackBar(context, 'no_lesson_schedule_yet'.tr());
    return;
  }

  final ranges = await _planningRanges(ref, schoolYearId);
  if (!context.mounted) return;

  final range = await _pickRange(context: context, ranges: ranges);
  if (range == null || !context.mounted) return;

  final lessons = lessonsInRange(slots, start: range.start, end: range.end);
  if (lessons.isEmpty) {
    showErrorSnackBar(context, 'no_lessons_in_range'.tr());
    return;
  }

  final categoryNames = {for (final c in categories) c.id: c.name};
  try {
    final created = await ref
        .read(sessionRepositoryProvider)
        .planLessons(
          groupId: groupId,
          lessons: [
            for (final lesson in lessons)
              (
                date: lesson.date,
                periodStart: lesson.periodStart,
                periodEnd: lesson.periodEnd,
                categoryId: lesson.categoryId,
                categoryName:
                    categoryNames[lesson.categoryId] ??
                    categoryNameFor(
                      categoryId: lesson.categoryId,
                      categories: categories,
                    ),
                label: '',
              ),
          ],
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lessons_planned'.tr(namedArgs: {'count': '$created'})),
        ),
      );
    }
  } catch (e, st) {
    developer.log(
      'Failed to fill term with lessons',
      name: 'classi.lesson_planning',
      level: 1000,
      error: e,
      stackTrace: st,
    );
    if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
  }
}

/// The ranges offered when filling a term: what is left of the school year,
/// plus every timeframe of that year that has not ended yet.
Future<List<PlanningRange>> _planningRanges(
  WidgetRef ref,
  int? schoolYearId,
) async {
  final today = normalizeLessonDate(DateTime.now());
  if (schoolYearId == null) {
    // Without a school year there is nothing to bound the range with, so the
    // fallback is the next few months.
    return [
      (
        label: 'next_weeks'.tr(namedArgs: {'count': '4'}),
        start: today,
        end: addDays(today, 28),
      ),
      (
        label: 'next_weeks'.tr(namedArgs: {'count': '12'}),
        start: today,
        end: addDays(today, 84),
      ),
    ];
  }

  final schoolYear = await ref
      .read(schoolYearRepositoryProvider)
      .getSchoolYear(schoolYearId);
  final timeframes = await ref
      .read(timeframeRepositoryProvider)
      .getTimeframes(schoolYearId);

  final ranges = <PlanningRange>[];
  if (schoolYear != null &&
      !normalizeLessonDate(schoolYear.endDate).isBefore(today)) {
    ranges.add((
      label: 'rest_of_school_year'.tr(namedArgs: {'year': schoolYear.label}),
      start: today.isAfter(schoolYear.startDate)
          ? today
          : normalizeLessonDate(schoolYear.startDate),
      end: normalizeLessonDate(schoolYear.endDate),
    ));
  }

  for (final timeframe in timeframes) {
    final end = normalizeLessonDate(timeframe.endDate);
    if (end.isBefore(today)) continue;
    final start = normalizeLessonDate(timeframe.startDate);
    ranges.add((
      label: timeframe.label,
      start: start.isBefore(today) ? today : start,
      end: end,
    ));
  }

  return ranges;
}

Future<PlanningRange?> _pickRange({
  required BuildContext context,
  required List<PlanningRange> ranges,
}) {
  if (ranges.isEmpty) {
    showErrorSnackBar(context, 'no_planning_range'.tr());
    return Future.value(null);
  }

  return showModalBottomSheet<PlanningRange>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxLarge,
              0,
              AppSpacing.xxLarge,
              AppSpacing.medium,
            ),
            child: Text(
              'fill_term_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final range in ranges)
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text(range.label),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatMediumDate(range.start)}'
                ' – '
                '${MaterialLocalizations.of(context).formatMediumDate(range.end)}',
              ),
              onTap: () => Navigator.of(context).pop(range),
            ),
          const SizedBox(height: AppSpacing.large),
        ],
      ),
    ),
  );
}
