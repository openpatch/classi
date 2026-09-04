import 'package:drift/drift.dart';

import 'students_table.dart';

class GradeEntriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  TextColumn get sessionLabel => text().withLength(min: 0, max: 120)();

  TextColumn get value => text().withLength(min: 1, max: 24)();

  TextColumn get categoryId =>
      text().withDefault(const Constant('sonstige-mitarbeit'))();

  TextColumn get categoryName =>
      text().withDefault(const Constant('Sonstige Mitarbeit'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
