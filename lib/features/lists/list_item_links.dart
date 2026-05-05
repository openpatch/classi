import 'dart:convert';

import '../../core/database/app_database.dart';

List<String> normalizeListItemStudentIds(Iterable<String> studentIds) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final studentId in studentIds) {
    if (studentId.isNotEmpty && seen.add(studentId)) {
      normalized.add(studentId);
    }
  }
  return normalized;
}

String? encodeListItemStudentIds(Iterable<String> studentIds) {
  final normalized = normalizeListItemStudentIds(studentIds);
  if (normalized.isEmpty) {
    return null;
  }
  return jsonEncode(normalized);
}

List<String> decodeListItemStudentIds(
  String? encodedStudentIds, {
  String? fallbackStudentId,
}) {
  final fallback = fallbackStudentId == null
      ? const <String>[]
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
      for (final studentId in decoded) studentId.toString(),
    ]);
    return normalized.isEmpty ? fallback : normalized;
  } on FormatException {
    return fallback;
  }
}

List<String> listItemStudentIds(ChecklistItem item) {
  return decodeListItemStudentIds(
    item.studentIdsJson,
    fallbackStudentId: item.studentId,
  );
}
