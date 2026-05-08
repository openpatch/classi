import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_ui.dart';

/// Shows a modal bottom sheet for creating or renaming a seating plan.
///
/// Returns the entered name, or `null` if the user cancelled.
Future<String?> showSeatingPlanForm({
  required BuildContext context,
  String? initialName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SeatingPlanFormSheet(initialName: initialName),
  );
}

class _SeatingPlanFormSheet extends StatefulWidget {
  const _SeatingPlanFormSheet({this.initialName});

  final String? initialName;

  @override
  State<_SeatingPlanFormSheet> createState() => _SeatingPlanFormSheetState();
}

class _SeatingPlanFormSheetState extends State<_SeatingPlanFormSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
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
          FilledButton(
            onPressed: _submit,
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }
}
