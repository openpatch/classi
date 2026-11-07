import 'package:drift/drift.dart';

import 'exam_expectations_table.dart';
import 'exams_table.dart';
import 'students_table.dart';

/// Points one student reached for one expectation.
///
/// Identified by `(expectation_id, student_id)`; a missing row means "not
/// entered yet".
@DataClassName('ExamScore')
class ExamScoresTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get examId =>
      integer().references(ExamsTable, #id, onDelete: KeyAction.cascade)();

  IntColumn get expectationId => integer().references(
    ExamExpectationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  RealColumn get points => real()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {expectationId, studentId},
  ];
}
