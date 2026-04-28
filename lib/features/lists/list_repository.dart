import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/formatting.dart';

class ListProgress {
  const ListProgress({required this.checked, required this.total});

  final int checked;
  final int total;
}

class ListRepository {
  ListRepository(this._database);

  final AppDatabase _database;

  Stream<List<Checklist>> watchAllLists() {
    return (_database.select(_database.listsTable)
          ..where((table) => table.archivedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Stream<List<Checklist>> watchArchivedAllLists() {
    return (_database.select(_database.listsTable)
          ..where((table) => table.archivedAt.isNotNull())
          ..orderBy([
            (table) => OrderingTerm.desc(table.archivedAt),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .watch();
  }

  Stream<List<Checklist>> watchLists(int groupId) {
    return (_database.select(_database.listsTable)
          ..where((table) => table.groupId.equals(groupId))
          ..where((table) => table.archivedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Stream<List<Checklist>> watchArchivedLists(int groupId) {
    return (_database.select(_database.listsTable)
          ..where((table) => table.groupId.equals(groupId))
          ..where((table) => table.archivedAt.isNotNull())
          ..orderBy([
            (table) => OrderingTerm.desc(table.archivedAt),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .watch();
  }

  Stream<Checklist?> watchList(int id) {
    return (_database.select(
      _database.listsTable,
    )..where((table) => table.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<ChecklistItem>> watchItems(int listId) {
    return (_database.select(_database.listItemsTable)
          ..where((table) => table.listId.equals(listId))
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .watch();
  }

  Stream<List<({Checklist list, ChecklistItem item})>> watchItemsForStudent(
    int studentId,
  ) {
    final query = _database.select(_database.listItemsTable).join([
      innerJoin(
        _database.listsTable,
        _database.listsTable.id.equalsExp(_database.listItemsTable.listId),
      ),
    ])
      ..where(_database.listItemsTable.studentId.equals(studentId))
      ..where(_database.listsTable.archivedAt.isNull())
      ..orderBy([OrderingTerm.asc(_database.listsTable.name)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              list: row.readTable(_database.listsTable),
              item: row.readTable(_database.listItemsTable),
            ),
          )
          .toList(),
    );
  }

  Stream<Map<int, ListProgress>> watchListProgress({int? groupId}) {
    final variables = <Variable<Object>>[];
    final whereClause = groupId == null ? '' : 'WHERE l.group_id = ?';
    if (groupId != null) {
      variables.add(Variable<Object>(groupId));
    }

    return _database
        .customSelect(
          '''
          SELECT
            l.id AS list_id,
            COUNT(i.id) AS total_count,
            COALESCE(SUM(CASE WHEN i.checked_at IS NOT NULL THEN 1 ELSE 0 END), 0)
              AS checked_count
          FROM lists_table l
          LEFT JOIN list_items_table i ON i.list_id = l.id
          $whereClause
          GROUP BY l.id
          ''',
          variables: variables,
          readsFrom: {_database.listsTable, _database.listItemsTable},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.read<int>('list_id'): ListProgress(
                checked: row.read<int>('checked_count'),
                total: row.read<int>('total_count'),
              ),
          },
        );
  }

  Future<int> createList({required int groupId, required String name}) {
    return _database
        .into(_database.listsTable)
        .insert(
          ListsTableCompanion.insert(groupId: groupId, name: name.trim()),
        );
  }

  Future<void> renameList({required int listId, required String name}) {
    return (_database.update(_database.listsTable)
          ..where((table) => table.id.equals(listId)))
        .write(ListsTableCompanion(name: Value(name.trim())));
  }

  Future<void> deleteList(int listId) {
    return (_database.delete(
      _database.listsTable,
    )..where((table) => table.id.equals(listId))).go();
  }

  Future<void> archiveList(int listId) {
    return (_database.update(_database.listsTable)
          ..where((table) => table.id.equals(listId)))
        .write(ListsTableCompanion(archivedAt: Value(DateTime.now())));
  }

  Future<void> unarchiveList(int listId) {
    return (_database.update(_database.listsTable)
          ..where((table) => table.id.equals(listId)))
        .write(const ListsTableCompanion(archivedAt: Value(null)));
  }

  Future<void> addItem({
    required int listId,
    int? studentId,
    required String label,
  }) {
    return _database
        .into(_database.listItemsTable)
        .insert(
          ListItemsTableCompanion.insert(
            listId: listId,
            studentId: Value(studentId),
            label: label.trim(),
          ),
        );
  }

  Future<void> toggleItem({required int itemId, required bool checked}) {
    return (_database.update(
      _database.listItemsTable,
    )..where((table) => table.id.equals(itemId))).write(
      ListItemsTableCompanion(
        checkedAt: Value(checked ? DateTime.now() : null),
      ),
    );
  }

  Future<void> deleteItem(int itemId) {
    return (_database.delete(
      _database.listItemsTable,
    )..where((table) => table.id.equals(itemId))).go();
  }

  Future<void> populateFromGroup({
    required int listId,
    required int groupId,
  }) async {
    final students =
        await (_database.select(_database.studentsTable)
              ..where((table) => table.groupId.equals(groupId))
              ..orderBy([
                (table) => OrderingTerm.asc(table.lastName),
                (table) => OrderingTerm.asc(table.firstName),
              ]))
            .get();

    await _database.batch((batch) {
      for (final student in students) {
        batch.insert(
          _database.listItemsTable,
          ListItemsTableCompanion.insert(
            listId: listId,
            studentId: Value(student.id),
            label: studentDisplayName(
              firstName: student.firstName,
              lastName: student.lastName,
            ),
          ),
        );
      }
    });
  }
}
