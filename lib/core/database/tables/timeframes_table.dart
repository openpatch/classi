import 'package:drift/drift.dart';

import 'school_years_table.dart';

class TimeframesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get schoolYearId => integer().references(
    SchoolYearsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get label => text().withLength(min: 1, max: 100)();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
