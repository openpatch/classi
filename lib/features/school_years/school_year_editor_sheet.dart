import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SchoolYearEditorResult {
  const SchoolYearEditorResult({
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  final String label;
  final DateTime startDate;
  final DateTime endDate;
}

Future<SchoolYearEditorResult?> showSchoolYearEditorSheet({
  required BuildContext context,
  String? initialLabel,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  bool isEdit = false,
}) {
  return showModalBottomSheet<SchoolYearEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _SchoolYearEditorSheet(
      initialLabel: initialLabel,
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      isEdit: isEdit,
    ),
  );
}

class _SchoolYearEditorSheet extends StatefulWidget {
  const _SchoolYearEditorSheet({
    this.initialLabel,
    this.initialStartDate,
    this.initialEndDate,
    this.isEdit = false,
  });

  final String? initialLabel;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool isEdit;

  @override
  State<_SchoolYearEditorSheet> createState() => _SchoolYearEditorSheetState();
}

class _SchoolYearEditorSheetState extends State<_SchoolYearEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
    _startDate = DateUtils.dateOnly(widget.initialStartDate ?? DateTime.now());
    _endDate = DateUtils.dateOnly(widget.initialEndDate ?? DateTime.now());
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                widget.isEdit
                    ? 'edit_school_year'.tr()
                    : 'add_school_year'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'school_year_label'.tr(),
                  hintText: '2025/26',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'school_year_label_required'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('start_date'.tr()),
                subtitle: Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(_startDate),
                ),
                trailing: IconButton(
                  onPressed: () => _pickDate(isStart: true),
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('end_date'.tr()),
                subtitle: Text(
                  MaterialLocalizations.of(context).formatMediumDate(_endDate),
                ),
                trailing: IconButton(
                  onPressed: () => _pickDate(isStart: false),
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              if (!_endDate.isAfter(_startDate))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'end_date_must_be_after_start_date'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
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

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = DateUtils.dateOnly(selected);
      } else {
        _endDate = DateUtils.dateOnly(selected);
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate() || !_endDate.isAfter(_startDate)) {
      return;
    }

    Navigator.of(context).pop(
      SchoolYearEditorResult(
        label: _labelController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }
}
