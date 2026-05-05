import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'students_table.dart';

class GradeEntriesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get studentId =>
      text().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  TextColumn get sessionLabel => text().withLength(min: 0, max: 120)();

  TextColumn get value => text().withLength(min: 1, max: 24)();

  TextColumn get categoryId =>
      text().withDefault(const Constant('sonstige-mitarbeit'))();

  TextColumn get categoryName =>
      text().withDefault(const Constant('Sonstige Mitarbeit'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
