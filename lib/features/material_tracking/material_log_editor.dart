import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

typedef MaterialLogEditorResult = ({DateTime date, bool hadMaterial});

Future<MaterialLogEditorResult?> showMaterialLogEditorSheet({
  required BuildContext context,
  DateTime? initialDate,
  bool initialHadMaterial = true,
  String? title,
}) {
  return showModalBottomSheet<MaterialLogEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _MaterialLogEditorSheet(
      initialDate: initialDate,
      initialHadMaterial: initialHadMaterial,
      title: title,
    ),
  );
}

class _MaterialLogEditorSheet extends StatefulWidget {
  const _MaterialLogEditorSheet({
    this.initialDate,
    required this.initialHadMaterial,
    this.title,
  });

  final DateTime? initialDate;
  final bool initialHadMaterial;
  final String? title;

  @override
  State<_MaterialLogEditorSheet> createState() =>
      _MaterialLogEditorSheetState();
}

class _MaterialLogEditorSheetState extends State<_MaterialLogEditorSheet> {
  late DateTime _selectedDate;
  late bool _hadMaterial;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _hadMaterial = widget.initialHadMaterial;
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
            widget.title ?? 'material'.tr(),
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
            value: _hadMaterial,
            onChanged: (value) => setState(() => _hadMaterial = value),
            title: Text(
              _hadMaterial ? 'had_material'.tr() : 'missing_material'.tr(),
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
                ).pop((date: _selectedDate, hadMaterial: _hadMaterial)),
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
