import 'dart:convert';

/// Kinds of rows in an Erwartungshorizont.
enum ExpectationKind {
  regular,
  elective,

  /// A 0-point note pointing out an alternative solution. Never scored.
  alternative,

  /// Points outside any task (e.g. presentation). Always counted.
  additional;

  static ExpectationKind parse(String? raw) => switch (raw) {
    'elective' => ExpectationKind.elective,
    'alternative' => ExpectationKind.alternative,
    'additional' => ExpectationKind.additional,
    _ => ExpectationKind.regular,
  };

  bool get isScored => this != ExpectationKind.alternative;
}

/// One expectation, independent of the database row.
class ExamItem {
  const ExamItem({
    required this.matchKey,
    required this.kind,
    required this.maxPoints,
    this.id,
    this.task = '',
    this.part,
    this.groupKey,
    this.scoreKey,
    this.description = '',
    this.label,
    this.sortOrder = 0,
  });

  /// Database id, or `null` for an item that does not exist yet.
  final int? id;
  final String matchKey;
  final ExpectationKind kind;
  final String task;
  final String? part;

  /// Task group (regular) or elective group (elective).
  final String? groupKey;
  final String? scoreKey;
  final String description;
  final String? label;
  final double maxPoints;
  final int sortOrder;

  /// Key of the task this item belongs to; elective tasks and regular tasks
  /// with the same number are different tasks.
  String get taskKey => switch (kind) {
    ExpectationKind.additional => 'additional',
    ExpectationKind.elective => 'E:$task',
    _ => 'T:$task',
  };

  ExamItem copyWith({
    int? id,
    String? matchKey,
    ExpectationKind? kind,
    String? task,
    String? part,
    bool clearPart = false,
    String? groupKey,
    bool clearGroupKey = false,
    String? scoreKey,
    String? description,
    String? label,
    bool clearLabel = false,
    double? maxPoints,
    int? sortOrder,
  }) {
    return ExamItem(
      id: id ?? this.id,
      matchKey: matchKey ?? this.matchKey,
      kind: kind ?? this.kind,
      task: task ?? this.task,
      part: clearPart ? null : (part ?? this.part),
      groupKey: clearGroupKey ? null : (groupKey ?? this.groupKey),
      scoreKey: scoreKey ?? this.scoreKey,
      description: description ?? this.description,
      label: clearLabel ? null : (label ?? this.label),
      maxPoints: maxPoints ?? this.maxPoints,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TaskGroupInfo {
  const TaskGroupInfo({required this.id, required this.label});

  final String id;
  final String label;

  Map<String, Object?> toJson() => {'id': id, 'label': label};
}

class ElectiveGroupInfo {
  const ElectiveGroupInfo({
    required this.id,
    required this.label,
    required this.countedTasks,
  });

  final String id;
  final String label;

  /// How many of the group's tasks count (the best ones).
  final int countedTasks;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'countedTasks': countedTasks,
  };
}

/// Task groups, elective groups and titles of an exam.
class ExamStructureMeta {
  const ExamStructureMeta({
    this.taskGroups = const [],
    this.electiveGroups = const [],
    this.taskTitles = const {},
    this.electiveTaskTitles = const {},
  });

  final List<TaskGroupInfo> taskGroups;
  final List<ElectiveGroupInfo> electiveGroups;
  final Map<String, String> taskTitles;
  final Map<String, String> electiveTaskTitles;

  /// Counted tasks of an elective group; one when the group is not declared,
  /// as in assessio.
  int countedTasksFor(String? groupKey) {
    for (final group in electiveGroups) {
      if (group.id == (groupKey ?? '')) return group.countedTasks;
    }
    return 1;
  }

  String? electiveGroupLabel(String? groupKey) {
    for (final group in electiveGroups) {
      if (group.id == (groupKey ?? '')) return group.label;
    }
    return null;
  }

  String? taskGroupLabel(String? groupKey) {
    for (final group in taskGroups) {
      if (group.id == groupKey) return group.label;
    }
    return null;
  }

  ExamStructureMeta copyWith({
    List<TaskGroupInfo>? taskGroups,
    List<ElectiveGroupInfo>? electiveGroups,
    Map<String, String>? taskTitles,
    Map<String, String>? electiveTaskTitles,
  }) {
    return ExamStructureMeta(
      taskGroups: taskGroups ?? this.taskGroups,
      electiveGroups: electiveGroups ?? this.electiveGroups,
      taskTitles: taskTitles ?? this.taskTitles,
      electiveTaskTitles: electiveTaskTitles ?? this.electiveTaskTitles,
    );
  }

  Map<String, Object?> toJson() => {
    'taskGroups': [for (final g in taskGroups) g.toJson()],
    'electiveGroups': [for (final g in electiveGroups) g.toJson()],
    'taskTitles': taskTitles,
    'electiveTaskTitles': electiveTaskTitles,
  };

  String encode() => jsonEncode(toJson());

  static ExamStructureMeta decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const ExamStructureMeta();
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return const ExamStructureMeta();
      return ExamStructureMeta(
        taskGroups: [
          for (final g in (json['taskGroups'] as List? ?? const []))
            if (g is Map)
              TaskGroupInfo(
                id: '${g['id'] ?? ''}',
                label: '${g['label'] ?? g['id'] ?? ''}',
              ),
        ],
        electiveGroups: [
          for (final g in (json['electiveGroups'] as List? ?? const []))
            if (g is Map)
              ElectiveGroupInfo(
                id: '${g['id'] ?? ''}',
                label: '${g['label'] ?? g['id'] ?? ''}',
                countedTasks: (g['countedTasks'] as num?)?.toInt() ?? 1,
              ),
        ],
        taskTitles: _stringMap(json['taskTitles']),
        electiveTaskTitles: _stringMap(json['electiveTaskTitles']),
      );
    } on FormatException {
      return const ExamStructureMeta();
    }
  }

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    return {for (final e in raw.entries) '${e.key}': '${e.value}'};
  }

  bool sameAs(ExamStructureMeta other) => encode() == other.encode();
}

/// Display name of a task, e.g. "1", "Wahl 3".
String taskDisplayKey(ExamItem item) => item.task;
