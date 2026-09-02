import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/formatting.dart';

/// Manages the seating rules that say which students belong together and
/// which have to be kept apart.
class StudentRelationRepository {
  StudentRelationRepository(this._database);

  final AppDatabase _database;

  /// Watches every rule that mentions a student of [groupId].
  ///
  /// A rule counts for the group when either of its students belongs to it,
  /// not just the one that happened to be stored first.
  Stream<List<StudentRelation>> watchRelationsForGroup(int groupId) {
    final relations = _database.studentRelationsTable;
    final students = _database.studentsTable;

    final query =
        _database.select(relations).join([
            innerJoin(
              students,
              students.id.equalsExp(relations.studentAId) |
                  students.id.equalsExp(relations.studentBId),
              useColumns: false,
            ),
          ])
          ..where(students.groupId.equals(groupId))
          // Both students are normally in the group, which matches the rule
          // once per side; fold those back into a single row.
          ..groupBy([relations.id])
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

  /// Copies the rules of [sourceGroupId] over to [targetGroupId].
  ///
  /// A rule is about two people, so it holds in whichever subject a teacher
  /// sees them: the same class in a second group should not need the same
  /// "keep these two apart" typed in again. The pair is matched by name, the
  /// way students are copied between groups, and a rule naming somebody the
  /// target group does not have is skipped.
  ///
  /// Re-running this updates the rules already there instead of doubling them.
  /// Returns how many rules were written.
  Future<int> copyRelationsBetweenGroups({
    required int sourceGroupId,
    required int targetGroupId,
  }) async {
    if (sourceGroupId == targetGroupId) return 0;

    return _database.transaction(() async {
      Future<List<Student>> studentsOf(int groupId) {
        return (_database.select(
          _database.studentsTable,
        )..where((t) => t.groupId.equals(groupId))).get();
      }

      final sourceStudents = await studentsOf(sourceGroupId);
      final targetStudents = await studentsOf(targetGroupId);
      final nameBySourceId = {
        for (final student in sourceStudents)
          student.id: studentMatchKey(
            firstName: student.firstName,
            lastName: student.lastName,
          ),
      };
      final targetByName = {
        for (final student in targetStudents)
          studentMatchKey(
            firstName: student.firstName,
            lastName: student.lastName,
          ): student.id,
      };

      final relations = await watchRelationsForGroup(sourceGroupId).first;
      var copied = 0;
      for (final relation in relations) {
        final a = targetByName[nameBySourceId[relation.studentAId]];
        final b = targetByName[nameBySourceId[relation.studentBId]];
        if (a == null || b == null || a == b) continue;

        await upsertRelation(
          studentAId: a,
          studentBId: b,
          isPositive: relation.isPositive,
          comment: relation.comment,
        );
        copied++;
      }
      return copied;
    });
  }

  Future<void> deleteRelation(int id) {
    return (_database.delete(
      _database.studentRelationsTable,
    )..where((t) => t.id.equals(id))).go();
  }
}
