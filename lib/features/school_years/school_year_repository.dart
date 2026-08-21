import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

export '../../core/database/app_database.dart' show SchoolYear;

class SchoolYearRepository {
  SchoolYearRepository(this._database);

  final AppDatabase _database;

  Stream<List<SchoolYear>> watchSchoolYears() {
    return (_database.select(
      _database.schoolYearsTable,
    )..orderBy([(table) => OrderingTerm.desc(table.startDate)])).watch();
  }

  Stream<List<SchoolYear>> watchActiveSchoolYears() {
    return (_database.select(_database.schoolYearsTable)
          ..where((table) => table.archivedAt.isNull())
          ..orderBy([(table) => OrderingTerm.desc(table.startDate)]))
        .watch();
  }

  Stream<SchoolYear?> watchSchoolYear(int id) {
    return (_database.select(
      _database.schoolYearsTable,
    )..where((table) => table.id.equals(id))).watchSingleOrNull();
  }

  Future<List<SchoolYear>> allSchoolYears() {
    return (_database.select(
      _database.schoolYearsTable,
    )..orderBy([(table) => OrderingTerm.desc(table.startDate)])).get();
  }

  Future<SchoolYear?> getSchoolYear(int id) {
    return (_database.select(
      _database.schoolYearsTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  /// The school year new groups should default to: the active year that
  /// contains today, or else the most recently started active one.
  Future<SchoolYear?> currentSchoolYear() async {
    final active =
        await (_database.select(_database.schoolYearsTable)
              ..where((table) => table.archivedAt.isNull())
              ..orderBy([(table) => OrderingTerm.desc(table.startDate)]))
            .get();
    if (active.isEmpty) return null;

    final now = DateTime.now();
    for (final year in active) {
      if (!year.startDate.isAfter(now) && !year.endDate.isBefore(now)) {
        return year;
      }
    }
    return active.first;
  }

  Future<int> createSchoolYear({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _database
        .into(_database.schoolYearsTable)
        .insert(
          SchoolYearsTableCompanion.insert(
            label: label.trim(),
            startDate: startDate,
            endDate: endDate,
          ),
        );
  }

  Future<void> updateSchoolYear({
    required int id,
    required String label,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return (_database.update(
      _database.schoolYearsTable,
    )..where((table) => table.id.equals(id))).write(
      SchoolYearsTableCompanion(
        label: Value(label.trim()),
        startDate: Value(startDate),
        endDate: Value(endDate),
      ),
    );
  }

  /// Archiving a school year archives every group assigned to it, so wrapping
  /// up a year is a single step.
  Future<void> archiveSchoolYear(int id) {
    return _database.transaction(() async {
      final now = DateTime.now();
      await (_database.update(_database.schoolYearsTable)
            ..where((table) => table.id.equals(id)))
          .write(SchoolYearsTableCompanion(archivedAt: Value(now)));
      await (_database.update(_database.groupsTable)..where(
            (table) =>
                table.schoolYearId.equals(id) & table.archivedAt.isNull(),
          ))
          .write(GroupsTableCompanion(archivedAt: Value(now)));
    });
  }

  /// Restores the year itself. Its groups stay archived and can be brought
  /// back individually, since they were not necessarily archived together.
  Future<void> unarchiveSchoolYear(int id) {
    return (_database.update(_database.schoolYearsTable)
          ..where((table) => table.id.equals(id)))
        .write(const SchoolYearsTableCompanion(archivedAt: Value(null)));
  }

  /// Deletes a school year along with its timeframes and the timeframe grades
  /// that hang off them. Groups keep existing, without a year.
  Future<void> deleteSchoolYear(int id) {
    return (_database.delete(
      _database.schoolYearsTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<int> countGroups(int id) async {
    final groups = await (_database.select(
      _database.groupsTable,
    )..where((table) => table.schoolYearId.equals(id))).get();
    return groups.length;
  }

  Stream<List<Group>> watchGroups(int id) {
    return (_database.select(_database.groupsTable)
          ..where((table) => table.schoolYearId.equals(id))
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }
}

/// A school year runs from August 1st until July 31st of the following year.
int schoolYearStartFor(DateTime date) =>
    date.month >= 8 ? date.year : date.year - 1;

String defaultSchoolYearLabel(int startYear) =>
    '$startYear/${(startYear + 1).toString().substring(2)}';

DateTime defaultSchoolYearStart(int startYear) => DateTime(startYear, 8, 1);

DateTime defaultSchoolYearEnd(int startYear) => DateTime(startYear + 1, 7, 31);
