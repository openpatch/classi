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

  /// Number of columns in the seating grid.
  IntColumn get columns => integer().withDefault(const Constant(6))();

  /// Whether this plan is the default for its group.
  ///
  /// At most one plan per group should have this set to `true`.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
