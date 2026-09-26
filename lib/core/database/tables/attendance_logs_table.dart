import 'package:drift/drift.dart';

import 'students_table.dart';

class AttendanceLogsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  /// First school period of the lesson this entry belongs to, or 0 for an
  /// entry that covers the whole day. Keeps two lessons of one group on the
  /// same day apart, the way WebUntis keeps its class register per lesson.
  IntColumn get periodStart => integer().withDefault(const Constant(0))();

  BoolColumn get isAbsent => boolean().withDefault(const Constant(true))();

  BoolColumn get isExcused => boolean().withDefault(const Constant(false))();

  /// The student came late but attended. Only meaningful on a present row
  /// ([isAbsent] false): late counts as present everywhere attendance is
  /// counted.
  BoolColumn get isLate => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
