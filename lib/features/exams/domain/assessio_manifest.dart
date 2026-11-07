import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'exam_structure.dart';

/// The newest `<assessio-manifest>` format this app understands.
const int supportedAssessioFormat = 1;

/// One entry of the Typst document's grade scale.
class TypstGradeLevel {
  const TypstGradeLevel({required this.grade, required this.minPercent});

  final String grade;
  final double minPercent;

  Map<String, Object?> toJson() => {'grade': grade, 'min': minPercent};
}

/// An exam as read from an assessio document.
class ImportedExam {
  const ImportedExam({
    required this.format,
    required this.lang,
    required this.items,
    required this.meta,
    required this.gradingSystem,
    required this.scale,
    required this.sha256,
    this.maxPoints,
    this.cutoffs = const [],
  });

  final int format;
  final String lang;
  final List<ExamItem> items;
  final ExamStructureMeta meta;
  final String gradingSystem;
  final List<TypstGradeLevel> scale;

  /// Maximum points as computed by assessio, for cross-checking.
  final double? maxPoints;

  /// Point cutoffs per Typst grade label as computed by assessio.
  final List<({String grade, double points})> cutoffs;

  /// Hash of the canonical manifest JSON; changes when the document's
  /// structure or scale changes.
  final String sha256;
}

class ManifestFormatException implements Exception {
  ManifestFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses the value of `query(<assessio-manifest>).first().value`.
ImportedExam parseAssessioManifest(String rawJson) {
  final Object? decoded;
  try {
    decoded = jsonDecode(rawJson);
  } on FormatException catch (error) {
    throw ManifestFormatException('Invalid manifest JSON: ${error.message}');
  }
  if (decoded is! Map) {
    throw ManifestFormatException('The manifest is not a JSON object.');
  }
  final format = (decoded['format'] as num?)?.toInt() ?? 0;
  if (format < 1 || format > supportedAssessioFormat) {
    throw ManifestFormatException(
      'Unsupported assessio manifest format $format.',
    );
  }

  final rawItems = <Map<Object?, Object?>>[
    for (final e in (decoded['expectations'] as List? ?? const []))
      if (e is Map) e,
  ];
  rawItems.sort((a, b) {
    final byOrder = _int(a['order']).compareTo(_int(b['order']));
    if (byOrder != 0) return byOrder;
    final byKind = _kindRank(a['kind']).compareTo(_kindRank(b['kind']));
    if (byKind != 0) return byKind;
    return _int(a['idx']).compareTo(_int(b['idx']));
  });

  final items = <ExamItem>[];
  final seenKeys = <String, int>{};
  var sort = 0;

  void add(ExamItem item) {
    final count = seenKeys.update(
      item.matchKey,
      (n) => n + 1,
      ifAbsent: () => 1,
    );
    final key = count == 1 ? item.matchKey : '${item.matchKey}#$count';
    items.add(item.copyWith(matchKey: key, sortOrder: sort++));
  }

  for (final e in rawItems) {
    final kind = ExpectationKind.parse(e['kind'] as String?);
    final task = '${e['task'] ?? ''}';
    final part = e['part'] as String?;
    final description = '${e['description'] ?? ''}'.trim();
    final id = e['id'] as String?;
    add(
      ExamItem(
        matchKey: deriveMatchKey(
          id: id,
          kind: kind,
          task: task,
          part: part,
          description: description,
        ),
        kind: kind,
        task: task,
        part: part,
        groupKey: e['group'] as String?,
        scoreKey: e['key'] as String?,
        description: description,
        label: e['label'] as String?,
        maxPoints: (e['points'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  for (final e in (decoded['additional'] as List? ?? const [])) {
    if (e is! Map) continue;
    final description = '${e['description'] ?? ''}'.trim();
    add(
      ExamItem(
        matchKey: deriveMatchKey(
          id: e['id'] as String?,
          kind: ExpectationKind.additional,
          task: '',
          part: null,
          description: description,
        ),
        kind: ExpectationKind.additional,
        scoreKey: (e['key'] as String?) ?? 'additional',
        description: description,
        label: e['label'] as String?,
        maxPoints: (e['points'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  final meta = ExamStructureMeta(
    taskGroups: [
      for (final g in (decoded['task_groups'] as List? ?? const []))
        if (g is Map) TaskGroupInfo(id: '${g['id']}', label: '${g['label']}'),
    ],
    electiveGroups: [
      for (final g in (decoded['elective_groups'] as List? ?? const []))
        if (g is Map)
          ElectiveGroupInfo(
            id: '${g['id']}',
            label: '${g['label']}',
            countedTasks: (g['counted_tasks'] as num?)?.toInt() ?? 1,
          ),
    ],
    taskTitles: _stringMap(decoded['task_titles']),
    electiveTaskTitles: _stringMap(decoded['elective_task_titles']),
  );

  final grading = decoded['grading'];
  final scale = <TypstGradeLevel>[
    if (grading is Map)
      for (final level in (grading['scale'] as List? ?? const []))
        if (level is Map && level['min'] is num)
          TypstGradeLevel(
            grade: '${level['grade']}',
            minPercent: (level['min'] as num).toDouble(),
          ),
  ];

  return ImportedExam(
    format: format,
    lang: '${decoded['lang'] ?? 'en'}',
    items: items,
    meta: meta,
    gradingSystem: grading is Map
        ? '${grading['grading_system'] ?? 'grades'}'
        : 'grades',
    scale: scale,
    maxPoints: (decoded['max_points'] as num?)?.toDouble(),
    cutoffs: [
      if (grading is Map)
        for (final c in (grading['cutoffs'] as List? ?? const []))
          if (c is Map && c['points'] is num)
            (grade: '${c['grade']}', points: (c['points'] as num).toDouble()),
    ],
    sha256: sha256.convert(utf8.encode(jsonEncode(decoded))).toString(),
  );
}

/// Identity of an expectation across edits of the document. An explicit
/// assessio `id:` wins; otherwise kind, task, part and the normalized text.
String deriveMatchKey({
  required String? id,
  required ExpectationKind kind,
  required String task,
  required String? part,
  required String description,
}) {
  if (id != null && id.trim().isNotEmpty) return 'id:${id.trim()}';
  final text = description.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return '${kind.name}|$task|${part ?? ''}|$text';
}

int _int(Object? value) => value is num ? value.toInt() : 0;

int _kindRank(Object? kind) => kind == 'elective' ? 1 : 0;

Map<String, String> _stringMap(Object? raw) {
  if (raw is! Map) return const {};
  return {for (final e in raw.entries) '${e.key}': '${e.value}'};
}
