import 'package:drift/drift.dart';

import 'exams_table.dart';
import 'students_table.dart';

/// A student's status in one exam. Students without a row count as present.
@DataClassName('ExamParticipant')
class ExamParticipantsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get examId =>
      integer().references(ExamsTable, #id, onDelete: KeyAction.cascade)();

  IntColumn get studentId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  /// `present`, `absent` or `excused`. Absent and excused students get no
  /// grade.
  TextColumn get status => text().withDefault(const Constant('present'))();

  /// Replaces the computed grade, e.g. after an attempt to cheat.
  TextColumn get gradeOverride => text().nullable()();

  TextColumn get overrideReason => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {examId, studentId},
  ];
}
