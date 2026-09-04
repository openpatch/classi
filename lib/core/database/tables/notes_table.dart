import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'students_table.dart';

@DataClassName('TeacherNote')
class NotesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get body => text().withLength(min: 1, max: 5000)();

  IntColumn get groupId => integer().nullable().references(
    GroupsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get studentId => integer().nullable().references(
    StudentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get studentIdsJson => text().nullable()();

  BoolColumn get isTodo => boolean().withDefault(const Constant(false))();

  BoolColumn get todoDone => boolean().withDefault(const Constant(false))();

  DateTimeColumn get todoDoneAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
