import 'package:flutter/widgets.dart';

import '../../shared/widgets/daily_log_editor.dart';

typedef MaterialLogEditorResult = ({DateTime date, bool hadMaterial});

/// Asks for a material log entry — see [showDailyLogEditorSheet], which this
/// names for materials.
Future<MaterialLogEditorResult?> showMaterialLogEditorSheet({
  required BuildContext context,
  DateTime? initialDate,
  bool initialHadMaterial = true,
  String? title,
}) async {
  final result = await showDailyLogEditorSheet(
    context: context,
    titleKey: 'material',
    onLabelKey: 'had_material',
    offLabelKey: 'missing_material',
    initialDate: initialDate,
    initialValue: initialHadMaterial,
    title: title,
  );
  if (result == null) return null;
  return (date: result.date, hadMaterial: result.value);
}
