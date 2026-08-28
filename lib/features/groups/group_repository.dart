import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';

class GroupRepository {
  GroupRepository(this._database);

  final AppDatabase _database;

  /// Groups of one school year, or every group when [schoolYearId] is null.
  ///
  /// Groups that were never assigned a school year are included in whichever
  /// year is being shown. They predate the year becoming the app's frame, and
  /// hiding a teacher's group behind a filter they did not know existed is
  /// worse than showing it in the wrong year.
  Stream<List<Group>> watchActiveGroups({int? schoolYearId}) {
    return (_database.select(_database.groupsTable)
          ..where((table) => table.archivedAt.isNull())
          ..where((table) => _inSchoolYear(table, schoolYearId))
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Stream<List<Group>> watchArchivedGroups({int? schoolYearId}) {
    return (_database.select(_database.groupsTable)
          ..where((table) => table.archivedAt.isNotNull())
          ..where((table) => _inSchoolYear(table, schoolYearId))
          ..orderBy([(table) => OrderingTerm.desc(table.archivedAt)]))
        .watch();
  }

  Expression<bool> _inSchoolYear($GroupsTableTable table, int? schoolYearId) {
    if (schoolYearId == null) {
      return const Constant(true);
    }
    return table.schoolYearId.equals(schoolYearId) |
        table.schoolYearId.isNull();
  }

  Stream<Group?> watchGroup(int id) {
    return (_database.select(
      _database.groupsTable,
    )..where((table) => table.id.equals(id))).watchSingleOrNull();
  }

  Future<List<Group>> allActiveGroups({int? schoolYearId}) {
    return (_database.select(_database.groupsTable)
          ..where((table) => table.archivedAt.isNull())
          ..where((table) => _inSchoolYear(table, schoolYearId))
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .get();
  }

  Future<int> createGroup({
    required String name,
    String colorHex = '#FF1E88E5',
    required List<GradeScaleEntry> gradeScale,
    List<GradeCategory> gradeCategories = defaultGradeCategories,
    int? schoolYearId,
  }) {
    return _database
        .into(_database.groupsTable)
        .insert(
          GroupsTableCompanion.insert(
            name: name.trim(),
            schoolYearId: Value(schoolYearId),
            colorHex: Value(normalizeColorHex(colorHex, fallback: '#FF1E88E5')),
            gradeScaleJson: Value(encodeGradeScaleEntries(gradeScale)),
            gradeCategoriesJson: Value(encodeGradeCategories(gradeCategories)),
          ),
        );
  }

  Future<void> updateGroup({
    required int id,
    required String name,
    String? colorHex,
    required List<GradeScaleEntry> gradeScale,
    required List<GradeCategory> gradeCategories,
    Value<int?> schoolYearId = const Value.absent(),
  }) {
    return (_database.update(
      _database.groupsTable,
    )..where((table) => table.id.equals(id))).write(
      GroupsTableCompanion(
        name: Value(name.trim()),
        schoolYearId: schoolYearId,
        colorHex: colorHex == null
            ? const Value.absent()
            : Value(normalizeColorHex(colorHex, fallback: '#FF1E88E5')),
        gradeScaleJson: Value(encodeGradeScaleEntries(gradeScale)),
        gradeCategoriesJson: Value(encodeGradeCategories(gradeCategories)),
      ),
    );
  }

  Future<void> updateGroupsWithMatchingGradeScale({
    required List<GradeScaleEntry> previousGradeScale,
    required List<GradeScaleEntry> nextGradeScale,
  }) {
    return (_database.update(_database.groupsTable)..where(
          (table) => table.gradeScaleJson.equals(
            encodeGradeScaleEntries(previousGradeScale),
          ),
        ))
        .write(
          GroupsTableCompanion(
            gradeScaleJson: Value(encodeGradeScaleEntries(nextGradeScale)),
          ),
        );
  }

  Future<void> archiveGroup(int id) {
    return (_database.update(_database.groupsTable)
          ..where((table) => table.id.equals(id)))
        .write(GroupsTableCompanion(archivedAt: Value(DateTime.now())));
  }

  Future<void> unarchiveGroup(int id) {
    return (_database.update(_database.groupsTable)
          ..where((table) => table.id.equals(id)))
        .write(const GroupsTableCompanion(archivedAt: Value(null)));
  }

  Future<void> deleteGroup(int id) {
    return (_database.delete(
      _database.groupsTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<int> cloneGroup({
    required int sourceGroupId,
    required String newName,
    String? colorHex,
    List<GradeScaleEntry>? gradeScale,
    List<GradeCategory>? gradeCategories,
    Value<int?> schoolYearId = const Value.absent(),
  }) {
    return _database.transaction(() async {
      final sourceGroup = await (_database.select(
        _database.groupsTable,
      )..where((table) => table.id.equals(sourceGroupId))).getSingle();
      final students = await (_database.select(
        _database.studentsTable,
      )..where((table) => table.groupId.equals(sourceGroupId))).get();

      final clonedGroupId = await createGroup(
        name: newName,
        colorHex: colorHex ?? sourceGroup.colorHex,
        gradeScale:
            gradeScale ?? parseGradeScaleEntries(sourceGroup.gradeScaleJson),
        gradeCategories:
            gradeCategories ??
            parseGradeCategories(sourceGroup.gradeCategoriesJson),
        schoolYearId: schoolYearId.present
            ? schoolYearId.value
            : sourceGroup.schoolYearId,
      );

      for (final student in students) {
        await _database
            .into(_database.studentsTable)
            .insert(
              StudentsTableCompanion.insert(
                firstName: student.firstName,
                lastName: student.lastName,
                groupId: clonedGroupId,
                callName: Value(student.callName),
                originNote: Value(student.originNote),
                avatarJson: Value(student.avatarJson),
              ),
            );
      }

      return clonedGroupId;
    });
  }
}
