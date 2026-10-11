import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/utils/formatting.dart';

typedef GradeSystemEditorResult = ({
  String name,
  List<GradeScaleEntry> entries,
  int? gradesPerRow,
});

Future<GradeSystemEditorResult?> showGradeSystemEditorSheet({
  required BuildContext context,
  String? initialName,
  List<GradeScaleEntry>? initialEntries,
  int? initialGradesPerRow,
  String? title,
}) {
  return showModalBottomSheet<GradeSystemEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _GradeSystemEditorSheet(
      initialName: initialName,
      initialEntries: initialEntries,
      initialGradesPerRow: initialGradesPerRow,
      title: title,
    ),
  );
}

class _GradeSystemEditorSheet extends StatefulWidget {
  const _GradeSystemEditorSheet({
    this.initialName,
    this.initialEntries,
    this.initialGradesPerRow,
    this.title,
  });

  final String? initialName;
  final List<GradeScaleEntry>? initialEntries;
  final int? initialGradesPerRow;
  final String? title;

  @override
  State<_GradeSystemEditorSheet> createState() =>
      _GradeSystemEditorSheetState();
}

class _GradeSystemEditorSheetState extends State<_GradeSystemEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gradesPerRowController;
  late final List<_EditableScaleEntry> _entries;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _gradesPerRowController = TextEditingController(
      text: widget.initialGradesPerRow?.toString(),
    );
    _entries = [
      for (final entry in widget.initialEntries ?? defaultGradeScaleEntries)
        _EditableScaleEntry.fromEntry(entry),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradesPerRowController.dispose();
    for (final entry in _entries) {
      entry.dispose();
    }
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
                widget.title ?? 'grade_systems'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'grade_system_name'.tr(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'grade_system_name'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < _entries.length; index++) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _entries[index].labelController,
                        decoration: InputDecoration(
                          labelText: 'grade_label'.tr(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'grade_label'.tr()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _entries[index].numericValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'grade_numeric_value'.tr(),
                        ),
                        validator: (value) =>
                            double.tryParse((value ?? '').trim()) == null
                            ? 'grade_numeric_value'.tr()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _entries.length > 1
                          ? () => _removeEntry(index)
                          : null,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'delete'.tr(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add),
                label: Text('add_grade_value'.tr()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradesPerRowController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'grades_per_row'.tr(),
                  helperText: 'grades_per_row_hint'.tr(),
                ),
                validator: (value) {
                  final trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) {
                    return null;
                  }
                  final parsed = int.tryParse(trimmed);
                  return parsed == null || parsed < 1
                      ? 'grades_per_row'.tr()
                      : null;
                },
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _gradesPerRowController,
                  for (final entry in _entries) entry.labelController,
                ]),
                builder: (context, _) => _gradesPerRowPreview(),
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

  void _addEntry() {
    setState(() {
      _entries.add(_EditableScaleEntry.newEntry());
    });
  }

  Widget _gradesPerRowPreview() {
    final theme = Theme.of(context);
    final labels = [
      for (final entry in _entries)
        if (entry.labelController.text.trim().isNotEmpty)
          entry.labelController.text.trim(),
    ];
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    final perRow = int.tryParse(_gradesPerRowController.text.trim());
    if (perRow == null || perRow < 1) {
      return Text(
        'grades_per_row_automatic'.tr(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'layout_preview'.tr(),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        for (var start = 0; start < labels.length; start += perRow)
          Padding(
            padding: EdgeInsets.only(
              bottom: start + perRow < labels.length ? 8 : 0,
            ),
            child: Row(
              children: [
                for (
                  var index = start;
                  index < start + perRow && index < labels.length;
                  index++
                ) ...[
                  if (index > start) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        labels[index],
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _removeEntry(int index) {
    final entry = _entries.removeAt(index);
    entry.dispose();
    setState(() {});
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final gradesPerRowText = _gradesPerRowController.text.trim();
    final parsedGradesPerRow = gradesPerRowText.isEmpty
        ? null
        : int.tryParse(gradesPerRowText);

    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      entries: [
        for (final entry in _entries)
          GradeScaleEntry(
            label: entry.labelController.text.trim(),
            numericValue: double.parse(
              entry.numericValueController.text.trim(),
            ),
          ),
      ],
      gradesPerRow: parsedGradesPerRow != null && parsedGradesPerRow > 0
          ? parsedGradesPerRow
          : null,
    ));
  }
}

class _EditableScaleEntry {
  _EditableScaleEntry({
    required this.labelController,
    required this.numericValueController,
  });

  factory _EditableScaleEntry.fromEntry(GradeScaleEntry entry) {
    return _EditableScaleEntry(
      labelController: TextEditingController(text: entry.label),
      numericValueController: TextEditingController(
        text: formatNumber(entry.numericValue),
      ),
    );
  }

  factory _EditableScaleEntry.newEntry() {
    return _EditableScaleEntry(
      labelController: TextEditingController(),
      numericValueController: TextEditingController(),
    );
  }

  final TextEditingController labelController;
  final TextEditingController numericValueController;

  void dispose() {
    labelController.dispose();
    numericValueController.dispose();
  }
}
