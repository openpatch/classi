import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

typedef HomeworkLogEditorResult = ({DateTime date, bool hadHomework});

Future<HomeworkLogEditorResult?> showHomeworkLogEditorSheet({
  required BuildContext context,
  DateTime? initialDate,
  bool initialHadHomework = true,
  String? title,
}) {
  return showModalBottomSheet<HomeworkLogEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _HomeworkLogEditorSheet(
      initialDate: initialDate,
      initialHadHomework: initialHadHomework,
      title: title,
    ),
  );
}

class _HomeworkLogEditorSheet extends StatefulWidget {
  const _HomeworkLogEditorSheet({
    this.initialDate,
    required this.initialHadHomework,
    this.title,
  });

  final DateTime? initialDate;
  final bool initialHadHomework;
  final String? title;

  @override
  State<_HomeworkLogEditorSheet> createState() =>
      _HomeworkLogEditorSheetState();
}

class _HomeworkLogEditorSheetState extends State<_HomeworkLogEditorSheet> {
  late DateTime _selectedDate;
  late bool _hadHomework;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _hadHomework = widget.initialHadHomework;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? 'homework'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('date'.tr()),
            subtitle: Text(
              MaterialLocalizations.of(context).formatMediumDate(_selectedDate),
            ),
            trailing: IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _hadHomework,
            onChanged: (value) => setState(() => _hadHomework = value),
            title: Text(
              _hadHomework ? 'had_homework'.tr() : 'missing_homework'.tr(),
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
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop((date: _selectedDate, hadHomework: _hadHomework)),
                child: Text('save'.tr()),
              ),
            ],
          ),
        ],
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
}
