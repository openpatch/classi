import 'dart:convert';

import 'student_draft.dart';

List<StudentDraft> parseStudentBatchText(String source) {
  final drafts = <StudentDraft>[];
  for (final rawLine in const LineSplitter().convert(source)) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }

    final draft = _parseBatchLine(line);
    if (draft == null) {
      throw const FormatException('student_batch_invalid_line');
    }
    drafts.add(draft);
  }

  if (drafts.isEmpty) {
    throw const FormatException('student_batch_empty');
  }

  return drafts;
}

List<StudentDraft> parseWebUntisStudentText(String source) {
  final lines = const LineSplitter()
      .convert(source)
      .map((line) => line.replaceFirst(RegExp(r'^\uFEFF'), '').trimRight())
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);

  if (lines.length < 2) {
    throw const FormatException('webuntis_import_empty');
  }

  final delimiter = _inferDelimiter(lines.first);
  final headers = _splitLine(
    lines.first,
    delimiter,
  ).map(_normalizeHeader).toList(growable: false);

  final lastNameIndex = headers.indexOf('langname');
  final firstNameIndex = headers.indexOf('vorname');
  if (lastNameIndex == -1 || firstNameIndex == -1) {
    throw const FormatException('webuntis_missing_columns');
  }

  final drafts = <StudentDraft>[];
  for (final line in lines.skip(1)) {
    final cells = _splitLine(line, delimiter);
    final lastName = _cellAt(cells, lastNameIndex);
    final firstName = _cellAt(cells, firstNameIndex);
    if (firstName.isEmpty && lastName.isEmpty) {
      continue;
    }
    if (firstName.isEmpty || lastName.isEmpty) {
      throw const FormatException('webuntis_invalid_row');
    }

    drafts.add((
      firstName: firstName,
      lastName: lastName,
      originNote: null,
      avatarJson: null,
    ));
  }

  if (drafts.isEmpty) {
    throw const FormatException('webuntis_import_empty');
  }

  return drafts;
}

StudentDraft? _parseBatchLine(String line) {
  if (line.contains(',')) {
    final parts = line.split(',');
    if (parts.length >= 2) {
      final lastName = parts.first.trim();
      final firstName = parts.sublist(1).join(',').trim();
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        return (
          firstName: firstName,
          lastName: lastName,
          originNote: null,
          avatarJson: null,
        );
      }
    }
  }

  if (line.contains('\t')) {
    final parts = line
        .split('\t')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return (
        firstName: parts.first,
        lastName: parts.sublist(1).join(' '),
        originNote: null,
        avatarJson: null,
      );
    }
  }

  final parts = line
      .split(RegExp(r'\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length < 2) {
    return null;
  }

  return (
    firstName: parts.first,
    lastName: parts.sublist(1).join(' '),
    originNote: null,
    avatarJson: null,
  );
}

String _inferDelimiter(String headerLine) {
  if (headerLine.contains('\t')) {
    return '\t';
  }
  final semicolons = ';'.allMatches(headerLine).length;
  final commas = ','.allMatches(headerLine).length;
  return semicolons > commas ? ';' : ',';
}

List<String> _splitLine(String line, String delimiter) =>
    line.split(delimiter).map((cell) => cell.trim()).toList(growable: false);

String _normalizeHeader(String header) =>
    header.toLowerCase().replaceAll(RegExp(r'\s+'), '');

String _cellAt(List<String> cells, int index) =>
    index >= 0 && index < cells.length ? cells[index].trim() : '';
