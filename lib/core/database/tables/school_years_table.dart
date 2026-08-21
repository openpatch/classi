import 'package:drift/drift.dart';

class SchoolYearsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get label => text().withLength(min: 1, max: 100)();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
