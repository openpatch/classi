import 'dart:convert';

import '../../core/database/app_database.dart';

List<int> normalizeNoteStudentIds(Iterable<int> studentIds) {
  final normalized = <int>[];
  final seen = <int>{};
  for (final studentId in studentIds) {
    if (studentId > 0 && seen.add(studentId)) {
      normalized.add(studentId);
    }
  }
  return normalized;
}

String? encodeNoteStudentIds(Iterable<int> studentIds) {
  final normalized = normalizeNoteStudentIds(studentIds);
  if (normalized.isEmpty) {
    return null;
  }
  return jsonEncode(normalized);
}

List<int> decodeNoteStudentIds(
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
    final normalized = normalizeNoteStudentIds([
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

List<int> noteStudentIds(TeacherNote note) {
  return decodeNoteStudentIds(
    note.studentIdsJson,
    fallbackStudentId: note.studentId,
  );
}
