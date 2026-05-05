import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'groups_table.dart';

@DataClassName('Checklist')
class ListsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get groupId => text().nullable().references(
    GroupsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get archivedAt => dateTime().nullable()();
}
