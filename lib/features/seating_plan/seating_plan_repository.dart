import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

/// Manages seating plans and student positions within those plans.
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

  Future<int> createPlan({required int groupId, required String name}) {
    return _database.into(_database.seatingPlansTable).insert(
      SeatingPlansTableCompanion.insert(groupId: groupId, name: name),
    );
  }

  Future<void> renamePlan(int id, String name) async {
    await (_database.update(_database.seatingPlansTable)
          ..where((t) => t.id.equals(id)))
        .write(SeatingPlansTableCompanion(name: Value(name)));
  }

  Future<void> deletePlan(int id) async {
    await (_database.delete(_database.seatingPlansTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Positions ──────────────────────────────────────────────────────────────

  /// Watches all student positions for a given plan.
  ///
  /// Returns a map from studentId → canvas offset.
  Stream<Map<int, Offset>> watchPositionsForPlan(int planId) {
    return (_database.select(_database.seatingPlanPositionsTable)
          ..where((t) => t.seatingPlanId.equals(planId)))
        .watch()
        .map(
          (rows) => {
            for (final row in rows) row.studentId: Offset(row.x, row.y),
          },
        );
  }

  /// Saves the position of a single student in a plan.
  ///
  /// Uses an INSERT OR REPLACE strategy via Drift's `insertOnConflictUpdate`.
  Future<void> upsertPosition({
    required int planId,
    required int studentId,
    required double x,
    required double y,
  }) {
    return _database
        .into(_database.seatingPlanPositionsTable)
        .insertOnConflictUpdate(
          SeatingPlanPositionsTableCompanion.insert(
            seatingPlanId: planId,
            studentId: studentId,
            x: Value(x),
            y: Value(y),
          ),
        );
  }

  /// Ensures every student in [students] has a position row for [planId].
  ///
  /// Students that already have a saved position are left untouched.
  /// New students are placed in a simple grid starting at (24, 24).
  Future<void> initializePositionsForPlan({
    required int planId,
    required List<Student> students,
  }) async {
    final existing = await (_database.select(
      _database.seatingPlanPositionsTable,
    )..where((t) => t.seatingPlanId.equals(planId))).get();
    final existingIds = {for (final p in existing) p.studentId};

    const chipW = 88.0;
    const chipH = 80.0;
    const cols = 6;
    const startX = 24.0;
    const startY = 24.0;

    var col = 0;
    var row = 0;

    for (final student in students) {
      if (existingIds.contains(student.id)) {
        continue;
      }
      await upsertPosition(
        planId: planId,
        studentId: student.id,
        x: startX + col * (chipW + 8),
        y: startY + row * (chipH + 8),
      );
      col++;
      if (col >= cols) {
        col = 0;
        row++;
      }
    }
  }
}
