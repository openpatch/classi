import '../data/exam_repository.dart';
import 'exam_structure.dart';

/// Share of the reachable points the students got, for one expectation,
/// task or label. `percent` is `null` when nobody has points there yet.
class AnalysisEntry<K> {
  const AnalysisEntry({
    required this.key,
    required this.points,
    required this.maxPoints,
  });

  final K key;
  final double points;
  final double maxPoints;

  double? get percent => maxPoints <= 0 ? null : points / maxPoints * 100;
}

/// Item analysis of one exam over the given students.
///
/// Only entered scores count: a student without points for an expectation
/// (e.g. an elective task they did not choose) neither raises nor lowers its
/// difficulty.
class ExamAnalysis {
  ExamAnalysis._(this.snapshot, this.studentIds);

  factory ExamAnalysis.of(ExamSnapshot snapshot, List<int> studentIds) =>
      ExamAnalysis._(snapshot, studentIds);

  final ExamSnapshot snapshot;
  final List<int> studentIds;

  List<ExamItem> get _scored => [
    for (final i in snapshot.items)
      if (i.kind.isScored && i.id != null && i.maxPoints > 0) i,
  ];

  AnalysisEntry<K> _aggregate<K>(
    K key,
    Iterable<ExamItem> items,
    Iterable<int> students,
  ) {
    var points = 0.0;
    var max = 0.0;
    for (final student in students) {
      final scores = snapshot.scoresOf(student);
      for (final item in items) {
        final value = scores[item.id];
        if (value == null) continue;
        points += value;
        max += item.maxPoints;
      }
    }
    return AnalysisEntry(key: key, points: points, maxPoints: max);
  }

  late final List<AnalysisEntry<ExamItem>> items = [
    for (final item in _scored) _aggregate(item, [item], studentIds),
  ];

  late final List<AnalysisEntry<String>> tasks = () {
    final byTask = <String, List<ExamItem>>{};
    for (final item in _scored) {
      byTask.putIfAbsent(item.taskKey, () => []).add(item);
    }
    return [
      for (final entry in byTask.entries)
        _aggregate(entry.key, entry.value, studentIds),
    ];
  }();

  /// Per label (e.g. "AFB II"), sorted by label.
  late final List<AnalysisEntry<String>> labels = () {
    final byLabel = <String, List<ExamItem>>{};
    for (final item in _scored) {
      final label = item.label?.trim();
      if (label == null || label.isEmpty) continue;
      byLabel.putIfAbsent(label, () => []).add(item);
    }
    final keys = byLabel.keys.toList()..sort();
    return [for (final k in keys) _aggregate(k, byLabel[k]!, studentIds)];
  }();

  double? studentTaskPercent(int studentId, String taskKey) {
    final items = _scored.where((i) => i.taskKey == taskKey);
    return _aggregate(taskKey, items, [studentId]).percent;
  }
}
