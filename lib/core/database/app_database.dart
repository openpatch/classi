import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';

import 'tables/attendance_logs_table.dart';
import 'tables/grade_entries_table.dart';
import 'tables/groups_table.dart';
import 'tables/homework_logs_table.dart';
import 'tables/list_items_table.dart';
import 'tables/lists_table.dart';
import 'tables/material_logs_table.dart';
import 'tables/notes_table.dart';
import 'tables/students_table.dart';

part 'app_database.g.dart';

typedef Group = GroupsTableData;
typedef Student = StudentsTableData;
typedef GradeEntry = GradeEntriesTableData;
typedef MaterialLog = MaterialLogsTableData;
typedef HomeworkLog = HomeworkLogsTableData;
typedef AttendanceLog = AttendanceLogsTableData;

@DriftDatabase(
  tables: [
    AttendanceLogsTable,
    GroupsTable,
    StudentsTable,
    GradeEntriesTable,
    MaterialLogsTable,
    HomeworkLogsTable,
    ListsTable,
    ListItemsTable,
    NotesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor, {required this.databasePath});

  /// Creates an [AppDatabase] backed by a PowerSync/sqlite_async connection.
  ///
  /// The [databasePath] is used only for file-level operations such as
  /// checking the last-modified time; PowerSync owns the actual SQLite file.
  factory AppDatabase.withConnection(
    SqliteAsyncDriftConnection connection, {
    required String databasePath,
  }) {
    return AppDatabase._(connection, databasePath: databasePath);
  }

  AppDatabase.test(QueryExecutor executor)
    : this._(executor, databasePath: ':memory:');

  final String databasePath;

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      // PowerSync creates the tables. We only create local Drift tables
      // that are not part of the PowerSync schema (none currently).
    },
    onUpgrade: (migrator, from, to) async {
      // Table structure is managed by PowerSync schema updates.
      // Drift migrations only apply when using the in-memory test executor.
      if (from < 12 && databasePath == ':memory:') {
        await migrator.createAll();
      }
    },
  );

  Future<DateTime?> lastModified() async {
    if (databasePath == ':memory:') {
      return null;
    }

    final file = File(databasePath);
    if (!await file.exists()) {
      return null;
    }

    return file.lastModified();
  }

  Future<int> fileSizeBytes() async {
    if (databasePath == ':memory:') {
      return 0;
    }

    final file = File(databasePath);
    if (!await file.exists()) {
      return 0;
    }

    return file.length();
  }

  Future<void> checkpointAndTruncate() async {
    await customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
  }
}
