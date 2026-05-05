import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import 'student_draft.dart';
import 'student_sorting.dart';

class StudentRepository {
  StudentRepository(this._database);

  final AppDatabase _database;

  Stream<List<Student>> watchByGroup(
    String groupId, {
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

  Stream<Map<String, int>> watchGroupStudentCounts() {
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
              row.read<String>('group_id'): row.read<int>('student_count'),
          },
        );
  }

  Stream<Student?> watchStudent(String id) {
    return (_database.select(
      _database.studentsTable,
    )..where((table) => table.id.equals(id))).watchSingleOrNull();
  }

  Future<String> addStudent({
    required String groupId,
    required String firstName,
    required String lastName,
    String? originNote,
    String? avatarJson,
  }) async {
    final row = await _database
        .into(_database.studentsTable)
        .insertReturning(
          StudentsTableCompanion.insert(
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            groupId: groupId,
            originNote: Value(
              originNote?.trim().isEmpty ?? true ? null : originNote!.trim(),
            ),
            avatarJson: Value(
              avatarJson?.trim().isEmpty ?? true ? null : avatarJson!.trim(),
            ),
          ),
        );
    return row.id;
  }

  Future<void> addStudents({
    required String groupId,
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

  Future<void> updateStudent({
    required String id,
    required String firstName,
    required String lastName,
    String? originNote,
    String? avatarJson,
  }) {
    return (_database.update(
      _database.studentsTable,
    )..where((table) => table.id.equals(id))).write(
      StudentsTableCompanion(
        firstName: Value(firstName.trim()),
        lastName: Value(lastName.trim()),
        originNote: Value(
          originNote?.trim().isEmpty ?? true ? null : originNote!.trim(),
        ),
        avatarJson: Value(
          avatarJson?.trim().isEmpty ?? true ? null : avatarJson!.trim(),
        ),
      ),
    );
  }

  Future<void> deleteStudent(String id) {
    return (_database.delete(
      _database.studentsTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> updateAvatar({required String id, String? avatarJson}) {
    return (_database.update(_database.studentsTable)
          ..where((table) => table.id.equals(id)))
        .write(StudentsTableCompanion(avatarJson: Value(avatarJson)));
  }

  StudentsTableCompanion _companionForDraft({
    required String groupId,
    required StudentDraft student,
  }) {
    return StudentsTableCompanion.insert(
      firstName: student.firstName.trim(),
      lastName: student.lastName.trim(),
      groupId: groupId,
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
