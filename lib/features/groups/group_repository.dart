import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';

class GroupRepository {
  GroupRepository(this._database);

  final AppDatabase _database;

  Stream<List<Group>> watchActiveGroups() {
    return (_database.select(_database.groupsTable)
          ..where((table) => table.archivedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Stream<List<Group>> watchArchivedGroups() {
    return (_database.select(_database.groupsTable)
          ..where((table) => table.archivedAt.isNotNull())
          ..orderBy([(table) => OrderingTerm.desc(table.archivedAt)]))
        .watch();
  }

  Stream<Group?> watchGroup(int id) {
    return (_database.select(
      _database.groupsTable,
    )..where((table) => table.id.equals(id))).watchSingleOrNull();
  }

  Future<List<Group>> allActiveGroups() {
    return (_database.select(_database.groupsTable)
          ..where((table) => table.archivedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .get();
  }

  Future<int> createGroup({
    required String name,
    String colorHex = '#FF1E88E5',
    required List<GradeScaleEntry> gradeScale,
    List<GradeCategory> gradeCategories = defaultGradeCategories,
  }) {
    return _database
        .into(_database.groupsTable)
        .insert(
          GroupsTableCompanion.insert(
            name: name.trim(),
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
  }) {
    return (_database.update(
      _database.groupsTable,
    )..where((table) => table.id.equals(id))).write(
      GroupsTableCompanion(
        name: Value(name.trim()),
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
