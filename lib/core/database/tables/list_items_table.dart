import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'lists_table.dart';
import 'students_table.dart';

@DataClassName('ChecklistItem')
class ListItemsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get listId =>
      text().references(ListsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get studentId => text().nullable().references(
    StudentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get studentIdsJson => text().nullable()();

  TextColumn get label => text().withLength(min: 1, max: 150)();

  DateTimeColumn get checkedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
