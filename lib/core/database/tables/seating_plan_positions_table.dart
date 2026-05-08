import 'package:drift/drift.dart';

import 'students_table.dart';
import 'seating_plans_table.dart';

/// The (x, y) position of a student within a seating plan.
///
/// Coordinates are canvas-relative, in logical pixels.
/// Each student appears at most once per plan.
@DataClassName('SeatingPlanPosition')
class SeatingPlanPositionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get seatingPlanId => integer().references(
    SeatingPlansTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get studentId => integer().references(
    StudentsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  RealColumn get x => real().withDefault(const Constant(0.0))();

  RealColumn get y => real().withDefault(const Constant(0.0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {seatingPlanId, studentId},
  ];
}
