import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

export '../../core/database/app_database.dart' show Timeframe;

class TimeframeRepository {
  TimeframeRepository(this._database);

  final AppDatabase _database;

  Future<int> saveTimeframe({
    required int groupId,
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    String? finalGrade,
  }) async {
    return await _database.into(_database.timeframesTable).insert(
          TimeframesTableCompanion.insert(
            groupId: groupId,
            label: label,
            startDate: startDate,
            endDate: endDate,
            finalGrade: Value(finalGrade),
            createdAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> updateTimeframe({
    required int id,
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    String? finalGrade,
  }) async {
    await (_database.update(_database.timeframesTable)
          ..where((table) => table.id.equals(id)))
        .write(
          TimeframesTableCompanion(
            label: Value(label),
            startDate: Value(startDate),
            endDate: Value(endDate),
            finalGrade: Value(finalGrade),
          ),
        );
  }

  Future<void> deleteTimeframe(int id) async {
    await (_database.delete(_database.timeframesTable)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  Future<List<Timeframe>> getTimeframes(int groupId) async {
    return await (_database.select(_database.timeframesTable)
          ..where((table) => table.groupId.equals(groupId))
          ..orderBy([(table) => OrderingTerm.asc(table.startDate)]))
        .get();
  }

  Stream<List<Timeframe>> watchTimeframes(int groupId) {
    return (_database.select(_database.timeframesTable)
          ..where((table) => table.groupId.equals(groupId))
          ..orderBy([(table) => OrderingTerm.asc(table.startDate)]))
        .watch();
  }

  Future<List<Timeframe>> getOverlappingTimeframes({
    required int groupId,
    required DateTime startDate,
    required DateTime endDate,
    int? excludeId,
  }) async {
    // Get all timeframes and filter in Dart since Drift 2.32.1 doesn't support
    // the date comparison operators we need
    final allTimeframes = await (_database.select(_database.timeframesTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.id.isNotIn([excludeId ?? -1]))
          ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
        .get();

    // Filter for overlaps: A overlaps with B if A.start <= B.end AND A.end >= B.start
    return allTimeframes
        .where((t) => t.startDate.isBefore(endDate) || t.startDate == endDate)
        .where((t) => t.endDate.isAfter(startDate) || t.endDate == startDate)
        .toList();
  }

  Future<Timeframe?> getTimeframe(int id) async {
    return await (_database.select(_database.timeframesTable)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }
}
