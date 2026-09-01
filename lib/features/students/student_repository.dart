import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
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

  /// Adds the students of a WebUntis class register to [groupId].
  ///
  /// Importing the same class twice must not double the group, and a teacher
  /// who typed their students in before connecting WebUntis should not end up
  /// with every name twice either. So an incoming student is, in order:
  ///
  /// * skipped when the group already holds their WebUntis id,
  /// * linked to an existing student of the same name who has no WebUntis id
  ///   yet, which is what makes a later attendance sync work for them,
  /// * otherwise added.
  Future<WebUntisRosterImportResult> importWebUntisStudents({
    required int groupId,
    required List<WebUntisStudentDraft> students,
  }) async {
    if (students.isEmpty) {
      return (added: 0, linked: 0, skipped: 0);
    }

    return _database.transaction(() async {
      final existing = await (_database.select(
        _database.studentsTable,
      )..where((table) => table.groupId.equals(groupId))).get();

      final byWebUntisId = <int, Student>{
        for (final student in existing) ?student.webuntisStudentId: student,
      };
      final byName = <String, Student>{};
      for (final student in existing) {
        byName.putIfAbsent(
          _nameKey(student.firstName, student.lastName),
          () => student,
        );
      }

      var added = 0;
      var linked = 0;
      var skipped = 0;

      for (final incoming in students) {
        final firstName = incoming.firstName.trim();
        final lastName = incoming.lastName.trim();
        if (firstName.isEmpty && lastName.isEmpty) {
          continue;
        }

        if (byWebUntisId.containsKey(incoming.webuntisStudentId)) {
          skipped++;
          continue;
        }

        final match = byName[_nameKey(firstName, lastName)];
        if (match != null && match.webuntisStudentId == null) {
          await (_database.update(
            _database.studentsTable,
          )..where((table) => table.id.equals(match.id))).write(
            StudentsTableCompanion(
              webuntisStudentId: Value(incoming.webuntisStudentId),
            ),
          );
          byWebUntisId[incoming.webuntisStudentId] = match;
          linked++;
          continue;
        }

        await _database
            .into(_database.studentsTable)
            .insert(
              StudentsTableCompanion.insert(
                firstName: firstName,
                lastName: lastName,
                groupId: groupId,
                webuntisStudentId: Value(incoming.webuntisStudentId),
              ),
            );
        added++;
      }

      return (added: added, linked: linked, skipped: skipped);
    });
  }

  /// Maps the WebUntis ids of a group's students onto their Classi ids, which
  /// is how an attendance import finds who an absence belongs to.
  Future<Map<int, int>> webUntisStudentIds(int groupId) async {
    final students =
        await (_database.select(_database.studentsTable)
              ..where((table) => table.groupId.equals(groupId))
              ..where((table) => table.webuntisStudentId.isNotNull()))
            .get();

    return {
      for (final student in students) ?student.webuntisStudentId: student.id,
    };
  }

  static String _nameKey(String firstName, String lastName) =>
      '${lastName.trim().toLowerCase()}|${firstName.trim().toLowerCase()}';

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
