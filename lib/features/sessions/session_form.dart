import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/utils/grade_categories.dart';

typedef SessionFormResult = ({
  DateTime date,
  String label,
  String? description,
  String categoryId,
  String categoryName,
});

/// Opens the session create/edit bottom sheet.
///
/// Returns [SessionFormResult] on save, or null if the user dismissed.
Future<SessionFormResult?> showSessionFormSheet({
  required BuildContext context,
  required List<GradeCategory> gradeCategories,
  DateTime? initialDate,
  String? initialLabel,
  String? initialDescription,
  String? initialCategoryId,
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
    this.title,
  });

  final List<GradeCategory> gradeCategories;
  final DateTime? initialDate;
  final String? initialLabel;
  final String? initialDescription;
  final String? initialCategoryId;
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
              if (widget.gradeCategories.isNotEmpty)
                DropdownButtonFormField<String>(
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
    ));
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
