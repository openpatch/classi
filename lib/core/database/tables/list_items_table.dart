import 'package:drift/drift.dart';

import 'lists_table.dart';
import 'students_table.dart';

@DataClassName('ChecklistItem')
class ListItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get listId =>
      integer().references(ListsTable, #id, onDelete: KeyAction.cascade)();

  IntColumn get studentId => integer().nullable().references(
    StudentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get studentIdsJson => text().nullable()();

  TextColumn get label => text().withLength(min: 1, max: 150)();

  DateTimeColumn get checkedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
