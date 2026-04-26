import 'package:drift/drift.dart';

import 'groups_table.dart';

@DataClassName('Checklist')
class ListsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get archivedAt => dateTime().nullable()();
}
