import 'dart:developer' as developer;
import 'dart:math' as math;

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
import '../lessons/lesson_support.dart';
import 'lesson_schedule.dart';
import 'lesson_schedule_editor_sheet.dart';
import 'weekly_timetable.dart';
import 'weekly_timetable_providers.dart';

/// A week of every group's lessons laid out like a school timetable —
/// weekdays across, school periods down — built from the weekly schedule set
/// per group. Lessons that the schedule calls for but that have no session
/// yet are drawn hollow so a teacher can see at a glance what is still
/// unplanned, and tap one to plan it.
class WeeklyTimetableScreen extends ConsumerStatefulWidget {
  const WeeklyTimetableScreen({super.key});

  @override
  ConsumerState<WeeklyTimetableScreen> createState() =>
      _WeeklyTimetableScreenState();
}

class _WeeklyTimetableScreenState extends ConsumerState<WeeklyTimetableScreen> {
  late DateTime _weekStart = mondayOf(DateTime.now());

  bool get _isCurrentWeek => _weekStart == mondayOf(DateTime.now());

  void _shiftWeek(int weeks) {
    setState(() => _weekStart = addDays(_weekStart, weeks * 7));
  }

  void _goToThisWeek() {
    setState(() => _weekStart = mondayOf(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final timetableValue = ref.watch(weeklyTimetableProvider(_weekStart));

    return Scaffold(
      appBar: AppBar(
        title: Text('timetable'.tr()),
        actions: [
          if (!_isCurrentWeek)
            IconButton(
              onPressed: _goToThisWeek,
              icon: const Icon(Icons.today_outlined),
              tooltip: 'this_week'.tr(),
            ),
          IconButton(
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'previous_week'.tr(),
          ),
          IconButton(
            onPressed: () => _shiftWeek(1),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'next_week'.tr(),
          ),
        ],
      ),
      body: ContentConstraints(
        child: timetableValue.when(
          data: (timetable) => _TimetableBody(
            timetable: timetable,
            onPlan: _planLesson,
            onOpen: _openLesson,
          ),
          error: (error, stackTrace) =>
              AppErrorState(error: error, stackTrace: stackTrace),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _openLesson(TimetableLesson lesson) {
    context.push(
      Uri(
        path: '/groups/${lesson.groupId}/lesson',
        queryParameters: {
          'date': encodeLessonDate(lesson.date),
          if (lesson.categoryId.isNotEmpty) 'category': lesson.categoryId,
          if (lesson.label.isNotEmpty) 'session': lesson.label,
        },
      ).toString(),
    );
  }

  Future<void> _planLesson(TimetableLesson lesson) async {
    final periods = formatPeriodRange(lesson.periodStart, lesson.periodEnd);
    final detail = [
      lesson.groupName,
      MaterialLocalizations.of(context).formatFullDate(lesson.date),
      if (periods.isNotEmpty) 'periods_short'.tr(namedArgs: {'periods': periods}),
    ].join('  ·  ');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('plan_lesson_question'.tr()),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('plan_lesson'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(sessionRepositoryProvider)
          .planLessons(
            groupId: lesson.groupId,
            lessons: [
              (
                date: lesson.date,
                periodStart: lesson.periodStart,
                periodEnd: lesson.periodEnd,
                categoryId: lesson.categoryId,
                categoryName: lesson.categoryName,
                label: '',
              ),
            ],
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('lesson_planned'.tr())));
      }
    } catch (e, st) {
      developer.log(
        'Failed to plan lesson from the timetable',
        name: 'classi.timetable',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
      }
    }
  }
}

class _TimetableBody extends StatelessWidget {
  const _TimetableBody({
    required this.timetable,
    required this.onPlan,
    required this.onOpen,
  });

  final WeeklyTimetable timetable;
  final void Function(TimetableLesson) onPlan;
  final void Function(TimetableLesson) onOpen;

  @override
  Widget build(BuildContext context) {
    if (timetable.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_view_week_outlined,
        title: 'timetable_empty'.tr(),
        body: 'timetable_empty_hint'.tr(),
      );
    }

    final unplannedCount = timetable.unplanned.length;

    return ListView(
      padding: appScreenPadding,
      children: [
        _WeekLabel(timetable: timetable),
        const SizedBox(height: AppSpacing.small),
        const _Legend(),
        if (unplannedCount > 0) ...[
          const SizedBox(height: AppSpacing.medium),
          _UnplannedBanner(count: unplannedCount),
        ],
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            // A five-to-seven column grid needs room to stay readable; below
            // that a phone reads the week better as a per-day agenda.
            if (constraints.maxWidth >= _gridMinWidth) {
              return _TimetableGrid(
                timetable: timetable,
                onPlan: onPlan,
                onOpen: onOpen,
              );
            }
            return _TimetableAgenda(
              timetable: timetable,
              onPlan: onPlan,
              onOpen: onOpen,
            );
          },
        ),
      ],
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel({required this.timetable});

  final WeeklyTimetable timetable;

  @override
  Widget build(BuildContext context) {
    final materialLocalizations = MaterialLocalizations.of(context);
    final start = timetable.weekStart;
    final end = addDays(start, timetable.weekdays.length - 1);
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.calendar_view_week_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            '${materialLocalizations.formatMediumDate(start)}'
            ' – '
            '${materialLocalizations.formatMediumDate(end)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Wrap(
      spacing: AppSpacing.large,
      runSpacing: AppSpacing.small,
      children: [
        _LegendItem(
          label: 'planned'.tr(),
          swatch: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(AppRadii.small / 2),
            ),
          ),
        ),
        _LegendItem(
          label: 'not_planned'.tr(),
          swatch: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(AppRadii.small / 2),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.swatch});

  final String label;
  final Widget swatch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 18, height: 18, child: swatch),
        const SizedBox(width: AppSpacing.small),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _UnplannedBanner extends StatelessWidget {
  const _UnplannedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 18,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'timetable_unplanned_count'.tr(namedArgs: {'count': '$count'}),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Content width at or above which the week is shown as a grid rather than a
/// per-day agenda.
const double _gridMinWidth = 620;

/// Layout constants for the grid, in logical pixels.
const double _periodColumnWidth = 40;
const double _rowHeight = 60;
const double _headerHeight = 36;
const double _minDayWidth = 112;
const double _blockGap = 3;

class _TimetableGrid extends StatelessWidget {
  const _TimetableGrid({
    required this.timetable,
    required this.onPlan,
    required this.onOpen,
  });

  final WeeklyTimetable timetable;
  final void Function(TimetableLesson) onPlan;
  final void Function(TimetableLesson) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekdays = timetable.weekdays;
    final periodCount = timetable.periodCount;
    final gridHeight = _rowHeight * periodCount;
    final withoutPeriod = [
      for (final lesson in timetable.lessons)
        if (lesson.periodStart <= 0) lesson,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - _periodColumnWidth;
        final dayWidth = math.max(_minDayWidth, available / weekdays.length);
        final daysWidth = dayWidth * weekdays.length;

        final days = SizedBox(
          width: daysWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(
                weekdays: weekdays,
                weekStart: timetable.weekStart,
                dayWidth: dayWidth,
              ),
              SizedBox(
                height: gridHeight,
                width: daysWidth,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridLinesPainter(
                          columns: weekdays.length,
                          rows: periodCount,
                          color: theme.dividerColor,
                        ),
                      ),
                    ),
                    for (final placed in _placeLessons(timetable, dayWidth))
                      Positioned(
                        left: placed.left,
                        top: placed.top,
                        width: placed.width,
                        height: placed.height,
                        child: _LessonBlock(
                          lesson: placed.lesson,
                          onTap: () => placed.lesson.planned
                              ? onOpen(placed.lesson)
                              : onPlan(placed.lesson),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _headerHeight + gridHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The period column stays pinned while the days scroll.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: _headerHeight,
                        width: _periodColumnWidth,
                      ),
                      _PeriodColumn(periodCount: periodCount),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: days,
                    ),
                  ),
                ],
              ),
            ),
            if (withoutPeriod.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.large),
              Text(
                'timetable_no_period'.tr(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final lesson in withoutPeriod)
                    _LessonChip(
                      lesson: lesson,
                      onTap: () =>
                          lesson.planned ? onOpen(lesson) : onPlan(lesson),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// Positions every period-bearing lesson in grid coordinates, giving lessons
  /// that overlap on a weekday their own lane so neither is hidden.
  List<_PlacedLesson> _placeLessons(WeeklyTimetable timetable, double dayWidth) {
    final placed = <_PlacedLesson>[];

    for (var column = 0; column < timetable.weekdays.length; column++) {
      final weekday = timetable.weekdays[column];
      final dayLessons = [
        for (final lesson in timetable.lessonsOn(weekday))
          if (lesson.periodStart > 0) lesson,
      ]..sort((a, b) {
        final byStart = a.periodStart.compareTo(b.periodStart);
        return byStart != 0 ? byStart : a.periodEnd.compareTo(b.periodEnd);
      });

      // Interval partitioning: put each lesson in the first lane whose last
      // lesson has already ended.
      final laneEnds = <int>[];
      final laneOf = <int>[];
      for (final lesson in dayLessons) {
        var lane = laneEnds.indexWhere((end) => end < lesson.periodStart);
        if (lane == -1) {
          lane = laneEnds.length;
          laneEnds.add(0);
        }
        laneEnds[lane] = lesson.periodEnd;
        laneOf.add(lane);
      }
      final laneCount = math.max(1, laneEnds.length);
      final laneWidth = dayWidth / laneCount;

      for (var i = 0; i < dayLessons.length; i++) {
        final lesson = dayLessons[i];
        placed.add(
          _PlacedLesson(
            lesson: lesson,
            left:
                column * dayWidth + laneOf[i] * laneWidth + _blockGap,
            top: (lesson.periodStart - 1) * _rowHeight + _blockGap,
            width: laneWidth - _blockGap * 2,
            height:
                (lesson.periodEnd - lesson.periodStart + 1) * _rowHeight -
                _blockGap * 2,
          ),
        );
      }
    }

    return placed;
  }
}

class _PlacedLesson {
  const _PlacedLesson({
    required this.lesson,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final TimetableLesson lesson;
  final double left;
  final double top;
  final double width;
  final double height;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.weekdays,
    required this.weekStart,
    required this.dayWidth,
  });

  final List<int> weekdays;
  final DateTime weekStart;
  final double dayWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = normalizeLessonDate(DateTime.now());

    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          for (var i = 0; i < weekdays.length; i++)
            SizedBox(
              width: dayWidth,
              child: Center(
                child: Text(
                  '${shortWeekdayName(context, weekdays[i])} '
                  '${addDays(weekStart, weekdays[i] - 1).day}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: addDays(weekStart, weekdays[i] - 1) == today
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodColumn extends StatelessWidget {
  const _PeriodColumn({required this.periodCount});

  final int periodCount;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return SizedBox(
      width: _periodColumnWidth,
      child: Column(
        children: [
          for (var period = 1; period <= periodCount; period++)
            SizedBox(
              height: _rowHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                  child: Text('$period', style: style),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  const _GridLinesPainter({
    required this.columns,
    required this.rows,
    required this.color,
  });

  final int columns;
  final int rows;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final columnWidth = size.width / columns;
    final rowHeight = size.height / rows;

    for (var c = 0; c <= columns; c++) {
      final x = c * columnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var r = 0; r <= rows; r++) {
      final y = r * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridLinesPainter oldDelegate) =>
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows ||
      oldDelegate.color != color;
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({required this.lesson, required this.onTap});

  final TimetableLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupColor = colorFromHex(lesson.groupColorHex);
    // The block's row span already shows the periods, so the second line
    // carries the lesson's label, falling back to its category.
    final detail = lesson.label.isNotEmpty
        ? lesson.label
        : lesson.categoryName;

    final BoxDecoration decoration;
    if (lesson.planned) {
      decoration = BoxDecoration(
        color: groupColor.withValues(alpha: 0.16),
        border: Border.all(color: groupColor.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(AppRadii.small / 2),
      );
    } else {
      decoration = BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: groupColor, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadii.small / 2),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.small / 2),
        child: Ink(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.xSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: groupColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xSmall),
                  Expanded(
                    child: Text(
                      lesson.groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  if (!lesson.planned)
                    Icon(
                      Icons.add,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: lesson.label.isNotEmpty
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
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

class _TimetableAgenda extends StatelessWidget {
  const _TimetableAgenda({
    required this.timetable,
    required this.onPlan,
    required this.onOpen,
  });

  final WeeklyTimetable timetable;
  final void Function(TimetableLesson) onPlan;
  final void Function(TimetableLesson) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = normalizeLessonDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final weekday in timetable.weekdays) ...[
          _AgendaDayHeader(
            weekday: weekday,
            date: addDays(timetable.weekStart, weekday - 1),
            isToday: addDays(timetable.weekStart, weekday - 1) == today,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          if (timetable.lessonsOn(weekday).isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 52,
                bottom: AppSpacing.medium,
              ),
              child: Text(
                'timetable_no_lessons_day'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final lesson in timetable.lessonsOn(weekday))
              _AgendaRow(
                lesson: lesson,
                onTap: () =>
                    lesson.planned ? onOpen(lesson) : onPlan(lesson),
              ),
          const SizedBox(height: AppSpacing.medium),
        ],
      ],
    );
  }
}

class _AgendaDayHeader extends StatelessWidget {
  const _AgendaDayHeader({
    required this.weekday,
    required this.date,
    required this.isToday,
  });

  final int weekday;
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isToday
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        children: [
          Text(
            weekdayName(context, weekday),
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            MaterialLocalizations.of(context).formatMediumDate(date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.lesson, required this.onTap});

  final TimetableLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupColor = colorFromHex(lesson.groupColorHex);
    final periods = formatPeriodRange(lesson.periodStart, lesson.periodEnd);
    final detail = lesson.label.isNotEmpty
        ? lesson.label
        : lesson.categoryName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.small / 2),
              ),
              child: Text(
                periods.isEmpty ? '–' : periods,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: groupColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xSmall),
                      Expanded(
                        child: Text(
                          lesson.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: lesson.label.isNotEmpty
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Icon(
              lesson.planned
                  ? Icons.check_circle
                  : Icons.add_circle_outline,
              size: 20,
              color: lesson.planned
                  ? groupColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonChip extends StatelessWidget {
  const _LessonChip({required this.lesson, required this.onTap});

  final TimetableLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final groupColor = colorFromHex(lesson.groupColorHex);

    return ActionChip(
      avatar: CircleAvatar(backgroundColor: groupColor, radius: 7),
      label: Text(
        '${shortWeekdayName(context, lesson.weekday)} · ${lesson.groupName}',
      ),
      onPressed: onTap,
      side: lesson.planned
          ? null
          : BorderSide(color: groupColor, width: 1.5),
    );
  }
}
