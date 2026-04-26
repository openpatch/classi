import 'package:drift/drift.dart';

import 'students_table.dart';

class MaterialLogsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  BoolColumn get hadMaterial => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
