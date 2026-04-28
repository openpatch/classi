import 'dart:convert';

import '../../core/database/app_database.dart';

List<int> normalizeListItemStudentIds(Iterable<int> studentIds) {
  final normalized = <int>[];
  final seen = <int>{};
  for (final studentId in studentIds) {
    if (studentId > 0 && seen.add(studentId)) {
      normalized.add(studentId);
    }
  }
  return normalized;
}

String? encodeListItemStudentIds(Iterable<int> studentIds) {
  final normalized = normalizeListItemStudentIds(studentIds);
  if (normalized.isEmpty) {
    return null;
  }
  return jsonEncode(normalized);
}

List<int> decodeListItemStudentIds(
  String? encodedStudentIds, {
  int? fallbackStudentId,
}) {
  final fallback = fallbackStudentId == null
      ? const <int>[]
      : [fallbackStudentId];
  if (encodedStudentIds == null || encodedStudentIds.trim().isEmpty) {
    return fallback;
  }

  try {
    final decoded = jsonDecode(encodedStudentIds);
    if (decoded is! List) {
      return fallback;
    }
    final normalized = normalizeListItemStudentIds([
      for (final studentId in decoded)
        if (studentId is int)
          studentId
        else
          int.tryParse(studentId.toString()) ?? -1,
    ]);
    return normalized.isEmpty ? fallback : normalized;
  } on FormatException {
    return fallback;
  }
}

List<int> listItemStudentIds(ChecklistItem item) {
  return decodeListItemStudentIds(
    item.studentIdsJson,
    fallbackStudentId: item.studentId,
  );
}
