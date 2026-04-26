import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class HomeworkRepository {
  HomeworkRepository(this._database);

  final AppDatabase _database;

  Stream<List<HomeworkLog>> watchStudentLogs(int studentId) {
    return (_database.select(_database.homeworkLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..orderBy([(table) => OrderingTerm.desc(table.date)]))
        .watch();
  }

  Stream<Map<int, bool>> watchGroupSelections({
    required int groupId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT h.student_id, h.had_homework
      FROM homework_logs_table h
      JOIN students_table s ON s.id = h.student_id
        WHERE s.group_id = ? AND h.date = ?
        ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
          ],
          readsFrom: {_database.homeworkLogsTable, _database.studentsTable},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.read<int>('student_id'): row.read<bool>('had_homework'),
          },
        );
  }

  Future<void> saveLog({
    required int studentId,
    required DateTime date,
    required bool hadHomework,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing =
        await (_database.select(_database.homeworkLogsTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where((table) => table.date.equals(normalizedDate)))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.homeworkLogsTable)
          .insert(
            HomeworkLogsTableCompanion.insert(
              studentId: studentId,
              date: normalizedDate,
              hadHomework: Value(hadHomework),
            ),
          );
      return;
    }

    await (_database.update(_database.homeworkLogsTable)
          ..where((table) => table.id.equals(existing.id)))
        .write(HomeworkLogsTableCompanion(hadHomework: Value(hadHomework)));
  }

  Future<void> updateLog({
    required int id,
    required int studentId,
    required DateTime date,
    required bool hadHomework,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final matches =
        await (_database.select(_database.homeworkLogsTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where((table) => table.date.equals(normalizedDate)))
            .get();

    HomeworkLog? duplicate;
    for (final match in matches) {
      if (match.id != id) {
        duplicate = match;
        break;
      }
    }

    await _database.transaction(() async {
      if (duplicate != null) {
        await (_database.update(_database.homeworkLogsTable)
              ..where((table) => table.id.equals(duplicate!.id)))
            .write(HomeworkLogsTableCompanion(hadHomework: Value(hadHomework)));
        await deleteLog(id);
        return;
      }

      await (_database.update(
        _database.homeworkLogsTable,
      )..where((table) => table.id.equals(id))).write(
        HomeworkLogsTableCompanion(
          date: Value(normalizedDate),
          hadHomework: Value(hadHomework),
        ),
      );
    });
  }

  Future<void> clearLog({
    required int studentId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.delete(_database.homeworkLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.equals(normalizedDate)))
        .go();
  }

  Future<void> deleteLog(int id) {
    return (_database.delete(
      _database.homeworkLogsTable,
    )..where((table) => table.id.equals(id))).go();
  }
}
