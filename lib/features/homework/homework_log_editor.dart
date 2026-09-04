import 'package:flutter/widgets.dart';

import '../../shared/widgets/daily_log_editor.dart';

typedef HomeworkLogEditorResult = ({DateTime date, bool hadHomework});

/// Asks for a homework log entry — see [showDailyLogEditorSheet], which this
/// names for homework.
Future<HomeworkLogEditorResult?> showHomeworkLogEditorSheet({
  required BuildContext context,
  DateTime? initialDate,
  bool initialHadHomework = true,
  String? title,
}) async {
  final result = await showDailyLogEditorSheet(
    context: context,
    titleKey: 'homework',
    onLabelKey: 'had_homework',
    offLabelKey: 'missing_homework',
    initialDate: initialDate,
    initialValue: initialHadHomework,
    title: title,
  );
  if (result == null) return null;
  return (date: result.date, hadHomework: result.value);
}
