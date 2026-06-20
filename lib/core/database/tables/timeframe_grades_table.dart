import 'package:drift/drift.dart';

import 'students_table.dart';
import 'timeframes_table.dart';

class TimeframeGradesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get timeframeId =>
      integer().references(TimeframesTable, #id, onDelete: KeyAction.cascade)();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get grade => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {timeframeId, studentId},
  ];
}
