import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

typedef GradePickerResult = ({bool confirmed, String? value});

Future<GradePickerResult?> showGradePickerDialog({
  required BuildContext context,
  required List<String> gradeScale,
  String? initialValue,
}) {
  return showDialog<GradePickerResult>(
    context: context,
    builder: (context) {
      var selectedValue = initialValue;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            scrollable: true,
            title: Text('grade_picker'.tr()),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final grade in gradeScale)
                    SizedBox(
                      width: 84,
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop((confirmed: true, value: grade)),
                        style: FilledButton.styleFrom(
                          backgroundColor: selectedValue == grade
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          foregroundColor: selectedValue == grade
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                        child: Text(grade),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop((confirmed: false, value: initialValue)),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop((confirmed: true, value: null)),
                child: Text('reset'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop((confirmed: true, value: selectedValue)),
                child: Text('ok'.tr()),
              ),
            ],
          );
        },
      );
    },
  );
}
