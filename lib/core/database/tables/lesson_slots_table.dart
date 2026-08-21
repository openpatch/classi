import 'package:drift/drift.dart';

import 'groups_table.dart';

/// One recurring slot in a group's weekly timetable, e.g. "Monday, periods
/// 1–2". Lessons planned from the schedule inherit the slot's periods and
/// grade category, so a teacher only has to confirm the suggested date.
class LessonSlotsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  /// ISO weekday, [DateTime.monday] (1) through [DateTime.sunday] (7).
  IntColumn get weekday => integer()();

  /// First school period of the slot, 1-based.
  IntColumn get periodStart => integer()();

  /// Last school period of the slot, inclusive. Equals [periodStart] for a
  /// slot that is a single period long.
  IntColumn get periodEnd => integer()();

  /// Grade category that lessons planned from this slot default to.
  TextColumn get categoryId =>
      text().withDefault(const Constant('sonstige-mitarbeit'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, weekday, periodStart},
  ];
}
