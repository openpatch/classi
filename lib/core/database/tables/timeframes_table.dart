import 'package:drift/drift.dart';

import 'groups_table.dart';

class TimeframesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get label => text().withLength(min: 1, max: 100)();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime()();

  TextColumn get finalGrade => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
