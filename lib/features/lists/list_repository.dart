import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import 'list_sorting.dart';
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

  Stream<List<Checklist>> watchAllLists({
    ListSortField sortField = ListSortField.name,
  }) {
    final query = _database.select(_database.listsTable)
      ..where((table) => table.archivedAt.isNull());
    _applySort(query, sortField);
    return query.watch();
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

  Stream<List<Checklist>> watchLists(
    int groupId, {
    ListSortField sortField = ListSortField.name,
  }) {
    final query = _database.select(_database.listsTable)
      ..where((table) => table.groupId.equals(groupId))
      ..where((table) => table.archivedAt.isNull());
    _applySort(query, sortField);
    return query.watch();
  }

  /// Orders [query] by [sortField], with the name as the tie-breaker.
  ///
  /// A list nobody has touched since [ListsTable.touchedAt] existed falls back
  /// to when it was made, so an old library sorts sensibly from the first tap
  /// instead of piling every list at one end.
  void _applySort(
    SimpleSelectStatement<$ListsTableTable, Checklist> query,
    ListSortField sortField,
  ) {
    switch (sortField) {
      case ListSortField.name:
        query.orderBy([(table) => OrderingTerm.asc(table.name)]);
      case ListSortField.newest:
        query.orderBy([
          (table) => OrderingTerm.desc(table.createdAt),
          (table) => OrderingTerm.asc(table.name),
        ]);
      case ListSortField.recentlyUsed:
        query.orderBy([
          (table) =>
              OrderingTerm.desc(coalesce([table.touchedAt, table.createdAt])),
          (table) => OrderingTerm.asc(table.name),
        ]);
    }
  }

  /// Notes that [listId] was just worked on.
  ///
  /// Called from every change to a list's contents, which is what "recently
  /// used" means to a teacher: the list they last ticked something off in.
  Future<void> _touch(int listId) {
    return (_database.update(
      _database.listsTable,
    )..where((table) => table.id.equals(listId))).write(
      ListsTableCompanion(touchedAt: Value(DateTime.now())),
    );
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

  /// The entries of [listId], in the order the teacher asked for.
  ///
  /// Sorting by student reads the name off the student an entry is linked to,
  /// which is why it needs [studentSortField]: an entry should sit where its
  /// student sits in every other list in the app. Entries about nobody follow
  /// behind, in the order they were written.
  Stream<List<ChecklistItem>> watchItems(
    int listId, {
    ListItemSortField sortField = ListItemSortField.entered,
    StudentSortField studentSortField = StudentSortField.lastName,
  }) {
    final items = _database.listItemsTable;
    final students = _database.studentsTable;
    final query = _database.select(items).join([
      leftOuterJoin(students, students.id.equalsExp(items.studentId)),
    ])..where(items.listId.equals(listId));

    final entered = OrderingTerm.asc(items.createdAt);
    query.orderBy(switch (sortField) {
      ListItemSortField.entered => [entered],
      ListItemSortField.label => [
        OrderingTerm.asc(items.label.lower()),
        entered,
      ],
      ListItemSortField.student => [
        // Nobody's entry has no name to sort by; NULLs would lead otherwise.
        OrderingTerm.asc(students.id.isNull()),
        if (studentSortField == StudentSortField.firstName) ...[
          OrderingTerm.asc(students.firstName.lower()),
          OrderingTerm.asc(students.lastName.lower()),
        ] else ...[
          OrderingTerm.asc(students.lastName.lower()),
          OrderingTerm.asc(students.firstName.lower()),
        ],
        entered,
      ],
      ListItemSortField.openFirst => [
        OrderingTerm.asc(items.checkedAt.isNotNull()),
        entered,
      ],
    });

    return query.map((row) => row.readTable(items)).watch();
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
    await _touch(listId);
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
    await _touch(item.listId);
  }

  Future<void> toggleItem({required int itemId, required bool checked}) async {
    await (_database.update(
      _database.listItemsTable,
    )..where((table) => table.id.equals(itemId))).write(
      ListItemsTableCompanion(
        checkedAt: Value(checked ? DateTime.now() : null),
      ),
    );
    final item = await (_database.select(
      _database.listItemsTable,
    )..where((table) => table.id.equals(itemId))).getSingleOrNull();
    if (item != null) await _touch(item.listId);
  }

  Future<void> deleteItem(int itemId) async {
    final item = await (_database.select(
      _database.listItemsTable,
    )..where((table) => table.id.equals(itemId))).getSingleOrNull();
    await (_database.delete(
      _database.listItemsTable,
    )..where((table) => table.id.equals(itemId))).go();
    if (item != null) await _touch(item.listId);
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
    await _touch(listId);
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
