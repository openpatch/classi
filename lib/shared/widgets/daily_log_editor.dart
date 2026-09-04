import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a [showDailyLogEditorSheet] returns: the date the teacher picked and
/// the yes/no they set for that day.
typedef DailyLogEditorResult = ({DateTime date, bool value});

/// A bottom sheet for the one shape every per-day yes/no log shares — pick a
/// date, flip a switch — used by the homework and material trackers.
///
/// [titleKey] names the sheet when the caller passes no [title]; [onLabelKey]
/// and [offLabelKey] label the switch in its two positions. All three are
/// translation keys, so the sheet stays out of the business of deciding what
/// the tracked thing is called.
Future<DailyLogEditorResult?> showDailyLogEditorSheet({
  required BuildContext context,
  required String titleKey,
  required String onLabelKey,
  required String offLabelKey,
  DateTime? initialDate,
  bool initialValue = true,
  String? title,
}) {
  return showModalBottomSheet<DailyLogEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _DailyLogEditorSheet(
      titleKey: titleKey,
      onLabelKey: onLabelKey,
      offLabelKey: offLabelKey,
      initialDate: initialDate,
      initialValue: initialValue,
      title: title,
    ),
  );
}

class _DailyLogEditorSheet extends StatefulWidget {
  const _DailyLogEditorSheet({
    required this.titleKey,
    required this.onLabelKey,
    required this.offLabelKey,
    required this.initialValue,
    this.initialDate,
    this.title,
  });

  final String titleKey;
  final String onLabelKey;
  final String offLabelKey;
  final DateTime? initialDate;
  final bool initialValue;
  final String? title;

  @override
  State<_DailyLogEditorSheet> createState() => _DailyLogEditorSheetState();
}

class _DailyLogEditorSheetState extends State<_DailyLogEditorSheet> {
  late DateTime _selectedDate;
  late bool _value;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _value = widget.initialValue;
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
            widget.title ?? widget.titleKey.tr(),
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
            value: _value,
            onChanged: (value) => setState(() => _value = value),
            title: Text(
              _value ? widget.onLabelKey.tr() : widget.offLabelKey.tr(),
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
                ).pop((date: _selectedDate, value: _value)),
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
