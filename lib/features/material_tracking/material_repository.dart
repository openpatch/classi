import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class MaterialRepository {
  MaterialRepository(this._database);

  final AppDatabase _database;

  Stream<List<MaterialLog>> watchStudentLogs(int studentId) {
    return (_database.select(_database.materialLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..orderBy([(table) => OrderingTerm.desc(table.date)]))
        .watch();
  }

  Stream<List<MaterialLog>> watchMaterialForStudentInDateRange(
    int studentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    return (_database.select(_database.materialLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.isBiggerOrEqualValue(normalizedStart) & 
                     table.date.isSmallerOrEqualValue(normalizedEnd))
          ..orderBy([(table) => OrderingTerm.asc(table.date)]))
        .watch();
  }

  Stream<Map<int, List<MaterialLog>>> watchMaterialForGroupInDateRange(
    int groupId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final query = _database.select(_database.materialLogsTable).join([
      innerJoin(
        _database.studentsTable,
        _database.studentsTable.id.equalsExp(_database.materialLogsTable.studentId),
      ),
    ])
      ..where(_database.studentsTable.groupId.equals(groupId))
      ..where(_database.materialLogsTable.date.isBiggerOrEqualValue(normalizedStart))
      ..where(_database.materialLogsTable.date.isSmallerOrEqualValue(normalizedEnd))
      ..orderBy([OrderingTerm.asc(_database.materialLogsTable.studentId), OrderingTerm.asc(_database.materialLogsTable.date)]);

    return query.watch().map((rows) {
      final result = <int, List<MaterialLog>>{};
      for (final row in rows) {
        final log = row.readTable(_database.materialLogsTable);
        result.putIfAbsent(log.studentId, () => []).add(log);
      }
      return result;
    });
  }

  Stream<Map<int, bool>> watchGroupSelections({
    required int groupId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT m.student_id, m.had_material
      FROM material_logs_table m
      JOIN students_table s ON s.id = m.student_id
        WHERE s.group_id = ? AND m.date = ?
        ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
          ],
          readsFrom: {_database.materialLogsTable, _database.studentsTable},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.read<int>('student_id'): row.read<bool>('had_material'),
          },
        );
  }

  Future<void> saveLog({
    required int studentId,
    required DateTime date,
    required bool hadMaterial,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing =
        await (_database.select(_database.materialLogsTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where((table) => table.date.equals(normalizedDate)))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.materialLogsTable)
          .insert(
            MaterialLogsTableCompanion.insert(
              studentId: studentId,
              date: normalizedDate,
              hadMaterial: Value(hadMaterial),
            ),
          );
      return;
    }

    await (_database.update(_database.materialLogsTable)
          ..where((table) => table.id.equals(existing.id)))
        .write(MaterialLogsTableCompanion(hadMaterial: Value(hadMaterial)));
  }

  Future<void> updateLog({
    required int id,
    required int studentId,
    required DateTime date,
    required bool hadMaterial,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final matches =
        await (_database.select(_database.materialLogsTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where((table) => table.date.equals(normalizedDate)))
            .get();

    MaterialLog? duplicate;
    for (final match in matches) {
      if (match.id != id) {
        duplicate = match;
        break;
      }
    }

    await _database.transaction(() async {
      if (duplicate != null) {
        await (_database.update(_database.materialLogsTable)
              ..where((table) => table.id.equals(duplicate!.id)))
            .write(MaterialLogsTableCompanion(hadMaterial: Value(hadMaterial)));
        await deleteLog(id);
        return;
      }

      await (_database.update(
        _database.materialLogsTable,
      )..where((table) => table.id.equals(id))).write(
        MaterialLogsTableCompanion(
          date: Value(normalizedDate),
          hadMaterial: Value(hadMaterial),
        ),
      );
    });
  }

  Future<void> deleteLog(int id) {
    return (_database.delete(
      _database.materialLogsTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> clearLog({
    required int studentId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await (_database.delete(_database.materialLogsTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.equals(normalizedDate)))
        .go();
  }
}
