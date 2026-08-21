import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_ui.dart';
import '../../shared/utils/grade_categories.dart';
import '../schedule/lesson_schedule.dart';
import '../schedule/lesson_schedule_editor_sheet.dart';

typedef SessionFormResult = ({
  DateTime date,
  String label,
  String? description,
  String categoryId,
  String categoryName,
  int periodStart,
  int periodEnd,
});

/// Opens the session create/edit bottom sheet.
///
/// Returns [SessionFormResult] on save, or null if the user dismissed.
/// [suggestions] are the next lessons the group's weekly schedule calls for.
/// They are offered as one-tap chips above the date field, so planning the
/// next lesson is a single tap when the group keeps to its timetable.
Future<SessionFormResult?> showSessionFormSheet({
  required BuildContext context,
  required List<GradeCategory> gradeCategories,
  DateTime? initialDate,
  String? initialLabel,
  String? initialDescription,
  String? initialCategoryId,
  int initialPeriodStart = 0,
  int initialPeriodEnd = 0,
  List<PlannedLesson> suggestions = const [],
  String? title,
}) {
  return showModalBottomSheet<SessionFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _SessionFormSheet(
      gradeCategories: gradeCategories,
      initialDate: initialDate,
      initialLabel: initialLabel,
      initialDescription: initialDescription,
      initialCategoryId: initialCategoryId,
      initialPeriodStart: initialPeriodStart,
      initialPeriodEnd: initialPeriodEnd,
      suggestions: suggestions,
      title: title,
    ),
  );
}

class _SessionFormSheet extends StatefulWidget {
  const _SessionFormSheet({
    required this.gradeCategories,
    this.initialDate,
    this.initialLabel,
    this.initialDescription,
    this.initialCategoryId,
    this.initialPeriodStart = 0,
    this.initialPeriodEnd = 0,
    this.suggestions = const [],
    this.title,
  });

  final List<GradeCategory> gradeCategories;
  final DateTime? initialDate;
  final String? initialLabel;
  final String? initialDescription;
  final String? initialCategoryId;
  final int initialPeriodStart;
  final int initialPeriodEnd;
  final List<PlannedLesson> suggestions;
  final String? title;

  @override
  State<_SessionFormSheet> createState() => _SessionFormSheetState();
}

class _SessionFormSheetState extends State<_SessionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategoryId;
  late int _periodStart;
  late int _periodEnd;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _selectedDate = widget.initialDate != null
        ? DateTime(
            widget.initialDate!.year,
            widget.initialDate!.month,
            widget.initialDate!.day,
          )
        : DateTime.now().let(
            (d) => DateTime(d.year, d.month, d.day),
          );
    _selectedCategoryId =
        widget.initialCategoryId ??
        (widget.gradeCategories.isNotEmpty
            ? widget.gradeCategories.first.id
            : defaultGradeCategoryId);
    _periodStart = widget.initialPeriodStart < 0
        ? 0
        : widget.initialPeriodStart;
    _periodEnd = _periodStart == 0
        ? 0
        : (widget.initialPeriodEnd < _periodStart
              ? _periodStart
              : widget.initialPeriodEnd);
  }

  void _applySuggestion(PlannedLesson suggestion) {
    setState(() {
      _selectedDate = suggestion.date;
      _periodStart = suggestion.periodStart;
      _periodEnd = suggestion.periodEnd;
      if (widget.gradeCategories.any((c) => c.id == suggestion.categoryId)) {
        _selectedCategoryId = suggestion.categoryId;
      }
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'add_session'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (widget.suggestions.isNotEmpty) ...[
                Text(
                  'suggested_dates'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.small),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    for (final suggestion in widget.suggestions)
                      ChoiceChip(
                        selected:
                            suggestion.date == _selectedDate &&
                            suggestion.periodStart == _periodStart,
                        onSelected: (_) => _applySuggestion(suggestion),
                        avatar: const Icon(Icons.event_outlined, size: 18),
                        label: Text(_suggestionLabel(context, suggestion)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text('date'.tr()),
                subtitle: Text(
                  MaterialLocalizations.of(context).formatMediumDate(
                    _selectedDate,
                  ),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SessionPeriodDropdown(
                      label: 'period_from'.tr(),
                      value: _periodStart,
                      allowNone: true,
                      onChanged: (value) => setState(() {
                        _periodStart = value;
                        _periodEnd = value == 0
                            ? 0
                            : (value > _periodEnd ? value : _periodEnd);
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: _SessionPeriodDropdown(
                      label: 'period_to'.tr(),
                      value: _periodEnd,
                      min: _periodStart,
                      enabled: _periodStart > 0,
                      onChanged: (value) =>
                          setState(() => _periodEnd = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.gradeCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCategoryId),
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'grade_category'.tr(),
                  ),
                  items: [
                    for (final category in widget.gradeCategories)
                      DropdownMenuItem<String>(
                        value: category.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 7,
                              backgroundColor: colorForCategory(category),
                            ),
                            const SizedBox(width: 8),
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
                    if (value != null) {
                      setState(() => _selectedCategoryId = value);
                    }
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'session_label'.tr(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'session_description'.tr(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _save, child: Text('save'.tr())),
                ],
              ),
            ],
          ),
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
    if (selected == null) return;
    setState(
      () => _selectedDate = DateTime(selected.year, selected.month, selected.day),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final selectedCategory = widget.gradeCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => widget.gradeCategories.isNotEmpty
          ? widget.gradeCategories.first
          : GradeCategory(
              id: defaultGradeCategoryId,
              name: 'Sonstige Mitarbeit',
              weight: 1,
              colorHex: '#FF1E88E5',
            ),
    );

    Navigator.of(context).pop((
      date: _selectedDate,
      label: _labelController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: selectedCategory.id,
      categoryName: selectedCategory.name,
      periodStart: _periodStart,
      periodEnd: _periodStart == 0
          ? 0
          : (_periodEnd < _periodStart ? _periodStart : _periodEnd),
    ));
  }
}

String _suggestionLabel(BuildContext context, PlannedLesson suggestion) {
  final weekday = shortWeekdayName(context, suggestion.date.weekday);
  final date = MaterialLocalizations.of(
    context,
  ).formatShortDate(suggestion.date);
  final periods = formatPeriodRange(
    suggestion.periodStart,
    suggestion.periodEnd,
  );
  return periods.isEmpty
      ? '$weekday, $date'
      : '$weekday, $date · $periods';
}

/// Period picker for a single lesson. Unlike the schedule editor's, the start
/// dropdown offers "no period" for lessons that are not tied to a slot.
class _SessionPeriodDropdown extends StatelessWidget {
  const _SessionPeriodDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.allowNone = false,
    this.enabled = true,
  });

  final String label;
  final int value;
  final int min;
  final bool allowNone;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final lowest = min < 1 ? 1 : min;
    final effectiveValue = value <= 0
        ? (allowNone ? 0 : lowest)
        : (value < lowest ? lowest : value);

    return DropdownButtonFormField<int>(
      // Applying a suggestion and moving the start period both change this
      // from outside, which the seeded form state would not pick up.
      key: ValueKey('$lowest-$effectiveValue-$enabled'),
      initialValue: enabled ? effectiveValue : 0,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowNone || !enabled)
          DropdownMenuItem<int>(value: 0, child: Text('no_period'.tr())),
        for (var period = lowest; period <= maxSchoolPeriod; period++)
          DropdownMenuItem<int>(value: period, child: Text('$period')),
      ],
      onChanged: enabled
          ? (value) {
              if (value != null) onChanged(value);
            }
          : null,
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
