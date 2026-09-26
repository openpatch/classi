import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_ui.dart';
import '../../shared/utils/grade_categories.dart';
import 'lesson_periods.dart';

class LessonContextCard extends StatelessWidget {
  const LessonContextCard({
    required this.sessionController,
    required this.selectedDate,
    required this.onSessionChanged,
    required this.onPickDate,
    this.action,
    this.topicSource,
    this.lessonSelector,
    super.key,
  });

  final TextEditingController sessionController;
  final DateTime selectedDate;
  final ValueChanged<String> onSessionChanged;
  final VoidCallback onPickDate;
  final Widget? action;

  /// Shown right under the topic field: where else a topic could come from,
  /// such as the WebUntis class register.
  final Widget? topicSource;

  /// Picks which of the day's lessons this is, below the date.
  final Widget? lessonSelector;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: sessionController,
              decoration: InputDecoration(labelText: 'session_label'.tr()),
              onChanged: onSessionChanged,
            ),
            if (topicSource != null) ...[
              const SizedBox(height: AppSpacing.medium),
              topicSource!,
            ],
            const SizedBox(height: AppSpacing.large),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('date'.tr()),
              subtitle: Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(selectedDate),
              ),
              trailing: IconButton(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined),
              ),
            ),
            if (lessonSelector != null) ...[
              const SizedBox(height: AppSpacing.small),
              lessonSelector!,
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.medium),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class LessonCategoryFabMenu extends StatefulWidget {
  const LessonCategoryFabMenu({
    required this.categories,
    required this.onSelected,
    required this.heroTagPrefix,
    required this.mainLabel,
    this.selectedCategoryId,
    this.mainIcon = Icons.category_outlined,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final List<GradeCategory> categories;
  final ValueChanged<GradeCategory> onSelected;
  final String heroTagPrefix;
  final String mainLabel;
  final String? selectedCategoryId;
  final IconData mainIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<LessonCategoryFabMenu> createState() => _LessonCategoryFabMenuState();
}

class _LessonCategoryFabMenuState extends State<LessonCategoryFabMenu> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor =
        widget.backgroundColor ?? theme.colorScheme.primaryContainer;
    final foregroundColor =
        widget.foregroundColor ?? onColorForBackground(backgroundColor);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: !_expanded,
          child: AnimatedOpacity(
            opacity: _expanded ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final category in widget.categories.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: _LessonCategoryFabEntry(
                      category: category,
                      selected: category.id == widget.selectedCategoryId,
                      heroTag: '${widget.heroTagPrefix}-${category.id}',
                      onPressed: () {
                        setState(() => _expanded = false);
                        widget.onSelected(category);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        FloatingActionButton.extended(
          heroTag: '${widget.heroTagPrefix}-main',
          onPressed: widget.categories.length == 1
              ? () => widget.onSelected(widget.categories.single)
              : () => setState(() => _expanded = !_expanded),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          icon: Icon(_expanded ? Icons.close : widget.mainIcon),
          label: Text(widget.mainLabel),
        ),
      ],
    );
  }
}

class _LessonCategoryFabEntry extends StatelessWidget {
  const _LessonCategoryFabEntry({
    required this.category,
    required this.selected,
    required this.heroTag,
    required this.onPressed,
  });

  final GradeCategory category;
  final bool selected;
  final String heroTag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final categoryColor = colorForCategory(category);
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppRadii.large);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              child: Text(
                category.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        FloatingActionButton.small(
          heroTag: heroTag,
          onPressed: onPressed,
          backgroundColor: categoryColor,
          foregroundColor: onColorForBackground(categoryColor),
          child: Icon(selected ? Icons.check : Icons.circle, size: 18),
        ),
      ],
    );
  }
}

class LessonTriStateField extends StatelessWidget {
  const LessonTriStateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool? value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.small),
        SegmentedButton<_LessonTriState>(
          segments: const [
            ButtonSegment<_LessonTriState>(
              value: _LessonTriState.unset,
              label: Text('-'),
            ),
            ButtonSegment<_LessonTriState>(
              value: _LessonTriState.yes,
              icon: Icon(Icons.check, size: 18),
            ),
            ButtonSegment<_LessonTriState>(
              value: _LessonTriState.no,
              icon: Icon(Icons.close, size: 18),
            ),
          ],
          selected: {_mapValue(value)},
          onSelectionChanged: enabled
              ? (selection) => onChanged(_unmapValue(selection.first))
              : null,
          showSelectedIcon: false,
        ),
      ],
    );
  }

  _LessonTriState _mapValue(bool? rawValue) {
    if (rawValue == null) {
      return _LessonTriState.unset;
    }
    return rawValue ? _LessonTriState.yes : _LessonTriState.no;
  }

  bool? _unmapValue(_LessonTriState value) {
    switch (value) {
      case _LessonTriState.unset:
        return null;
      case _LessonTriState.yes:
        return true;
      case _LessonTriState.no:
        return false;
    }
  }
}

enum _LessonTriState { unset, yes, no }

/// Chips for the lessons a group has on the day, plus a whole-day entry.
class LessonPicker extends StatelessWidget {
  const LessonPicker({
    required this.lessons,
    required this.selected,
    required this.weekday,
    required this.bellTimes,
    required this.onSelected,
    super.key,
  });

  final List<LessonPeriods> lessons;
  final LessonPeriods? selected;
  final int weekday;
  final BellTimes bellTimes;
  final ValueChanged<LessonPeriods?> onSelected;

  @override
  Widget build(BuildContext context) {
    // A lesson chosen by hand that the timetable does not know still shows.
    final all = [
      ...lessons,
      if (selected != null && !lessons.contains(selected)) selected!,
    ]..sort((a, b) => a.start.compareTo(b.start));

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.xSmall,
      children: [
        for (final lesson in all)
          ChoiceChip(
            label: Text(lessonLabel(lesson)),
            selected: lesson == selected,
            onSelected: (_) => onSelected(lesson),
          ),
        ChoiceChip(
          label: Text('lesson_whole_day'.tr()),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
      ],
    );
  }

  String lessonLabel(LessonPeriods lesson) {
    final periods = lesson.start == lesson.end
        ? 'lesson_period'.tr(namedArgs: {'period': '${lesson.start}'})
        : 'lesson_periods'.tr(
            namedArgs: {'start': '${lesson.start}', 'end': '${lesson.end}'},
          );
    final span = lessonMinutes(lesson, weekday, bellTimes);
    if (span == null) return periods;
    String clock(int minutes) =>
        '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';
    return '$periods · ${clock(span.start)}–${clock(span.end)}';
  }
}
