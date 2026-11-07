import 'package:drift/drift.dart';

import 'exams_table.dart';

/// One gradable row of an exam's Erwartungshorizont.
@DataClassName('ExamExpectation')
class ExamExpectationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get examId =>
      integer().references(ExamsTable, #id, onDelete: KeyAction.cascade)();

  /// Identity across Typst re-imports: `id:<assessio id>` or a key derived
  /// from kind, task, part and description.
  TextColumn get matchKey => text()();

  /// `regular`, `elective`, `alternative` (0-point note) or `additional`.
  TextColumn get kind => text().withDefault(const Constant('regular'))();

  TextColumn get task => text().withDefault(const Constant(''))();

  TextColumn get part => text().nullable()();

  /// Task group (regular) or elective group (elective) id.
  TextColumn get groupKey => text().nullable()();

  /// assessio score key, e.g. `2a.3`; used for the rubric export.
  TextColumn get scoreKey => text().nullable()();

  TextColumn get description => text().withDefault(const Constant(''))();

  /// Category label such as `AFB II`.
  TextColumn get label => text().nullable()();

  RealColumn get maxPoints => real().withDefault(const Constant(0))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {examId, matchKey},
  ];
}
