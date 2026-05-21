import 'package:drift/drift.dart';

import 'groups_table.dart';

class SessionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  TextColumn get label => text().withLength(min: 0, max: 120)();

  TextColumn get description => text().nullable()();

  TextColumn get categoryId =>
      text().withDefault(const Constant('sonstige-mitarbeit'))();

  TextColumn get categoryName =>
      text().withDefault(const Constant('Sonstige Mitarbeit'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, date, categoryId},
  ];
}
