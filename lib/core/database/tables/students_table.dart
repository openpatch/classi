import 'package:drift/drift.dart';

import 'groups_table.dart';

class StudentsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get firstName => text().withLength(min: 1, max: 100)();

  TextColumn get lastName => text().withLength(min: 1, max: 100)();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get originNote => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get avatarJson => text().nullable()();

  IntColumn get seatIndex => integer().nullable()();
}
