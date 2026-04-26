import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import 'grade_picker_dialog.dart';

typedef GradeEditorResult = ({
  String categoryId,
  String categoryName,
  DateTime date,
  String sessionLabel,
  String value,
});

Future<GradeEditorResult?> showGradeEditorSheet({
  required BuildContext context,
  required List<String> gradeScale,
  required List<GradeCategory> gradeCategories,
  DateTime? initialDate,
  String? initialSessionLabel,
  String? initialValue,
  String? initialCategoryId,
  String? title,
}) {
  return showModalBottomSheet<GradeEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _GradeEditorSheet(
      gradeScale: gradeScale,
      gradeCategories: gradeCategories,
      initialDate: initialDate,
      initialSessionLabel: initialSessionLabel,
      initialValue: initialValue,
      initialCategoryId: initialCategoryId,
      title: title,
    ),
  );
}

class _GradeEditorSheet extends StatefulWidget {
  const _GradeEditorSheet({
    required this.gradeScale,
    required this.gradeCategories,
    this.initialDate,
    this.initialSessionLabel,
    this.initialValue,
    this.initialCategoryId,
    this.title,
  });

  final List<String> gradeScale;
  final List<GradeCategory> gradeCategories;
  final DateTime? initialDate;
  final String? initialSessionLabel;
  final String? initialValue;
  final String? initialCategoryId;
  final String? title;

  @override
  State<_GradeEditorSheet> createState() => _GradeEditorSheetState();
}

class _GradeEditorSheetState extends State<_GradeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sessionController;
  late DateTime _selectedDate;
  late String? _selectedValue;
  late String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _sessionController = TextEditingController(
      text: widget.initialSessionLabel,
    );
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _selectedValue =
        widget.initialValue ??
        (widget.gradeScale.isEmpty ? null : widget.gradeScale.first);
    _selectedCategoryId =
        widget.initialCategoryId ??
        (widget.gradeCategories.isEmpty
            ? null
            : widget.gradeCategories.first.id);
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradeOptions = <String>[
      ...widget.gradeScale,
      if (widget.initialValue != null &&
          widget.initialValue!.trim().isNotEmpty &&
          !widget.gradeScale.contains(widget.initialValue!.trim()))
        widget.initialValue!.trim(),
    ];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'grades'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sessionController,
                decoration: InputDecoration(labelText: 'session_label'.tr()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                isExpanded: true,
                items: [
                  for (final category in widget.gradeCategories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.circle,
                                size: 14,
                                color: colorForCategory(category),
                              ),
                            ),
                            const WidgetSpan(child: SizedBox(width: 8)),
                            TextSpan(
                              text:
                                  '${category.name} (${formatNumber(category.weight)})',
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
                decoration: InputDecoration(labelText: 'grade_category'.tr()),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'grade_category'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              FormField<String>(
                initialValue: _selectedValue,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'grades'.tr()
                    : null,
                builder: (field) {
                  final hasGrade =
                      field.value != null && field.value!.trim().isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'grade'.tr(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _pickGrade(field, gradeOptions),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                hasGrade ? field.value! : 'no_grade'.tr(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 8),
                        Text(
                          field.errorText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('date'.tr()),
                subtitle: Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(_selectedDate),
                ),
                trailing: IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 16),
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
    if (selected == null) {
      return;
    }

    setState(() => _selectedDate = DateUtils.dateOnly(selected));
  }

  Future<void> _pickGrade(
    FormFieldState<String> field,
    List<String> gradeOptions,
  ) async {
    final result = await showGradePickerDialog(
      context: context,
      gradeScale: gradeOptions,
      initialValue: field.value,
    );
    if (result == null || !result.confirmed) {
      return;
    }

    setState(() => _selectedValue = result.value);
    field.didChange(result.value);
  }

  void _save() {
    if (!_formKey.currentState!.validate() ||
        _selectedValue == null ||
        _selectedCategoryId == null) {
      return;
    }

    GradeCategory? category;
    for (final item in widget.gradeCategories) {
      if (item.id == _selectedCategoryId) {
        category = item;
        break;
      }
    }
    if (category == null) {
      return;
    }

    Navigator.of(context).pop((
      categoryId: category.id,
      categoryName: category.name,
      date: _selectedDate,
      sessionLabel: _sessionController.text.trim(),
      value: _selectedValue!.trim(),
    ));
  }
}
