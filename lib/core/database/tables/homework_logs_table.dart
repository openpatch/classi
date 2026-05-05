import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'students_table.dart';

class HomeworkLogsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get studentId =>
      text().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  BoolColumn get hadHomework => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
