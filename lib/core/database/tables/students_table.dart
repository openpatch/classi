import 'package:drift/drift.dart';

import 'groups_table.dart';

class StudentsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get firstName => text().withLength(min: 1, max: 100)();

  TextColumn get lastName => text().withLength(min: 1, max: 100)();

  /// Informal name a teacher actually calls the student by (German
  /// "Rufname"), shown instead of [firstName] wherever the surname is
  /// still displayed alongside it. `null` means "same as firstName".
  TextColumn get callName => text().nullable()();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get originNote => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get avatarJson => text().nullable()();

  IntColumn get seatIndex => integer().nullable()();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
