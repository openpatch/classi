import 'package:drift/drift.dart';

import 'groups_table.dart';

@DataClassName('Checklist')
class ListsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId => integer().nullable().references(
    GroupsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// When the list was last worked on: an item added, ticked off, renamed or
  /// removed. `null` for lists nobody has touched since the column existed,
  /// which sort as if they were last used when they were made.
  DateTimeColumn get touchedAt => dateTime().nullable()();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
