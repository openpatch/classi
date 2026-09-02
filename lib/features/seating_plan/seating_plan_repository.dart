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
    return _database
        .into(_database.seatingPlansTable)
        .insert(
          SeatingPlansTableCompanion.insert(
            groupId: groupId,
            name: name,
            columns: Value(columns),
          ),
        );
  }

  Future<void> updatePlan(
    int id, {
    required String name,
    required int columns,
  }) {
    return (_database.update(
      _database.seatingPlansTable,
    )..where((t) => t.id.equals(id))).write(
      SeatingPlansTableCompanion(name: Value(name), columns: Value(columns)),
    );
  }

  /// Marks [planId] as the default for [groupId] and clears any other default.
  Future<void> setDefaultPlan(int groupId, int planId) {
    return _database.transaction(() async {
      await (_database.update(_database.seatingPlansTable)
            ..where((t) => t.groupId.equals(groupId)))
          .write(const SeatingPlansTableCompanion(isDefault: Value(false)));
      await (_database.update(_database.seatingPlansTable)
            ..where((t) => t.id.equals(planId)))
          .write(const SeatingPlansTableCompanion(isDefault: Value(true)));
    });
  }

  /// Returns the default plan for [groupId], falling back to the first plan.
  ///
  /// Returns `null` if the group has no seating plans yet.
  Future<SeatingPlan?> getDefaultOrFirstPlan(int groupId) async {
    final plans = await watchPlansForGroup(groupId).first;
    if (plans.isEmpty) return null;
    return plans.where((p) => p.isDefault).firstOrNull ?? plans.first;
  }

  Future<void> deletePlan(int id) {
    return (_database.delete(
      _database.seatingPlansTable,
    )..where((t) => t.id.equals(id))).go();
  }

  // ── Positions ──────────────────────────────────────────────────────────────

  /// Watches all student positions for a given plan.
  ///
  /// Returns a map from studentId → (col, row) grid position.
  Stream<Map<int, ({int col, int row})>> watchPositionsForPlan(int planId) {
    return (_database.select(
      _database.seatingPlanPositionsTable,
    )..where((t) => t.seatingPlanId.equals(planId))).watch().map(
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
        .insert(
          SeatingPlanPositionsTableCompanion.insert(
            seatingPlanId: planId,
            studentId: studentId,
            colIndex: Value(col),
            rowIndex: Value(row),
          ),
          onConflict: DoUpdate(
            (_) => SeatingPlanPositionsTableCompanion(
              colIndex: Value(col),
              rowIndex: Value(row),
            ),
            target: [
              _database.seatingPlanPositionsTable.seatingPlanId,
              _database.seatingPlanPositionsTable.studentId,
            ],
          ),
        );
  }

  /// Moves [studentId] to `[col, row]` within [planId].
  ///
  /// If another student already occupies the target cell, both students swap
  /// positions.
  Future<void> moveStudent({
    required int planId,
    required int studentId,
    required int col,
    required int row,
  }) {
    return _database.transaction(() async {
      final source =
          await (_database.select(_database.seatingPlanPositionsTable)..where(
                (t) =>
                    t.seatingPlanId.equals(planId) &
                    t.studentId.equals(studentId),
              ))
              .getSingleOrNull();

      if (source == null) {
        await upsertPosition(
          planId: planId,
          studentId: studentId,
          col: col,
          row: row,
        );
        return;
      }

      if (source.colIndex == col && source.rowIndex == row) return;

      // Reading every occupant rather than a single one: libraries written
      // before [initializePositionsForPlan] respected occupancy can still hold
      // two students in one cell, and a `getSingleOrNull` would throw there,
      // leaving that cell permanently unusable.
      final targets =
          await (_database.select(_database.seatingPlanPositionsTable)..where(
                (t) =>
                    t.seatingPlanId.equals(planId) &
                    t.colIndex.equals(col) &
                    t.rowIndex.equals(row),
              ))
              .get();

      for (final target in targets) {
        if (target.studentId == studentId) continue;
        await (_database.update(
          _database.seatingPlanPositionsTable,
        )..where((t) => t.id.equals(target.id))).write(
          SeatingPlanPositionsTableCompanion(
            colIndex: Value(source.colIndex),
            rowIndex: Value(source.rowIndex),
          ),
        );
      }

      await (_database.update(
        _database.seatingPlanPositionsTable,
      )..where((t) => t.id.equals(source.id))).write(
        SeatingPlanPositionsTableCompanion(
          colIndex: Value(col),
          rowIndex: Value(row),
        ),
      );
    });
  }

  /// Ensures every student in [students] sits on their own cell of [planId].
  ///
  /// Existing positions are preserved. Students without one are placed in the
  /// first free cell, scanning left-to-right and top-to-bottom over the plan's
  /// [columns] setting, so a student who joins the group later lands in a gap
  /// or below the class instead of on top of whoever sits at the top left.
  ///
  /// Any students found sharing a cell — written by an earlier version that
  /// placed new students without looking — are moved apart as well. A shared
  /// cell hides one of the two on the grid and makes every move into it fail.
  Future<void> initializePositionsForPlan({
    required int planId,
    required List<Student> students,
    int columns = 6,
  }) async {
    final existing = await (_database.select(
      _database.seatingPlanPositionsTable,
    )..where((t) => t.seatingPlanId.equals(planId))).get();

    final effectiveColumns = columns < 1 ? 1 : columns;
    final occupied = <(int, int)>{};
    final stacked = <SeatingPlanPosition>[];
    for (final position in existing) {
      if (!occupied.add((position.colIndex, position.rowIndex))) {
        stacked.add(position);
      }
    }

    var col = 0;
    var row = 0;
    void advance() {
      col++;
      if (col >= effectiveColumns) {
        col = 0;
        row++;
      }
    }

    ({int col, int row}) takeFreeCell() {
      while (occupied.contains((col, row))) {
        advance();
      }
      final cell = (col: col, row: row);
      occupied.add((col, row));
      advance();
      return cell;
    }

    for (final position in stacked) {
      final cell = takeFreeCell();
      await upsertPosition(
        planId: planId,
        studentId: position.studentId,
        col: cell.col,
        row: cell.row,
      );
    }

    final existingIds = {for (final p in existing) p.studentId};
    for (final student in students) {
      if (existingIds.contains(student.id)) continue;
      final cell = takeFreeCell();
      await upsertPosition(
        planId: planId,
        studentId: student.id,
        col: cell.col,
        row: cell.row,
      );
    }
  }
}
