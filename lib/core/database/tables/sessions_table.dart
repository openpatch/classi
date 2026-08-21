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

  /// First school period of the lesson, 1-based, or 0 when the lesson is not
  /// tied to a period. Lessons planned from a group's weekly schedule carry
  /// the periods of the slot they came from.
  IntColumn get periodStart => integer().withDefault(const Constant(0))();

  /// Last school period of the lesson, inclusive. Equals [periodStart] for a
  /// single-period lesson, 0 when [periodStart] is 0.
  IntColumn get periodEnd => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// A group can hold the same lesson twice on one day as long as the two sit
  /// in different periods, so the period is part of what identifies a lesson.
  /// [periodEnd] is left out: two lessons starting in the same period are the
  /// same lesson, however far they run.
  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, date, categoryId, periodStart},
  ];
}
