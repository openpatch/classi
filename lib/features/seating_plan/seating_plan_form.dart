import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_ui.dart';

/// The result of the seating plan form.
typedef SeatingPlanFormResult = ({String name, int columns});

/// Shows a modal bottom sheet for creating or editing a seating plan.
///
/// Returns `({name, columns})`, or `null` if the user cancelled.
Future<SeatingPlanFormResult?> showSeatingPlanForm({
  required BuildContext context,
  String? initialName,
  int initialColumns = 6,
}) {
  return showModalBottomSheet<SeatingPlanFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SeatingPlanFormSheet(
      initialName: initialName,
      initialColumns: initialColumns,
    ),
  );
}

class _SeatingPlanFormSheet extends StatefulWidget {
  const _SeatingPlanFormSheet({this.initialName, this.initialColumns = 6});

  final String? initialName;
  final int initialColumns;

  @override
  State<_SeatingPlanFormSheet> createState() => _SeatingPlanFormSheetState();
}

class _SeatingPlanFormSheetState extends State<_SeatingPlanFormSheet> {
  late final TextEditingController _controller;
  late int _columns;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _columns = widget.initialColumns.clamp(1, 12);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, columns: _columns));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.small,
        AppSpacing.xLarge,
        AppSpacing.xxLarge + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initialName == null
                ? 'add_seating_plan'.tr()
                : 'rename_seating_plan'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.large),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'seating_plan_name'.tr(),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.large),
          _ColumnsStepper(
            value: _columns,
            onChanged: (v) => setState(() => _columns = v),
          ),
          const SizedBox(height: AppSpacing.large),
          FilledButton(
            onPressed: _submit,
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }
}

class _ColumnsStepper extends StatelessWidget {
  const _ColumnsStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'grid_columns'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < 12 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
