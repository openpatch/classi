import 'dart:convert';

import '../../core/database/app_database.dart';

List<String> normalizeNoteStudentIds(Iterable<String> studentIds) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final studentId in studentIds) {
    if (studentId.isNotEmpty && seen.add(studentId)) {
      normalized.add(studentId);
    }
  }
  return normalized;
}

String? encodeNoteStudentIds(Iterable<String> studentIds) {
  final normalized = normalizeNoteStudentIds(studentIds);
  if (normalized.isEmpty) {
    return null;
  }
  return jsonEncode(normalized);
}

List<String> decodeNoteStudentIds(
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
    final normalized = normalizeNoteStudentIds([
      for (final studentId in decoded) studentId.toString(),
    ]);
    return normalized.isEmpty ? fallback : normalized;
  } on FormatException {
    return fallback;
  }
}

List<String> noteStudentIds(TeacherNote note) {
  return decodeNoteStudentIds(
    note.studentIdsJson,
    fallbackStudentId: note.studentId,
  );
}
