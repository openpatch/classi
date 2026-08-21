import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_ui.dart';
import '../../shared/utils/grade_categories.dart';
import 'lesson_schedule.dart';

/// Highest school period a slot can be set to. Twelve covers a full day
/// including afternoon lessons in every German school model.
const int maxSchoolPeriod = 12;

/// The weekday's name in the current locale, e.g. "Monday" / "Montag".
/// [weekday] is an ISO weekday, [DateTime.monday] through [DateTime.sunday].
String weekdayName(BuildContext context, int weekday) {
  // 2024-01-01 was a Monday, so adding weekday - 1 lands on the wanted day.
  final reference = DateTime(2024, 1, weekday);
  return DateFormat.EEEE(context.locale.toLanguageTag()).format(reference);
}

/// The weekday's short name, e.g. "Mon" / "Mo".
String shortWeekdayName(BuildContext context, int weekday) {
  final reference = DateTime(2024, 1, weekday);
  return DateFormat.E(context.locale.toLanguageTag()).format(reference);
}

/// One slot rendered the way a timetable reads it: "Mon · 1+2".
String formatSlot(BuildContext context, LessonSlotDraft slot) {
  final periods = formatPeriodRange(slot.periodStart, slot.periodEnd);
  final weekday = shortWeekdayName(context, slot.weekday);
  return periods.isEmpty ? weekday : '$weekday · $periods';
}

/// Opens the editor for a group's weekly timetable.
///
/// Returns the timetable to save, or null if the user dismissed the sheet.
/// An empty list is a valid result and clears the schedule.
Future<List<LessonSlotDraft>?> showLessonScheduleEditorSheet({
  required BuildContext context,
  required List<GradeCategory> gradeCategories,
  required List<LessonSlotDraft> initialSlots,
  List<LessonSlotDraft> suggestedSlots = const [],
}) {
  return showModalBottomSheet<List<LessonSlotDraft>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _LessonScheduleEditorSheet(
      gradeCategories: gradeCategories,
      initialSlots: initialSlots,
      suggestedSlots: suggestedSlots,
    ),
  );
}

class _LessonScheduleEditorSheet extends StatefulWidget {
  const _LessonScheduleEditorSheet({
    required this.gradeCategories,
    required this.initialSlots,
    required this.suggestedSlots,
  });

  final List<GradeCategory> gradeCategories;
  final List<LessonSlotDraft> initialSlots;
  final List<LessonSlotDraft> suggestedSlots;

  @override
  State<_LessonScheduleEditorSheet> createState() =>
      _LessonScheduleEditorSheetState();
}

class _LessonScheduleEditorSheetState
    extends State<_LessonScheduleEditorSheet> {
  late List<LessonSlotDraft> _slots = [...widget.initialSlots];

  String get _defaultCategoryId => widget.gradeCategories.isNotEmpty
      ? widget.gradeCategories.first.id
      : defaultGradeCategoryId;

  /// Whether the inferred pattern is worth offering: there is one, and it is
  /// not already what the teacher has in the editor.
  bool get _showsSuggestion =>
      widget.suggestedSlots.isNotEmpty &&
      !_sameSlots(_slots, widget.suggestedSlots);

  static bool _sameSlots(List<LessonSlotDraft> a, List<LessonSlotDraft> b) {
    if (a.length != b.length) return false;
    final left = sortedSlots(a);
    final right = sortedSlots(b);
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxLarge,
        right: AppSpacing.xxLarge,
        top: AppSpacing.xxLarge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxLarge,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('lesson_schedule'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.small),
            Text(
              'lesson_schedule_hint'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            if (_showsSuggestion) ...[
              _SuggestionCard(
                slots: widget.suggestedSlots,
                onApply: () =>
                    setState(() => _slots = [...widget.suggestedSlots]),
              ),
              const SizedBox(height: AppSpacing.large),
            ],
            if (_slots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                child: Text(
                  'no_lesson_slots'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < _slots.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: _SlotRow(
                    // A DropdownButtonFormField seeds its state from
                    // initialValue once, so a row whose slot was replaced
                    // wholesale — by applying a detected pattern — needs a new
                    // key to show the new values rather than the old ones.
                    key: ValueKey('$i-${_slots[i].hashCode}'),
                    slot: _slots[i],
                    gradeCategories: widget.gradeCategories,
                    onChanged: (slot) => setState(() => _slots[i] = slot),
                    onRemove: () => setState(() => _slots.removeAt(i)),
                  ),
                ),
            const SizedBox(height: AppSpacing.small),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addSlot,
                icon: const Icon(Icons.add),
                label: Text('add_lesson_slot'.tr()),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                const SizedBox(width: AppSpacing.medium),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(sortedSlots(_slots)),
                  child: Text('save'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addSlot() {
    // Start the new slot on a weekday that is still free where possible, so
    // two rows do not immediately clash on the (weekday, period) unique key.
    final used = {for (final slot in _slots) (slot.weekday, slot.periodStart)};
    var weekday = DateTime.monday;
    var period = 1;
    for (
      var candidate = DateTime.monday;
      candidate <= DateTime.friday;
      candidate++
    ) {
      if (!used.any((entry) => entry.$1 == candidate)) {
        weekday = candidate;
        break;
      }
      weekday = candidate;
    }
    while (used.contains((weekday, period)) && period < maxSchoolPeriod) {
      period++;
    }

    setState(() {
      _slots = sortedSlots([
        ..._slots,
        LessonSlotDraft(
          weekday: weekday,
          periodStart: period,
          periodEnd: period + 1 <= maxSchoolPeriod ? period + 1 : period,
          categoryId: _defaultCategoryId,
        ),
      ]);
    });
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.slots, required this.onApply});

  final List<LessonSlotDraft> slots;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'detected_lesson_pattern'.tr(),
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            [for (final slot in slots) formatSlot(context, slot)].join(', '),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.small),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onApply,
              child: Text('use_pattern'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.gradeCategories,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final LessonSlotDraft slot;
  final List<GradeCategory> gradeCategories;
  final ValueChanged<LessonSlotDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                initialValue: slot.weekday,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'weekday'.tr()),
                items: [
                  for (
                    var weekday = DateTime.monday;
                    weekday <= DateTime.sunday;
                    weekday++
                  )
                    DropdownMenuItem<int>(
                      value: weekday,
                      child: Text(
                        weekdayName(context, weekday),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onChanged(slot.copyWith(weekday: value));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              flex: 2,
              child: _PeriodDropdown(
                label: 'period_from'.tr(),
                value: slot.periodStart,
                onChanged: (value) => onChanged(
                  slot.copyWith(
                    periodStart: value,
                    // Keep the block valid when the start moves past the end.
                    periodEnd: value > slot.periodEnd ? value : slot.periodEnd,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              flex: 2,
              child: _PeriodDropdown(
                label: 'period_to'.tr(),
                value: slot.periodEnd < slot.periodStart
                    ? slot.periodStart
                    : slot.periodEnd,
                min: slot.periodStart,
                onChanged: (value) =>
                    onChanged(slot.copyWith(periodEnd: value)),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              tooltip: 'delete'.tr(),
            ),
          ],
        ),
        if (gradeCategories.length > 1) ...[
          const SizedBox(height: AppSpacing.small),
          DropdownButtonFormField<String>(
            initialValue: gradeCategories.any((c) => c.id == slot.categoryId)
                ? slot.categoryId
                : gradeCategories.first.id,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'grade_category'.tr()),
            items: [
              for (final category in gradeCategories)
                DropdownMenuItem<String>(
                  value: category.id,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 7,
                        backgroundColor: colorForCategory(category),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(slot.copyWith(categoryId: value));
            },
          ),
        ],
      ],
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = value < min ? min : value;
    return DropdownButtonFormField<int>(
      // Both the selection and the range of offered periods can change from
      // the other dropdown, which the seeded form state would not pick up.
      key: ValueKey('$min-$effectiveValue'),
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var period = min; period <= maxSchoolPeriod; period++)
          DropdownMenuItem<int>(value: period, child: Text('$period')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
