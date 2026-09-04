import 'package:drift/drift.dart';

import 'students_table.dart';

class AttendanceLogsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  BoolColumn get isAbsent => boolean().withDefault(const Constant(true))();

  BoolColumn get isExcused => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
