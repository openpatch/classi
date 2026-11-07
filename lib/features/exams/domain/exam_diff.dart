import 'exam_calculator.dart';
import 'exam_structure.dart';
import 'grade_scheme.dart';

enum ItemChangeType { unchanged, changed, added, removed }

/// How one expectation differs between the app and the Typst document.
class ItemChange {
  const ItemChange({
    required this.type,
    this.before,
    this.after,
    this.uncertain = false,
  });

  final ItemChangeType type;

  /// The expectation as stored (with its database id).
  final ExamItem? before;

  /// The expectation as read from the document.
  final ExamItem? after;

  /// Paired by position only (same task and part, different text): may be a
  /// rewritten expectation or a different one.
  final bool uncertain;

  bool get pointsChanged =>
      before != null && after != null && before!.maxPoints != after!.maxPoints;

  bool get pointsLowered =>
      before != null && after != null && after!.maxPoints < before!.maxPoints;

  bool get textChanged =>
      before != null &&
      after != null &&
      (before!.description != after!.description ||
          before!.label != after!.label);

  bool get placementChanged =>
      before != null &&
      after != null &&
      (before!.task != after!.task ||
          before!.part != after!.part ||
          before!.groupKey != after!.groupKey ||
          before!.kind != after!.kind ||
          before!.scoreKey != after!.scoreKey);

  bool get orderChanged =>
      before != null && after != null && before!.sortOrder != after!.sortOrder;
}

class StructureDiff {
  const StructureDiff({
    required this.items,
    required this.metaChanged,
    required this.schemeChanged,
  });

  final List<ItemChange> items;
  final bool metaChanged;
  final bool schemeChanged;

  Iterable<ItemChange> get added =>
      items.where((c) => c.type == ItemChangeType.added);
  Iterable<ItemChange> get removed =>
      items.where((c) => c.type == ItemChangeType.removed);
  Iterable<ItemChange> get changed =>
      items.where((c) => c.type == ItemChangeType.changed);

  /// Changes a teacher should see; reordering alone is listed only when
  /// nothing else changed for that expectation.
  bool get hasChanges =>
      metaChanged ||
      schemeChanged ||
      items.any((c) => c.type != ItemChangeType.unchanged);
}

/// Compares the stored structure with the one read from the document.
///
/// Expectations are matched by `matchKey` (explicit assessio id, or kind +
/// task + part + text). Leftovers within the same kind, task and part are
/// paired in order and flagged as uncertain; everything else is added or
/// removed.
StructureDiff diffExamStructure({
  required List<ExamItem> before,
  required List<ExamItem> after,
  required ExamStructureMeta metaBefore,
  required ExamStructureMeta metaAfter,
  required GradeScheme schemeBefore,
  required GradeScheme schemeAfter,
}) {
  final beforeByKey = {for (final item in before) item.matchKey: item};
  final matchedBefore = <String>{};
  final changes = <ItemChange>[];
  final unmatchedAfter = <ExamItem>[];

  for (final item in after) {
    final old = beforeByKey[item.matchKey];
    if (old == null) {
      unmatchedAfter.add(item);
      continue;
    }
    matchedBefore.add(old.matchKey);
    changes.add(_change(old, item, uncertain: false));
  }

  final unmatchedBefore = [
    for (final item in before)
      if (!matchedBefore.contains(item.matchKey)) item,
  ];

  String slot(ExamItem i) => '${i.kind.name}|${i.task}|${i.part ?? ''}';
  final leftoverBySlot = <String, List<ExamItem>>{};
  for (final item in unmatchedBefore) {
    leftoverBySlot.putIfAbsent(slot(item), () => []).add(item);
  }
  final pairedBefore = <ExamItem>{};
  for (final item in unmatchedAfter) {
    final candidates = leftoverBySlot[slot(item)];
    if (candidates != null && candidates.isNotEmpty) {
      final old = candidates.removeAt(0);
      pairedBefore.add(old);
      changes.add(_change(old, item, uncertain: true));
    } else {
      changes.add(ItemChange(type: ItemChangeType.added, after: item));
    }
  }
  for (final item in unmatchedBefore) {
    if (!pairedBefore.contains(item)) {
      changes.add(ItemChange(type: ItemChangeType.removed, before: item));
    }
  }

  int position(ItemChange c) => (c.after ?? c.before)!.sortOrder;
  changes.sort((a, b) => position(a).compareTo(position(b)));

  return StructureDiff(
    items: changes,
    metaChanged: !metaBefore.sameAs(metaAfter),
    schemeChanged: !schemeBefore.sameAs(schemeAfter),
  );
}

ItemChange _change(ExamItem old, ExamItem item, {required bool uncertain}) {
  final next = ItemChange(
    type: ItemChangeType.changed,
    before: old,
    after: item,
    uncertain: uncertain,
  );
  final different =
      uncertain ||
      next.pointsChanged ||
      next.textChanged ||
      next.placementChanged;
  return ItemChange(
    type: different ? ItemChangeType.changed : ItemChangeType.unchanged,
    before: old,
    after: item,
    uncertain: uncertain,
  );
}

/// What applying an import does to the stored expectations.
class ImportPlan {
  ImportPlan(this.diff, {Set<String> splitUncertain = const {}})
    : _split = splitUncertain;

  final StructureDiff diff;

  /// `matchKey`s (of the document side) of uncertain pairs the teacher wants
  /// treated as remove + add instead of a rewritten expectation.
  final Set<String> _split;

  bool isSplit(ItemChange change) =>
      change.uncertain && _split.contains(change.after!.matchKey);

  /// Existing expectation ids that keep their scores, with their new shape.
  Map<int, ExamItem> get kept => {
    for (final c in diff.items)
      if (c.before != null && c.after != null && !isSplit(c))
        c.before!.id!: c.after!.copyWith(id: c.before!.id),
  };

  List<ExamItem> get inserted => [
    for (final c in diff.items)
      if (c.type == ItemChangeType.added || (c.after != null && isSplit(c)))
        c.after!,
  ];

  List<ExamItem> get deleted => [
    for (final c in diff.items)
      if (c.type == ItemChangeType.removed || (c.before != null && isSplit(c)))
        c.before!,
  ];

  /// The structure after applying the plan; new items have no id yet.
  List<ExamItem> get resultingItems =>
      [...kept.values, ...inserted]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

/// A student whose result an import or scheme change would alter.
class GradeChange {
  const GradeChange({
    required this.studentId,
    required this.before,
    required this.after,
    required this.clampedItems,
    required this.removedScores,
  });

  final int studentId;
  final StudentExamResult before;
  final StudentExamResult after;

  /// Expectations whose points were above the new maximum.
  final int clampedItems;

  /// Scores that are deleted with removed expectations.
  final int removedScores;

  bool get gradeChanged => before.grade != after.grade;
  bool get totalChanged => (before.total - after.total).abs() > 1e-9;
}

/// Scores carried over to a new structure: deleted expectations drop their
/// scores, lowered maxima clamp them.
Map<int, double> carryOverScores(Map<int, double> scores, ImportPlan plan) {
  final kept = plan.kept;
  return {
    for (final entry in scores.entries)
      if (kept.containsKey(entry.key))
        entry.key: entry.value > kept[entry.key]!.maxPoints
            ? kept[entry.key]!.maxPoints
            : entry.value,
  };
}

/// Per student, the result before and after a structural change.
///
/// [scoresByStudent] maps student ids to their scores (expectation id ->
/// points); [plan] may be `null` for scheme-only changes.
List<GradeChange> previewGradeChanges({
  required Map<int, Map<int, double>> scoresByStudent,
  required ExamCalculator before,
  required ExamCalculator after,
  ImportPlan? plan,
}) {
  final deletedIds = {
    for (final i in plan?.deleted ?? const <ExamItem>[]) i.id,
  };
  final kept = plan?.kept ?? const <int, ExamItem>{};
  return [
    for (final entry in scoresByStudent.entries)
      () {
        final carried = plan == null
            ? entry.value
            : carryOverScores(entry.value, plan);
        return GradeChange(
          studentId: entry.key,
          before: before.compute(entry.value),
          after: after.compute(carried),
          clampedItems: entry.value.entries
              .where(
                (s) =>
                    kept.containsKey(s.key) && s.value > kept[s.key]!.maxPoints,
              )
              .length,
          removedScores: entry.value.keys.where(deletedIds.contains).length,
        );
      }(),
  ];
}
