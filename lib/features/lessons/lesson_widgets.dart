import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/utils/grade_categories.dart';

class LessonContextCard extends StatelessWidget {
  const LessonContextCard({
    required this.sessionController,
    required this.selectedDate,
    required this.gradeCategories,
    required this.selectedCategoryId,
    required this.onSessionChanged,
    required this.onCategoryChanged,
    required this.onPickDate,
    this.action,
    super.key,
  });

  final TextEditingController sessionController;
  final DateTime selectedDate;
  final List<GradeCategory> gradeCategories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSessionChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onPickDate;
  final Widget? action;

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
            const SizedBox(height: AppSpacing.large),
            DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              items: [
                for (final category in gradeCategories)
                  DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(
                      '${category.name} (${formatNumber(category.weight)})',
                    ),
                  ),
              ],
              onChanged: onCategoryChanged,
              decoration: InputDecoration(labelText: 'grade_category'.tr()),
            ),
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
