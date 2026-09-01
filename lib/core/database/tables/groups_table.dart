import 'package:drift/drift.dart';

import 'school_years_table.dart';

class GroupsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  TextColumn get colorHex => text().withDefault(const Constant('#FF1E88E5'))();

  TextColumn get gradeScaleJson =>
      text().withDefault(const Constant('["1","2","3","4","5","6"]'))();

  TextColumn get gradeCategoriesJson => text().withDefault(
    const Constant(
      '[{"id":"sonstige-mitarbeit","name":"Sonstige Mitarbeit","weight":1.0,"color":"#FF1E88E5"},{"id":"klassenarbeit","name":"Klassenarbeit","weight":3.0,"color":"#FF8E24AA"},{"id":"praesentation","name":"Präsentation","weight":2.0,"color":"#FF00897B"}]',
    ),
  )();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  IntColumn get schoolYearId => integer().nullable().references(
    SchoolYearsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The id of the WebUntis class ("Klasse") this group was imported from.
  ///
  /// Kept so a later student or attendance sync knows which class register to
  /// read without asking the teacher to pick it again. `null` for groups that
  /// were created by hand.
  IntColumn get webuntisKlasseId => integer().nullable()();
}
