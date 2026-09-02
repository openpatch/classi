import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/lists/list_repository.dart';
import 'package:classi/features/lists/list_sorting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an in-memory library with the schema of app version 26, whose lists
/// had no record of when they were last worked on.
AppDatabase _openLegacyDatabase() {
  return AppDatabase.test(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('''
          CREATE TABLE lists_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NULL,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            archived_at INTEGER NULL
          );
        ''');
        db.execute('''
          CREATE TABLE list_items_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            list_id INTEGER NOT NULL REFERENCES lists_table (id)
              ON DELETE CASCADE,
            student_id INTEGER NULL,
            student_ids_json TEXT NULL,
            label TEXT NOT NULL,
            checked_at INTEGER NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
          );
        ''');
        db.execute('''
          INSERT INTO lists_table (name, created_at)
          VALUES ('Zoo trip', 1767225600), ('Ausflug', 1780272000);
        ''');
        db.execute('PRAGMA user_version = 26;');
      },
    ),
  );
}

void main() {
  test('lists made before the column sort by when they were made', () async {
    final database = _openLegacyDatabase();
    addTearDown(database.close);
    final repository = ListRepository(database);

    // Opening runs the migration.
    final lists = await repository
        .watchAllLists(sortField: ListSortField.recentlyUsed)
        .first;

    expect(lists.map((list) => list.name), ['Ausflug', 'Zoo trip']);
    expect(lists.every((list) => list.touchedAt == null), isTrue);
  });

  test('working on a migrated list starts recording when', () async {
    final database = _openLegacyDatabase();
    addTearDown(database.close);
    final repository = ListRepository(database);

    final lists = await repository.watchAllLists().first;
    final zoo = lists.firstWhere((list) => list.name == 'Zoo trip');
    await repository.addItem(listId: zoo.id, label: 'Tickets');

    final sorted = await repository
        .watchAllLists(sortField: ListSortField.recentlyUsed)
        .first;
    expect(sorted.first.name, 'Zoo trip');
    expect(sorted.first.touchedAt, isNotNull);
  });
}
