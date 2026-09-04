import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks for a short note about [studentName] and returns what was typed, or
/// `null` if the teacher backed out.
///
/// The dialog owns its [TextEditingController]: it is created and disposed
/// with the dialog's own state, so callers cannot leak one by forgetting.
Future<String?> showQuickNoteDialog({
  required BuildContext context,
  required String studentName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _QuickNoteDialog(studentName: studentName),
  );
}

class _QuickNoteDialog extends StatefulWidget {
  const _QuickNoteDialog({required this.studentName});

  final String studentName;

  @override
  State<_QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<_QuickNoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.studentName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'add_note'.tr(),
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text('save'.tr()),
        ),
      ],
    );
  }
}
