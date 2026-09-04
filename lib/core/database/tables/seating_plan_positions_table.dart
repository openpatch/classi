import 'package:drift/drift.dart';

import 'students_table.dart';
import 'seating_plans_table.dart';

/// The grid position (column, row) of a student within a seating plan.
///
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

  /// Zero-based column index within the seating grid.
  IntColumn get colIndex => integer().withDefault(const Constant(0))();

  /// Zero-based row index within the seating grid.
  IntColumn get rowIndex => integer().withDefault(const Constant(0))();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {seatingPlanId, studentId},
  ];
}
