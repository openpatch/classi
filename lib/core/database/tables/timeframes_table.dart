import 'package:drift/drift.dart';

import 'school_years_table.dart';

class TimeframesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get schoolYearId => integer().references(
    SchoolYearsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get label => text().withLength(min: 1, max: 100)();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
