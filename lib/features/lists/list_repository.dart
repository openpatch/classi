import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/formatting.dart';
import '../students/student_sorting.dart';
import 'list_item_links.dart';

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
    final query =
        _database.select(_database.listItemsTable).join([
            innerJoin(
              _database.listsTable,
              _database.listsTable.id.equalsExp(
                _database.listItemsTable.listId,
              ),
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

  Future<int> createList({
    required int groupId,
    required String name,
    StudentSortField sortField = StudentSortField.lastName,
  }) {
    return createListWithOptions(
      groupId: groupId,
      name: name,
      sortField: sortField,
    );
  }

  Future<int> createListWithOptions({
    int? groupId,
    required String name,
    bool populateFromGroupStudents = false,
    StudentSortField sortField = StudentSortField.lastName,
  }) {
    if (populateFromGroupStudents && groupId == null) {
      throw ArgumentError.value(
        groupId,
        'groupId',
        'Only group lists can create one item per student.',
      );
    }

    return _database.transaction(() async {
      final listId = await _database
          .into(_database.listsTable)
          .insert(
            ListsTableCompanion.insert(
              groupId: Value(groupId),
              name: name.trim(),
            ),
          );
      if (populateFromGroupStudents && groupId != null) {
        await populateFromGroup(
          listId: listId,
          groupId: groupId,
          sortField: sortField,
        );
      }
      return listId;
    });
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
    List<int> studentIds = const [],
    required String label,
  }) async {
    final list = await _requireList(listId);
    final normalizedStudentIds = await _validatedStudentIdsForList(
      list: list,
      studentIds: studentIds,
    );

    await _database
        .into(_database.listItemsTable)
        .insert(
          ListItemsTableCompanion.insert(
            listId: listId,
            studentId: Value(
              normalizedStudentIds.isEmpty ? null : normalizedStudentIds.first,
            ),
            studentIdsJson: Value(
              encodeListItemStudentIds(normalizedStudentIds),
            ),
            label: label.trim(),
          ),
        );
  }

  Future<void> updateItem({
    required ChecklistItem item,
    required String label,
    List<int> studentIds = const [],
  }) async {
    final list = await _requireList(item.listId);
    final normalizedStudentIds = await _validatedStudentIdsForList(
      list: list,
      studentIds: studentIds,
    );

    await (_database.update(
      _database.listItemsTable,
    )..where((table) => table.id.equals(item.id))).write(
      ListItemsTableCompanion(
        studentId: Value(
          normalizedStudentIds.isEmpty ? null : normalizedStudentIds.first,
        ),
        studentIdsJson: Value(encodeListItemStudentIds(normalizedStudentIds)),
        label: Value(label.trim()),
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
    StudentSortField sortField = StudentSortField.lastName,
  }) async {
    final list = await _requireList(listId);
    if (list.groupId != groupId) {
      throw ArgumentError.value(
        groupId,
        'groupId',
        'List does not belong to the requested group.',
      );
    }

    final query = _database.select(_database.studentsTable)
      ..where((table) => table.groupId.equals(groupId));
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
    final students = await query.get();

    await _database.batch((batch) {
      for (final student in students) {
        batch.insert(
          _database.listItemsTable,
          ListItemsTableCompanion.insert(
            listId: listId,
            studentId: Value(student.id),
            studentIdsJson: Value(encodeListItemStudentIds([student.id])),
            label: studentDisplayName(
              firstName: student.firstName,
              lastName: student.lastName,
              callName: student.callName,
              sortField: sortField,
            ),
          ),
        );
      }
    });
  }

  Future<Checklist> _requireList(int listId) {
    return (_database.select(
      _database.listsTable,
    )..where((table) => table.id.equals(listId))).getSingle();
  }

  Future<List<int>> _validatedStudentIdsForList({
    required Checklist list,
    required Iterable<int> studentIds,
  }) async {
    final normalizedStudentIds = normalizeListItemStudentIds(studentIds);
    if (normalizedStudentIds.isEmpty) {
      return normalizedStudentIds;
    }

    final query = _database.select(_database.studentsTable)
      ..where((table) => table.id.isIn(normalizedStudentIds));
    if (list.groupId != null) {
      query.where((table) => table.groupId.equals(list.groupId!));
    }
    final students = await query.get();
    final availableStudentIds = {for (final student in students) student.id};
    final invalidStudentIds = [
      for (final studentId in normalizedStudentIds)
        if (!availableStudentIds.contains(studentId)) studentId,
    ];
    if (invalidStudentIds.isNotEmpty) {
      throw ArgumentError.value(
        invalidStudentIds,
        'studentIds',
        'Students are not available for this list.',
      );
    }
    return normalizedStudentIds;
  }
}
