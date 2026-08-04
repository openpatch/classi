import 'dart:convert';

import '../../features/students/student_sorting.dart';

class GradeScaleEntry {
  const GradeScaleEntry({required this.label, required this.numericValue});

  final String label;
  final double numericValue;

  Map<String, Object> toJson() => {
    'label': label,
    'numericValue': numericValue,
  };
}

class GradeSystemTemplate {
  const GradeSystemTemplate({required this.name, required this.entries});

  final String name;
  final List<GradeScaleEntry> entries;
}

const defaultGradeScaleEntries = <GradeScaleEntry>[
  GradeScaleEntry(label: '1', numericValue: 1),
  GradeScaleEntry(label: '2', numericValue: 2),
  GradeScaleEntry(label: '3', numericValue: 3),
  GradeScaleEntry(label: '4', numericValue: 4),
  GradeScaleEntry(label: '5', numericValue: 5),
  GradeScaleEntry(label: '6', numericValue: 6),
];

const defaultExtendedGradeScaleEntries = <GradeScaleEntry>[
  GradeScaleEntry(label: '1+', numericValue: 0.7),
  GradeScaleEntry(label: '1', numericValue: 1.0),
  GradeScaleEntry(label: '1-', numericValue: 1.3),
  GradeScaleEntry(label: '2+', numericValue: 1.7),
  GradeScaleEntry(label: '2', numericValue: 2.0),
  GradeScaleEntry(label: '2-', numericValue: 2.3),
  GradeScaleEntry(label: '3+', numericValue: 2.7),
  GradeScaleEntry(label: '3', numericValue: 3.0),
  GradeScaleEntry(label: '3-', numericValue: 3.3),
  GradeScaleEntry(label: '4+', numericValue: 3.7),
  GradeScaleEntry(label: '4', numericValue: 4.0),
  GradeScaleEntry(label: '4-', numericValue: 4.3),
  GradeScaleEntry(label: '5+', numericValue: 4.7),
  GradeScaleEntry(label: '5', numericValue: 5.0),
  GradeScaleEntry(label: '5-', numericValue: 5.3),
  GradeScaleEntry(label: '6', numericValue: 6.0),
];

const defaultPointGradeScaleEntries = <GradeScaleEntry>[
  GradeScaleEntry(label: '15', numericValue: 15),
  GradeScaleEntry(label: '14', numericValue: 14),
  GradeScaleEntry(label: '13', numericValue: 13),
  GradeScaleEntry(label: '12', numericValue: 12),
  GradeScaleEntry(label: '11', numericValue: 11),
  GradeScaleEntry(label: '10', numericValue: 10),
  GradeScaleEntry(label: '9', numericValue: 9),
  GradeScaleEntry(label: '8', numericValue: 8),
  GradeScaleEntry(label: '7', numericValue: 7),
  GradeScaleEntry(label: '6', numericValue: 6),
  GradeScaleEntry(label: '5', numericValue: 5),
  GradeScaleEntry(label: '4', numericValue: 4),
  GradeScaleEntry(label: '3', numericValue: 3),
  GradeScaleEntry(label: '2', numericValue: 2),
  GradeScaleEntry(label: '1', numericValue: 1),
  GradeScaleEntry(label: '0', numericValue: 0),
];

const defaultGradeSystemTemplates = <GradeSystemTemplate>[
  GradeSystemTemplate(name: '1-6', entries: defaultGradeScaleEntries),
  GradeSystemTemplate(
    name: '1+/1/1-/.../6',
    entries: defaultExtendedGradeScaleEntries,
  ),
  GradeSystemTemplate(name: '15-0', entries: defaultPointGradeScaleEntries),
];

List<GradeScaleEntry> parseGradeScaleEntries(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! List) {
    return defaultGradeScaleEntries;
  }

  final labels = <String>[];
  final entries = <GradeScaleEntry>[];
  for (var index = 0; index < decoded.length; index++) {
    final entry = decoded[index];
    if (entry is Map) {
      final label = entry['label']?.toString().trim();
      final numericValue = entry['numericValue'];
      final parsedNumericValue = numericValue is num
          ? numericValue.toDouble()
          : double.tryParse(numericValue?.toString() ?? '');
      if (label == null || label.isEmpty || parsedNumericValue == null) {
        continue;
      }
      entries.add(
        GradeScaleEntry(label: label, numericValue: parsedNumericValue),
      );
      continue;
    }

    final label = entry.toString().trim();
    if (label.isNotEmpty) {
      labels.add(label);
    }
  }

  if (entries.isNotEmpty) {
    return entries;
  }

  if (labels.isEmpty) {
    return defaultGradeScaleEntries;
  }

  final matchingTemplate = matchingGradeSystemTemplateByLabels(labels);
  if (matchingTemplate != null) {
    return matchingTemplate.entries;
  }

  return [
    for (var index = 0; index < labels.length; index++)
      GradeScaleEntry(
        label: labels[index],
        numericValue: double.tryParse(labels[index]) ?? (index + 1).toDouble(),
      ),
  ];
}

List<String> parseGradeScale(String rawJson) {
  return [for (final entry in parseGradeScaleEntries(rawJson)) entry.label];
}

String encodeGradeScaleEntries(List<GradeScaleEntry> values) => jsonEncode([
  for (final entry in values)
    if (entry.label.trim().isNotEmpty)
      GradeScaleEntry(
        label: entry.label.trim(),
        numericValue: entry.numericValue,
      ).toJson(),
]);

String encodeGradeScale(List<String> values) => encodeGradeScaleEntries([
  for (final entry in values)
    if (entry.trim().isNotEmpty)
      GradeScaleEntry(
        label: entry.trim(),
        numericValue:
            double.tryParse(entry.trim()) ??
            (values.indexOf(entry) + 1).toDouble(),
      ),
]);

bool sameGradeScaleEntries(
  List<GradeScaleEntry> left,
  List<GradeScaleEntry> right,
) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index].label != right[index].label ||
        left[index].numericValue != right[index].numericValue) {
      return false;
    }
  }
  return true;
}

GradeSystemTemplate? matchingGradeSystemTemplate(
  List<GradeScaleEntry> entries,
) {
  for (final template in defaultGradeSystemTemplates) {
    if (sameGradeScaleEntries(entries, template.entries)) {
      return template;
    }
  }
  return null;
}

GradeSystemTemplate? matchingGradeSystemTemplateByLabels(List<String> labels) {
  for (final template in defaultGradeSystemTemplates) {
    if (_sameLabels(labels, template.entries)) {
      return template;
    }
  }
  return null;
}

double? gradeValueToNumberFromJson(String rawValue, String gradeScaleJson) {
  return gradeValueToNumber(rawValue, parseGradeScaleEntries(gradeScaleJson));
}

double? gradeValueToNumber(String rawValue, List<GradeScaleEntry> gradeScale) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  for (final entry in gradeScale) {
    if (entry.label == trimmed) {
      return entry.numericValue;
    }
  }

  return double.tryParse(trimmed);
}

String gradeLabelForNumericValue(
  double value,
  List<GradeScaleEntry> gradeScale,
) {
  if (gradeScale.isEmpty) {
    return formatNumber(value);
  }

  var closest = gradeScale.first;
  var smallestDifference = (value - closest.numericValue).abs();
  for (final entry in gradeScale.skip(1)) {
    final difference = (value - entry.numericValue).abs();
    if (difference < smallestDifference) {
      closest = entry;
      smallestDifference = difference;
    }
  }
  return closest.label;
}

bool gradeScaleLowerValuesAreBetter(List<GradeScaleEntry> gradeScale) {
  if (gradeScale.length < 2) {
    return false;
  }
  return gradeScale.first.numericValue < gradeScale.last.numericValue;
}

bool _sameLabels(List<String> labels, List<GradeScaleEntry> entries) {
  if (labels.length != entries.length) {
    return false;
  }
  for (var index = 0; index < labels.length; index++) {
    if (labels[index] != entries[index].label) {
      return false;
    }
  }
  return true;
}

/// The name shown for a student in place of [firstName]: [callName] (the
/// informal "Rufname" a teacher actually calls them by) when set, otherwise
/// [firstName] itself.
String effectiveFirstName({required String firstName, String? callName}) {
  final trimmedCallName = callName?.trim();
  return trimmedCallName == null || trimmedCallName.isEmpty
      ? firstName
      : trimmedCallName;
}

String studentDisplayName({
  required String firstName,
  required String lastName,
  String? callName,
  StudentSortField sortField = StudentSortField.lastName,
}) {
  final displayFirstName = effectiveFirstName(
    firstName: firstName,
    callName: callName,
  );
  return switch (sortField) {
    StudentSortField.firstName => '$displayFirstName $lastName',
    StudentSortField.lastName => '$lastName, $displayFirstName',
  };
}

String studentDisplayNameWithOrigin({
  required String firstName,
  required String lastName,
  String? callName,
  String? originNote,
  StudentSortField sortField = StudentSortField.lastName,
}) {
  final displayName = studentDisplayName(
    firstName: firstName,
    lastName: lastName,
    callName: callName,
    sortField: sortField,
  );
  final trimmedOriginNote = originNote?.trim();
  if (trimmedOriginNote == null || trimmedOriginNote.isEmpty) {
    return displayName;
  }
  return '$displayName ($trimmedOriginNote)';
}

bool isGeneratedStudentDisplayName({
  required String value,
  required String firstName,
  required String lastName,
  String? callName,
}) {
  final trimmedValue = value.trim();
  return trimmedValue ==
          studentDisplayName(
            firstName: firstName,
            lastName: lastName,
            callName: callName,
            sortField: StudentSortField.firstName,
          ) ||
      trimmedValue ==
          studentDisplayName(
            firstName: firstName,
            lastName: lastName,
            callName: callName,
            sortField: StudentSortField.lastName,
          );
}

String studentInitials({required String firstName, required String lastName}) {
  final first = firstName.isEmpty ? '?' : firstName.substring(0, 1);
  final last = lastName.isEmpty ? '?' : lastName.substring(0, 1);
  return '$first$last'.toUpperCase();
}

String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String formatShortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  return '$day.$month.$year';
}
