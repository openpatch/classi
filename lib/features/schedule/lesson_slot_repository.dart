import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import 'lesson_schedule.dart';

class LessonSlotRepository {
  LessonSlotRepository(this._database);

  final AppDatabase _database;

  /// Watches a group's weekly timetable, ordered the way a timetable reads.
  Stream<List<LessonSlot>> watchSlots(int groupId) {
    return (_database.select(_database.lessonSlotsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.weekday),
            (t) => OrderingTerm.asc(t.periodStart),
          ]))
        .watch();
  }

  Future<List<LessonSlot>> slots(int groupId) {
    return (_database.select(_database.lessonSlotsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.weekday),
            (t) => OrderingTerm.asc(t.periodStart),
          ]))
        .get();
  }

  /// Watches every group's timetable at once, keyed by group id, for screens
  /// that show several groups side by side.
  Stream<Map<int, List<LessonSlot>>> watchSlotsByGroup() {
    return (_database.select(_database.lessonSlotsTable)..orderBy([
          (t) => OrderingTerm.asc(t.weekday),
          (t) => OrderingTerm.asc(t.periodStart),
        ]))
        .watch()
        .map((slots) {
          final byGroup = <int, List<LessonSlot>>{};
          for (final slot in slots) {
            byGroup.putIfAbsent(slot.groupId, () => []).add(slot);
          }
          return byGroup;
        });
  }

  /// Replaces a group's whole timetable with [drafts].
  ///
  /// The editor hands back the timetable as a whole rather than a list of
  /// edits, so writing it is a delete-then-insert inside one transaction.
  Future<void> replaceSlots({
    required int groupId,
    required List<LessonSlotDraft> drafts,
  }) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.lessonSlotsTable,
      )..where((t) => t.groupId.equals(groupId))).go();

      // The unique key covers (group, weekday, periodStart), so two drafts
      // that collide would abort the transaction. The editor prevents that,
      // but an inferred pattern is cheaper to de-duplicate than to trust.
      final seen = <(int, int)>{};
      for (final draft in sortedSlots(drafts)) {
        if (!seen.add((draft.weekday, draft.periodStart))) continue;
        await _database
            .into(_database.lessonSlotsTable)
            .insert(
              LessonSlotsTableCompanion.insert(
                groupId: groupId,
                weekday: draft.weekday,
                periodStart: draft.periodStart,
                periodEnd: draft.periodEnd,
                categoryId: Value(draft.categoryId),
              ),
            );
      }
    });
  }

  Future<void> deleteSlotsForGroup(int groupId) {
    return (_database.delete(
      _database.lessonSlotsTable,
    )..where((t) => t.groupId.equals(groupId))).go();
  }
}
