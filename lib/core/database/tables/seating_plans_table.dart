import 'package:drift/drift.dart';

import 'groups_table.dart';

/// A named seating plan belonging to a group.
///
/// A group can have multiple seating plans.
@DataClassName('SeatingPlan')
class SeatingPlansTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId => integer().references(
    GroupsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
