import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

/// Manages seating plans and student grid positions within those plans.
class SeatingPlanRepository {
  SeatingPlanRepository(this._database);

  final AppDatabase _database;

  // ── Plans ──────────────────────────────────────────────────────────────────

  Stream<List<SeatingPlan>> watchPlansForGroup(int groupId) {
    return (_database.select(_database.seatingPlansTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<int> createPlan({
    required int groupId,
    required String name,
    int columns = 6,
  }) {
    return _database.into(_database.seatingPlansTable).insert(
      SeatingPlansTableCompanion.insert(
        groupId: groupId,
        name: name,
        columns: Value(columns),
      ),
    );
  }

  Future<void> updatePlan(int id, {required String name, required int columns}) {
    return (_database.update(_database.seatingPlansTable)
          ..where((t) => t.id.equals(id)))
        .write(
          SeatingPlansTableCompanion(
            name: Value(name),
            columns: Value(columns),
          ),
        );
  }

  Future<void> deletePlan(int id) {
    return (_database.delete(_database.seatingPlansTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Positions ──────────────────────────────────────────────────────────────

  /// Watches all student positions for a given plan.
  ///
  /// Returns a map from studentId → (col, row) grid position.
  Stream<Map<int, ({int col, int row})>> watchPositionsForPlan(int planId) {
    return (_database.select(_database.seatingPlanPositionsTable)
          ..where((t) => t.seatingPlanId.equals(planId)))
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.studentId: (col: row.colIndex, row: row.rowIndex),
          },
        );
  }

  /// Saves the grid position of a single student in a plan.
  Future<void> upsertPosition({
    required int planId,
    required int studentId,
    required int col,
    required int row,
  }) {
    return _database
        .into(_database.seatingPlanPositionsTable)
        .insertOnConflictUpdate(
          SeatingPlanPositionsTableCompanion.insert(
            seatingPlanId: planId,
            studentId: studentId,
            colIndex: Value(col),
            rowIndex: Value(row),
          ),
        );
  }

  /// Ensures every student in [students] has a position row for [planId].
  ///
  /// Existing positions are preserved. New students are placed left-to-right,
  /// top-to-bottom based on the plan's [columns] setting.
  Future<void> initializePositionsForPlan({
    required int planId,
    required List<Student> students,
    int columns = 6,
  }) async {
    final existing = await (_database.select(
      _database.seatingPlanPositionsTable,
    )..where((t) => t.seatingPlanId.equals(planId))).get();
    final existingIds = {for (final p in existing) p.studentId};

    var col = 0;
    var row = 0;

    for (final student in students) {
      if (existingIds.contains(student.id)) continue;
      await upsertPosition(
        planId: planId,
        studentId: student.id,
        col: col,
        row: row,
      );
      col++;
      if (col >= columns) {
        col = 0;
        row++;
      }
    }
  }
}
