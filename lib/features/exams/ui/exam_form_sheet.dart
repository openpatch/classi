import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/utils/grade_categories.dart';

typedef ExamFormResult = ({
  String title,
  DateTime date,
  GradeCategory category,
  bool fromTypst,
});

/// Title, date and grade category of an exam. With [offerTypst] the sheet
/// also lets the teacher start from a Typst document.
Future<ExamFormResult?> showExamFormSheet({
  required BuildContext context,
  required List<GradeCategory> categories,
  String? initialTitle,
  DateTime? initialDate,
  String? initialCategoryId,
  bool offerTypst = false,
  bool editing = false,
}) {
  return showModalBottomSheet<ExamFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ExamFormSheet(
      categories: categories,
      initialTitle: initialTitle,
      initialDate: initialDate,
      initialCategoryId: initialCategoryId,
      offerTypst: offerTypst,
      editing: editing,
    ),
  );
}

class _ExamFormSheet extends StatefulWidget {
  const _ExamFormSheet({
    required this.categories,
    required this.offerTypst,
    required this.editing,
    this.initialTitle,
    this.initialDate,
    this.initialCategoryId,
  });

  final List<GradeCategory> categories;
  final String? initialTitle;
  final DateTime? initialDate;
  final String? initialCategoryId;
  final bool offerTypst;
  final bool editing;

  @override
  State<_ExamFormSheet> createState() => _ExamFormSheetState();
}

class _ExamFormSheetState extends State<_ExamFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late DateTime _date;
  late GradeCategory? _category;
  bool _fromTypst = false;

  List<GradeCategory> get _gradable => gradableCategories(widget.categories);

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _date = widget.initialDate ?? DateTime.now();
    final gradable = _gradable;
    GradeCategory? pick(String id) {
      for (final c in gradable) {
        if (c.id == id) return c;
      }
      return null;
    }

    _category =
        pick(widget.initialCategoryId ?? '') ??
        pick('klassenarbeit') ??
        (gradable.isEmpty ? null : gradable.first);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd(
      context.locale.toLanguageTag(),
    ).format(_date);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.editing ? 'exam_edit'.tr() : 'exam_add'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: !widget.editing,
                maxLength: 200,
                decoration: InputDecoration(labelText: 'exam_title'.tr()),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'exam_title'.tr() : null,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(dateLabel),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GradeCategory>(
                initialValue: _category,
                decoration: InputDecoration(labelText: 'grade_category'.tr()),
                items: [
                  for (final category in _gradable)
                    DropdownMenuItem(
                      value: category,
                      child: Text(
                        categoryPathName(category, widget.categories),
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'grade_category'.tr() : null,
              ),
              if (widget.offerTypst) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _fromTypst,
                  onChanged: (value) => setState(() => _fromTypst = value),
                  title: Text('exam_from_typst'.tr()),
                  subtitle: Text('exam_from_typst_hint'.tr()),
                ),
              ],
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      title: _title.text.trim(),
      date: _date,
      category: _category!,
      fromTypst: _fromTypst,
    ));
  }
}
