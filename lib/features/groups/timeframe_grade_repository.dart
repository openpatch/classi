import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

export '../../core/database/app_database.dart' show TimeframeGrade;

class TimeframeGradeRepository {
  TimeframeGradeRepository(this._database);

  final AppDatabase _database;

  Future<void> saveGrade({
    required int timeframeId,
    required int studentId,
    required String grade,
  }) async {
    await _database.into(_database.timeframeGradesTable).insert(
          TimeframeGradesTableCompanion.insert(
            timeframeId: timeframeId,
            studentId: studentId,
            grade: grade,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> saveGrades({
    required int timeframeId,
    required Map<int, String> studentIdToGrade,
  }) async {
    await _database.batch((batch) {
      // Delete existing grades for this timeframe
      batch.deleteWhere(
        _database.timeframeGradesTable,
        (t) => t.timeframeId.equals(timeframeId),
      );
      
      // Insert new grades
      for (final entry in studentIdToGrade.entries) {
        batch.insert(
          _database.timeframeGradesTable,
          TimeframeGradesTableCompanion.insert(
            timeframeId: timeframeId,
            studentId: entry.key,
            grade: entry.value,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<TimeframeGrade>> getGradesForTimeframe(int timeframeId) async {
    return (_database.select(_database.timeframeGradesTable)
          ..where((t) => t.timeframeId.equals(timeframeId))
          ..orderBy([(t) => OrderingTerm.asc(t.studentId)]))
        .get();
  }

  Stream<List<TimeframeGrade>> watchGradesForTimeframe(int timeframeId) {
    return (_database.select(_database.timeframeGradesTable)
          ..where((t) => t.timeframeId.equals(timeframeId))
          ..orderBy([(t) => OrderingTerm.asc(t.studentId)]))
        .watch();
  }

  Stream<List<TimeframeGrade>> watchGradesForStudent(int studentId) {
    return (_database.select(_database.timeframeGradesTable)
          ..where((t) => t.studentId.equals(studentId))
          ..orderBy([(t) => OrderingTerm.asc(t.timeframeId)]))
        .watch();
  }

  Future<Map<int, String>> getGradesMapForTimeframe(int timeframeId) async {
    final grades = await getGradesForTimeframe(timeframeId);
    return {for (final g in grades) g.studentId: g.grade};
  }

  Future<void> deleteGradesForTimeframe(int timeframeId) async {
    await (_database.delete(_database.timeframeGradesTable)
          ..where((t) => t.timeframeId.equals(timeframeId)))
        .go();
  }

  Future<void> deleteGrade(int id) async {
    await (_database.delete(_database.timeframeGradesTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<TimeframeGrade?> getGrade(int timeframeId, int studentId) async {
    return (_database.select(_database.timeframeGradesTable)
          ..where((t) => t.timeframeId.equals(timeframeId) & t.studentId.equals(studentId)))
        .getSingleOrNull();
  }
}
