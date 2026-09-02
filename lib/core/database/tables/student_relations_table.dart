import 'package:drift/drift.dart';

import 'students_table.dart';

/// A seating rule between two students of the same group.
///
/// Says whether the pair should sit next to each other or be kept apart, with
/// an optional comment recording the reason. The pair is stored normalized —
/// [studentAId] always holds the lower id — so a rule exists at most once no
/// matter which student it was created from.
@DataClassName('StudentRelation')
class StudentRelationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  @ReferenceName('relationsAsStudentA')
  IntColumn get studentAId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  @ReferenceName('relationsAsStudentB')
  IntColumn get studentBId =>
      integer().references(StudentsTable, #id, onDelete: KeyAction.cascade)();

  /// `true` when the two should sit together, `false` when they should not.
  BoolColumn get isPositive => boolean().withDefault(const Constant(true))();

  /// Why the rule exists, e.g. "talks too much with him".
  TextColumn get comment => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {studentAId, studentBId},
  ];
}
