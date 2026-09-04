import 'package:drift/drift.dart';

import 'students_table.dart';
import 'timeframes_table.dart';

class TimeframeGradesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get timeframeId =>
      integer().references(TimeframesTable, #id, onDelete: KeyAction.cascade)();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get grade => text()();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {timeframeId, studentId},
  ];
}
