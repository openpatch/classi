import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/content_constraints.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/database/app_database.dart';
import '../lessons/lesson_support.dart';
import '../schedule/lesson_schedule.dart';
import '../schedule/lesson_schedule_editor_sheet.dart';
import 'today_repository.dart';

/// Landing screen after unlock: every active group's status for a chosen
/// date in one place, with a single tap into that group's lesson for that
/// date. Defaults to today; a date picker lets a teacher browse into the
/// past (e.g. to catch up on missed entries), with a quick way back to
/// today. Replaces having to open each group individually to see whether a
/// day's lesson has already been logged.
class TodayDashboardScreen extends ConsumerStatefulWidget {
  const TodayDashboardScreen({this.initialDate, super.key});

  /// The date to show initially. Defaults to today when omitted; browsing
  /// to a different date afterwards is local screen state, not reflected
  /// back into the route (matching Lesson Mode's own date picker).
  final DateTime? initialDate;

  @override
  ConsumerState<TodayDashboardScreen> createState() =>
      _TodayDashboardScreenState();
}

class _TodayDashboardScreenState extends ConsumerState<TodayDashboardScreen> {
  late DateTime _selectedDate = normalizeLessonDate(
    widget.initialDate ?? DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final today = normalizeLessonDate(DateTime.now());
    final isToday = _selectedDate == today;
    final overviewValue = ref.watch(todayOverviewProvider(_selectedDate));
    final slotsByGroup =
        ref.watch(lessonSlotsByGroupProvider).value ??
        const <int, List<LessonSlot>>{};

    return Scaffold(
      appBar: AppBar(
        title: Text('today'.tr()),
        actions: [
          if (!isToday)
            IconButton(
              onPressed: _goToToday,
              icon: const Icon(Icons.today_outlined),
              tooltip: 'today'.tr(),
            ),
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'date'.tr(),
          ),
        ],
      ),
      body: ContentConstraints(
        child: overviewValue.when(
          data: (overviews) {
            if (overviews.isEmpty) {
              return EmptyState(
                icon: Icons.groups_outlined,
                title: 'empty_groups'.tr(),
              );
            }

            return ListView(
              padding: appScreenPadding,
              children: [
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.small,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatFullDate(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                for (final overview in overviews) ...[
                  _TodayGroupCard(
                    overview: overview,
                    date: _selectedDate,
                    slots: [
                      for (final slot
                          in slotsByGroup[overview.group.id] ??
                              const <LessonSlot>[])
                        LessonSlotDraft.fromSlot(slot),
                    ],
                    onOpenLesson: () => _openLesson(overview.group.id),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
              ],
            );
          },
          error: (error, _) => const AppErrorState(),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }

    setState(() => _selectedDate = normalizeLessonDate(selected));
  }

  void _goToToday() {
    setState(() => _selectedDate = normalizeLessonDate(DateTime.now()));
  }

  void _openLesson(int groupId) {
    context.push(
      Uri(
        path: '/groups/$groupId/lesson',
        queryParameters: {'date': encodeLessonDate(_selectedDate)},
      ).toString(),
    );
  }
}

class _TodayGroupCard extends StatelessWidget {
  const _TodayGroupCard({
    required this.overview,
    required this.date,
    required this.slots,
    required this.onOpenLesson,
  });

  final TodayGroupOverview overview;

  /// The date the dashboard is showing, which the schedule is read against.
  final DateTime date;

  /// The group's weekly timetable, empty when it has none saved.
  final List<LessonSlotDraft> slots;

  final VoidCallback onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final group = overview.group;
    final groupColor = colorFromHex(group.colorHex);
    final colorScheme = Theme.of(context).colorScheme;

    // The periods the timetable puts this group in on the shown date, and —
    // when it has none that day — the next date it does, so a teacher can see
    // at a glance which groups are due and which are not.
    final todaysPeriods = [
      for (final slot in slots)
        if (slot.weekday == date.weekday)
          formatPeriodRange(slot.periodStart, slot.periodEnd),
    ]..removeWhere((periods) => periods.isEmpty);
    final nextLesson = todaysPeriods.isNotEmpty
        ? null
        : upcomingLessons(slots, from: addDays(date, 1)).firstOrNull;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenLesson,
        child: Padding(
          padding: appCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: groupColor.withValues(alpha: 0.18),
                    child: CircleAvatar(radius: 5, backgroundColor: groupColor),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (todaysPeriods.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.small),
                      child: _TodayStatChip(
                        icon: Icons.schedule_outlined,
                        label: 'periods_short'.tr(
                          namedArgs: {'periods': todaysPeriods.join(', ')},
                        ),
                      ),
                    ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (nextLesson != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  'next_lesson_on'.tr(
                    namedArgs: {'date': _formatNextLesson(context, nextLesson)},
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              if (overview.hasActivity)
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    _TodayStatChip(
                      icon: Icons.person_off_outlined,
                      label:
                          '${'absent'.tr()}: ${overview.absentCount}/${overview.totalStudents}',
                      emphasize: overview.absentCount > 0,
                    ),
                    _TodayStatChip(
                      icon: Icons.edit_note_outlined,
                      label:
                          '${'grades'.tr()}: ${overview.gradeCount}/${overview.totalStudents}',
                    ),
                    _TodayStatChip(
                      icon: Icons.fact_check_outlined,
                      label:
                          '${'homework'.tr()}: ${overview.homeworkCount}/${overview.totalStudents}',
                    ),
                    _TodayStatChip(
                      icon: Icons.backpack_outlined,
                      label:
                          '${'material'.tr()}: ${overview.materialCount}/${overview.totalStudents}',
                    ),
                  ],
                )
              else
                Text(
                  'lesson_not_started'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.medium),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onOpenLesson,
                  icon: Icon(
                    overview.hasActivity
                        ? Icons.arrow_forward
                        : Icons.play_arrow_outlined,
                  ),
                  label: Text(
                    (overview.hasActivity ? 'continue_lesson' : 'start_lesson')
                        .tr(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNextLesson(BuildContext context, PlannedLesson lesson) {
  final weekday = shortWeekdayName(context, lesson.date.weekday);
  final date = MaterialLocalizations.of(context).formatMediumDate(lesson.date);
  final periods = formatPeriodRange(lesson.periodStart, lesson.periodEnd);
  return periods.isEmpty ? '$weekday, $date' : '$weekday, $date · $periods';
}

class _TodayStatChip extends StatelessWidget {
  const _TodayStatChip({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = emphasize ? colorScheme.error : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasize
            ? colorScheme.errorContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
