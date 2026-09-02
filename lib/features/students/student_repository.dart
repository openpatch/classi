import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/formatting.dart';
import 'student_draft.dart';
import 'student_sorting.dart';

class StudentRepository {
  StudentRepository(this._database);

  final AppDatabase _database;

  Stream<List<Student>> watchByGroup(
    int groupId, {
    StudentSortField sortField = StudentSortField.lastName,
  }) {
    final query = _database.select(_database.studentsTable)
      ..where((table) => table.groupId.equals(groupId));
    _applySort(query, sortField);
    return query.watch();
  }

  Stream<List<Student>> watchAllStudents({
    StudentSortField sortField = StudentSortField.lastName,
  }) {
    final query = _database.select(_database.studentsTable);
    _applySort(query, sortField);
    return query.watch();
  }

  Stream<Map<int, int>> watchGroupStudentCounts() {
    return _database
        .customSelect(
          '''
          SELECT
            group_id,
            COUNT(id) AS student_count
          FROM students_table
          GROUP BY group_id
          ''',
          readsFrom: {_database.studentsTable},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.read<int>('group_id'): row.read<int>('student_count'),
          },
        );
  }

  Stream<Student?> watchStudent(int id) {
    return (_database.select(
      _database.studentsTable,
    )..where((table) => table.id.equals(id))).watchSingleOrNull();
  }

  Future<int> addStudent({
    required int groupId,
    required String firstName,
    required String lastName,
    String? callName,
    String? originNote,
    String? avatarJson,
  }) {
    return _database
        .into(_database.studentsTable)
        .insert(
          StudentsTableCompanion.insert(
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            groupId: groupId,
            callName: Value(
              callName?.trim().isEmpty ?? true ? null : callName!.trim(),
            ),
            originNote: Value(
              originNote?.trim().isEmpty ?? true ? null : originNote!.trim(),
            ),
            avatarJson: Value(
              avatarJson?.trim().isEmpty ?? true ? null : avatarJson!.trim(),
            ),
          ),
        );
  }

  Future<void> addStudents({
    required int groupId,
    required List<StudentDraft> students,
  }) async {
    if (students.isEmpty) {
      return;
    }

    await _database.batch((batch) {
      batch.insertAll(_database.studentsTable, [
        for (final student in students)
          _companionForDraft(groupId: groupId, student: student),
      ]);
    });
  }

  /// Copies the students of [sourceGroupId] into [targetGroupId].
  ///
  /// A student the target already has — matched on first and last name — keeps
  /// their id and everything hanging off it, their grades and attendance
  /// included, and only takes over what the source has to add: a call name, an
  /// avatar, an origin note. Nothing already in the target is erased by a
  /// source that has nothing to put there, so copying twice is safe and is how
  /// an avatar drawn in one subject reaches the other.
  ///
  /// Returns how many students were added, how many were filled in, and the
  /// students the target has that the source does not — a class that lost
  /// somebody in one subject usually lost them in the other, but taking a
  /// student out deletes their grades, so that is left for the caller to ask
  /// about.
  Future<({int added, int updated, List<Student> notInSource})>
  copyStudentsFromGroup({
    required int sourceGroupId,
    required int targetGroupId,
  }) async {
    if (sourceGroupId == targetGroupId) {
      return (added: 0, updated: 0, notInSource: const <Student>[]);
    }

    return _database.transaction(() async {
      final source = await watchByGroup(sourceGroupId).first;
      final target = await watchByGroup(targetGroupId).first;
      final existing = {
        for (final student in target)
          studentMatchKey(
            firstName: student.firstName,
            lastName: student.lastName,
          ): student,
      };

      final sourceKeys = {
        for (final student in source)
          studentMatchKey(
            firstName: student.firstName,
            lastName: student.lastName,
          ),
      };

      var added = 0;
      var updated = 0;
      for (final student in source) {
        final match = existing[studentMatchKey(
          firstName: student.firstName,
          lastName: student.lastName,
        )];

        if (match == null) {
          await addStudent(
            groupId: targetGroupId,
            firstName: student.firstName,
            lastName: student.lastName,
            callName: student.callName,
            originNote: student.originNote,
            avatarJson: student.avatarJson,
          );
          added++;
          continue;
        }

        final callName = student.callName ?? match.callName;
        final originNote = student.originNote ?? match.originNote;
        final avatarJson = student.avatarJson ?? match.avatarJson;
        if (callName == match.callName &&
            originNote == match.originNote &&
            avatarJson == match.avatarJson) {
          continue;
        }

        await updateStudent(
          id: match.id,
          firstName: match.firstName,
          lastName: match.lastName,
          callName: callName,
          originNote: originNote,
          avatarJson: avatarJson,
        );
        updated++;
      }

      return (
        added: added,
        updated: updated,
        notInSource: [
          for (final student in target)
            if (!sourceKeys.contains(
              studentMatchKey(
                firstName: student.firstName,
                lastName: student.lastName,
              ),
            ))
              student,
        ],
      );
    });
  }

  Future<void> updateStudent({
    required int id,
    required String firstName,
    required String lastName,
    String? callName,
    String? originNote,
    String? avatarJson,
  }) {
    return (_database.update(
      _database.studentsTable,
    )..where((table) => table.id.equals(id))).write(
      StudentsTableCompanion(
        firstName: Value(firstName.trim()),
        lastName: Value(lastName.trim()),
        callName: Value(
          callName?.trim().isEmpty ?? true ? null : callName!.trim(),
        ),
        originNote: Value(
          originNote?.trim().isEmpty ?? true ? null : originNote!.trim(),
        ),
        avatarJson: Value(
          avatarJson?.trim().isEmpty ?? true ? null : avatarJson!.trim(),
        ),
      ),
    );
  }

  Future<void> deleteStudent(int id) {
    return (_database.delete(
      _database.studentsTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> updateAvatar({required int id, String? avatarJson}) {
    return (_database.update(_database.studentsTable)
          ..where((table) => table.id.equals(id)))
        .write(StudentsTableCompanion(avatarJson: Value(avatarJson)));
  }

  StudentsTableCompanion _companionForDraft({
    required int groupId,
    required StudentDraft student,
  }) {
    return StudentsTableCompanion.insert(
      firstName: student.firstName.trim(),
      lastName: student.lastName.trim(),
      groupId: groupId,
      callName: Value(
        student.callName?.trim().isEmpty ?? true
            ? null
            : student.callName!.trim(),
      ),
      originNote: Value(
        student.originNote?.trim().isEmpty ?? true
            ? null
            : student.originNote!.trim(),
      ),
      avatarJson: Value(
        student.avatarJson?.trim().isEmpty ?? true
            ? null
            : student.avatarJson!.trim(),
      ),
    );
  }

  void _applySort(
    SimpleSelectStatement<$StudentsTableTable, Student> query,
    StudentSortField sortField,
  ) {
    switch (sortField) {
      case StudentSortField.firstName:
        query.orderBy([
          (table) => OrderingTerm.asc(table.firstName),
          (table) => OrderingTerm.asc(table.lastName),
        ]);
        break;
      case StudentSortField.lastName:
        query.orderBy([
          (table) => OrderingTerm.asc(table.lastName),
          (table) => OrderingTerm.asc(table.firstName),
        ]);
        break;
    }
  }
}
