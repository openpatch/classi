import 'exam_structure.dart';
import 'grade_scheme.dart';

/// Points of one task for one student.
class TaskResult {
  const TaskResult({
    required this.taskKey,
    required this.points,
    required this.maxPoints,
    required this.counted,
  });

  final String taskKey;
  final double points;
  final double maxPoints;

  /// Whether the task counts towards the total. Elective tasks beyond the
  /// best `countedTasks` of their group do not.
  final bool counted;
}

/// One student's result in an exam.
class StudentExamResult {
  const StudentExamResult({
    required this.total,
    required this.maxPoints,
    required this.grade,
    required this.complete,
    required this.missing,
    required this.tasks,
  });

  final double total;
  final double maxPoints;

  /// Grade from the scheme for [total], also while incomplete (provisional).
  final String? grade;

  /// All required expectations have points.
  final bool complete;

  /// Number of expectations still without points that block completion.
  final int missing;
  final Map<String, TaskResult> tasks;

  double get percent => maxPoints <= 0 ? 0 : total / maxPoints * 100;

  bool get hasAnyPoints => tasks.values.any((t) => t.points > 0) || total > 0;
}

/// Grading rules of assessio, in one place:
///
/// - regular and additional expectations always count;
/// - per elective group, the best `countedTasks` tasks count (by the
///   student's points; for the maximum, by the tasks' maxima);
/// - alternative expectations are notes worth 0 points.
class ExamCalculator {
  ExamCalculator({
    required List<ExamItem> items,
    required this.meta,
    required this.scheme,
  }) : items = [
         for (final item in items)
           if (item.kind.isScored) item,
       ];

  final List<ExamItem> items;
  final ExamStructureMeta meta;
  final GradeScheme scheme;

  late final Map<String, List<ExamItem>> _byTask = _groupByTask();
  late final Map<String, List<String>> _electiveTasksByGroup =
      _groupElectiveTasks();
  late final double maxPoints = _computeMaxPoints();

  Map<String, List<ExamItem>> _groupByTask() {
    final result = <String, List<ExamItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.taskKey, () => []).add(item);
    }
    return result;
  }

  Map<String, List<String>> _groupElectiveTasks() {
    final result = <String, List<String>>{};
    for (final item in items) {
      if (item.kind != ExpectationKind.elective) continue;
      final tasks = result.putIfAbsent(item.groupKey ?? '', () => []);
      if (!tasks.contains(item.taskKey)) tasks.add(item.taskKey);
    }
    return result;
  }

  double _taskMax(String taskKey) =>
      (_byTask[taskKey] ?? const []).fold(0.0, (s, i) => s + i.maxPoints);

  double _computeMaxPoints() {
    var total = 0.0;
    for (final item in items) {
      if (item.kind != ExpectationKind.elective) total += item.maxPoints;
    }
    for (final entry in _electiveTasksByGroup.entries) {
      final maxima = [for (final t in entry.value) _taskMax(t)]
        ..sort((a, b) => b.compareTo(a));
      final counted = meta.countedTasksFor(entry.key);
      total += maxima.take(counted).fold(0.0, (s, v) => s + v);
    }
    return total;
  }

  /// [scores] maps expectation ids to points; absent means "not entered".
  StudentExamResult compute(Map<int, double> scores) {
    double scoreOf(ExamItem item) =>
        item.id == null ? 0 : (scores[item.id] ?? 0);
    bool scored(ExamItem item) =>
        item.id != null && scores.containsKey(item.id);

    final tasks = <String, TaskResult>{};
    var total = 0.0;
    var missing = 0;

    for (final entry in _byTask.entries) {
      final first = entry.value.first;
      if (first.kind == ExpectationKind.elective) continue;
      final points = entry.value.fold(0.0, (s, i) => s + scoreOf(i));
      missing += entry.value.where((i) => !scored(i)).length;
      total += points;
      tasks[entry.key] = TaskResult(
        taskKey: entry.key,
        points: points,
        maxPoints: _taskMax(entry.key),
        counted: true,
      );
    }

    for (final group in _electiveTasksByGroup.entries) {
      final counted = meta.countedTasksFor(group.key);
      final results = <TaskResult>[];
      var fullyScored = 0;
      var leastMissing = <int>[];
      for (final taskKey in group.value) {
        final taskItems = _byTask[taskKey]!;
        final points = taskItems.fold(0.0, (s, i) => s + scoreOf(i));
        final taskMissing = taskItems.where((i) => !scored(i)).length;
        if (taskMissing == 0) fullyScored++;
        leastMissing.add(taskMissing);
        results.add(
          TaskResult(
            taskKey: taskKey,
            points: points,
            maxPoints: _taskMax(taskKey),
            counted: false,
          ),
        );
      }
      final ranked = [...results]..sort((a, b) => b.points.compareTo(a.points));
      final countedKeys = ranked.take(counted).map((r) => r.taskKey).toSet();
      for (final r in results) {
        final isCounted = countedKeys.contains(r.taskKey);
        if (isCounted) total += r.points;
        tasks[r.taskKey] = TaskResult(
          taskKey: r.taskKey,
          points: r.points,
          maxPoints: r.maxPoints,
          counted: isCounted,
        );
      }
      // A student writes only the tasks they chose: the group is complete
      // once enough tasks are fully scored. Otherwise the cheapest way to get
      // there is what is still missing.
      final required = counted < group.value.length
          ? counted
          : group.value.length;
      if (fullyScored < required) {
        leastMissing.sort();
        missing += leastMissing
            .where((m) => m > 0)
            .take(required - fullyScored)
            .fold(0, (s, m) => s + m);
      }
    }

    return StudentExamResult(
      total: total,
      maxPoints: maxPoints,
      grade: scheme.gradeFor(total, maxPoints),
      complete: missing == 0,
      missing: missing,
      tasks: tasks,
    );
  }
}
