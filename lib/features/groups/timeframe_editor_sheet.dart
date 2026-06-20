import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/utils/formatting.dart';
import 'timeframe_repository.dart';

class TimeframeEditorResult {
  const TimeframeEditorResult({
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  final String label;
  final DateTime startDate;
  final DateTime endDate;
}

Future<TimeframeEditorResult?> showTimeframeEditorSheet({
  required BuildContext context,
  required int groupId,
  required TimeframeRepository timeframeRepository,
  String? initialLabel,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  int? timeframeId,
}) {
  return showModalBottomSheet<TimeframeEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _TimeframeEditorSheet(
      groupId: groupId,
      timeframeRepository: timeframeRepository,
      initialLabel: initialLabel,
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      timeframeId: timeframeId,
    ),
  );
}

class _TimeframeEditorSheet extends StatefulWidget {
  const _TimeframeEditorSheet({
    required this.groupId,
    required this.timeframeRepository,
    this.initialLabel,
    this.initialStartDate,
    this.initialEndDate,
    this.timeframeId,
  });

  final int groupId;
  final TimeframeRepository timeframeRepository;
  final String? initialLabel;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? timeframeId;

  @override
  State<_TimeframeEditorSheet> createState() => _TimeframeEditorSheetState();
}

class _TimeframeEditorSheetState extends State<_TimeframeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.initialLabel ?? '',
    );
    _startDate = DateUtils.dateOnly(
      widget.initialStartDate ?? DateTime.now(),
    );
    _endDate = DateUtils.dateOnly(
      widget.initialEndDate ?? DateTime.now().add(const Duration(days: 30)),
    );
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
                widget.timeframeId == null ? 'add_timeframe'.tr() : 'edit_timeframe'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(labelText: 'timeframe_label'.tr()),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a label'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('start_date'.tr()),
                subtitle: Text(
                  MaterialLocalizations.of(context).formatMediumDate(_startDate),
                ),
                trailing: IconButton(
                  onPressed: _pickStartDate,
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
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              if (_endDate.isBefore(_startDate))
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
                  FilledButton(
                    onPressed: _save,
                    child: Text('save'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }

    setState(() => _startDate = DateUtils.dateOnly(selected));
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }

    setState(() => _endDate = DateUtils.dateOnly(selected));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      return;
    }

    final overlaps = await widget.timeframeRepository.getOverlappingTimeframes(
      groupId: widget.groupId,
      startDate: _startDate,
      endDate: _endDate,
      excludeId: widget.timeframeId,
    );

    if (overlaps.isNotEmpty && mounted) {
      final proceed = await _showOverlapWarning(context, overlaps);
      if (!proceed) {
        return;
      }
    }

    if (mounted) {
      Navigator.of(context).pop(
        TimeframeEditorResult(
          label: _labelController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
        ),
      );
    }
  }

  Future<bool> _showOverlapWarning(
    BuildContext context,
    List<Timeframe> overlaps,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('overlapping_timeframes'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('this_timeframe_overlaps_with'.tr()),
                const SizedBox(height: 12),
                ...overlaps.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '• ${t.label}: ${formatShortDate(t.startDate)} - ${formatShortDate(t.endDate)}',
                      ),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('save_anyway'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }
}
