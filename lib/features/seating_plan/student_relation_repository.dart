import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

/// Manages the seating rules that say which students belong together and
/// which have to be kept apart.
class StudentRelationRepository {
  StudentRelationRepository(this._database);

  final AppDatabase _database;

  /// Watches every rule that mentions a student of [groupId].
  ///
  /// Rules always join two students of the same group, so matching on the
  /// first of the pair is enough.
  Stream<List<StudentRelation>> watchRelationsForGroup(int groupId) {
    final relations = _database.studentRelationsTable;
    final students = _database.studentsTable;

    final query =
        _database.select(relations).join([
            innerJoin(students, students.id.equalsExp(relations.studentAId)),
          ])
          ..where(students.groupId.equals(groupId))
          ..orderBy([OrderingTerm.asc(relations.createdAt)]);

    return query.map((row) => row.readTable(relations)).watch();
  }

  /// Creates or replaces the rule between two students.
  ///
  /// The pair is normalized before writing, so calling this with the students
  /// swapped updates the same rule instead of adding a mirrored one. Throws an
  /// [ArgumentError] if both ids are the same student.
  Future<void> upsertRelation({
    required int studentAId,
    required int studentBId,
    required bool isPositive,
    String? comment,
  }) {
    if (studentAId == studentBId) {
      throw ArgumentError.value(
        studentBId,
        'studentBId',
        'A student cannot have a seating rule with themselves',
      );
    }

    final lowerId = studentAId < studentBId ? studentAId : studentBId;
    final higherId = studentAId < studentBId ? studentBId : studentAId;
    final trimmedComment = comment?.trim();
    final storedComment = trimmedComment == null || trimmedComment.isEmpty
        ? null
        : trimmedComment;

    return _database
        .into(_database.studentRelationsTable)
        .insert(
          StudentRelationsTableCompanion.insert(
            studentAId: lowerId,
            studentBId: higherId,
            isPositive: Value(isPositive),
            comment: Value(storedComment),
          ),
          onConflict: DoUpdate(
            (_) => StudentRelationsTableCompanion(
              isPositive: Value(isPositive),
              comment: Value(storedComment),
            ),
            target: [
              _database.studentRelationsTable.studentAId,
              _database.studentRelationsTable.studentBId,
            ],
          ),
        );
  }

  Future<void> deleteRelation(int id) {
    return (_database.delete(
      _database.studentRelationsTable,
    )..where((t) => t.id.equals(id))).go();
  }
}
