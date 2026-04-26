import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'student_draft.dart';
import 'student_import_parser.dart';

Future<List<StudentDraft>?> showStudentBatchCreateSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<List<StudentDraft>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _StudentBatchCreateSheet(),
  );
}

class _StudentBatchCreateSheet extends StatefulWidget {
  const _StudentBatchCreateSheet();

  @override
  State<_StudentBatchCreateSheet> createState() =>
      _StudentBatchCreateSheetState();
}

class _StudentBatchCreateSheetState extends State<_StudentBatchCreateSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'batch_create_students'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('student_batch_hint'.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 8,
              maxLines: 16,
              decoration: InputDecoration(
                labelText: 'student_batch_input'.tr(),
                hintText: 'student_batch_example'.tr(),
                alignLabelWithHint: true,
              ),
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
    );
  }

  void _save() {
    try {
      final drafts = parseStudentBatchText(_controller.text);
      Navigator.of(context).pop(drafts);
    } on FormatException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.tr())));
    }
  }
}
