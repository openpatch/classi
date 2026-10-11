import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

typedef GradePickerResult = ({bool confirmed, String? value});

Future<GradePickerResult?> showGradePickerDialog({
  required BuildContext context,
  required List<String> gradeScale,
  int? gradesPerRow,
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
              child: _gradeButtons(
                gradeScale,
                gradesPerRow,
                selectedValue,
                (grade) => Navigator.of(
                  context,
                ).pop((confirmed: true, value: grade)),
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

Widget _gradeButtons(
  List<String> gradeScale,
  int? gradesPerRow,
  String? selectedValue,
  void Function(String) onSelected,
) {
  if (gradesPerRow == null || gradesPerRow < 1) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final grade in gradeScale)
          SizedBox(
            width: 84,
            child: _gradeButton(grade, selectedValue, onSelected),
          ),
      ],
    );
  }

  final rows = <Widget>[];
  for (var start = 0; start < gradeScale.length; start += gradesPerRow) {
    rows.add(
      Padding(
        padding: EdgeInsets.only(
          bottom: start + gradesPerRow < gradeScale.length ? 8 : 0,
        ),
        child: Row(
          children: [
            for (
              var index = start;
              index < start + gradesPerRow && index < gradeScale.length;
              index++
            ) ...[
              if (index > start) const SizedBox(width: 8),
              Expanded(
                child: _gradeButton(
                  gradeScale[index],
                  selectedValue,
                  onSelected,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  return Column(mainAxisSize: MainAxisSize.min, children: rows);
}

Widget _gradeButton(
  String grade,
  String? selectedValue,
  void Function(String) onSelected,
) {
  return Builder(
    builder: (context) {
      final isSelected = selectedValue == grade;
      return FilledButton.tonal(
        onPressed: () => onSelected(grade),
        style: FilledButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : null,
        ),
        child: Text(grade),
      );
    },
  );
}
