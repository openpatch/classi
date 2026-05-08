import 'dart:io';

import 'package:drift/drift.dart';

import 'cipher_opener.dart';
import 'tables/attendance_logs_table.dart';
import 'tables/grade_entries_table.dart';
import 'tables/groups_table.dart';
import 'tables/homework_logs_table.dart';
import 'tables/list_items_table.dart';
import 'tables/lists_table.dart';
import 'tables/material_logs_table.dart';
import 'tables/notes_table.dart';
import 'tables/seating_plan_positions_table.dart';
import 'tables/seating_plans_table.dart';
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
    SeatingPlansTable,
    SeatingPlanPositionsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor, {required this.databasePath});

  factory AppDatabase.open({
    required File dbFile,
    required String databaseKey,
  }) {
    return AppDatabase._(
      openEncryptedDatabase(dbFile, databaseKey),
      databasePath: dbFile.path,
    );
  }

  AppDatabase.test(QueryExecutor executor)
    : this._(executor, databasePath: ':memory:');

  final String databasePath;

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(groupsTable, groupsTable.archivedAt);
      }
      if (from < 3) {
        await migrator.addColumn(groupsTable, groupsTable.gradeCategoriesJson);
        await migrator.addColumn(
          gradeEntriesTable,
          gradeEntriesTable.categoryId,
        );
        await migrator.addColumn(
          gradeEntriesTable,
          gradeEntriesTable.categoryName,
        );
      }
      if (from < 4) {
        // ignore: experimental_member_use
        await migrator.alterTable(TableMigration(gradeEntriesTable));
      }
      if (from < 5) {
        await migrator.createTable(homeworkLogsTable);
      }
      if (from < 6) {
        await migrator.createTable(attendanceLogsTable);
      }
      if (from < 7) {
        await migrator.addColumn(groupsTable, groupsTable.colorHex);
      }
      if (from < 8) {
        await migrator.addColumn(listsTable, listsTable.archivedAt);
        await migrator.addColumn(notesTable, notesTable.archivedAt);
      }
      if (from < 9) {
        await migrator.addColumn(notesTable, notesTable.studentIdsJson);
      }
      if (from < 10) {
        await migrator.addColumn(studentsTable, studentsTable.seatIndex);
      }
      if (from < 11) {
        await migrator.alterTable(TableMigration(listsTable));
        await migrator.addColumn(listItemsTable, listItemsTable.studentIdsJson);
        await customStatement('''
          UPDATE list_items_table
          SET student_ids_json = json_array(student_id)
          WHERE student_id IS NOT NULL AND student_ids_json IS NULL
        ''');
      }
      if (from < 12) {
        final cols = await customSelect(
          "PRAGMA table_info('attendance_logs_table')",
        ).get();
        final existing = {for (final r in cols) r.data['name'] as String};
        if (!existing.contains('is_absent')) {
          await migrator.addColumn(
            attendanceLogsTable,
            attendanceLogsTable.isAbsent,
          );
        }
      }
      if (from < 13) {
        final cols = await customSelect(
          "PRAGMA table_info('attendance_logs_table')",
        ).get();
        final existing = {for (final r in cols) r.data['name'] as String};
        if (!existing.contains('is_excused')) {
          await migrator.addColumn(
            attendanceLogsTable,
            attendanceLogsTable.isExcused,
          );
        }
      }
      if (from < 14) {
        await migrator.createTable(seatingPlansTable);
        await migrator.createTable(seatingPlanPositionsTable);
      }
      if (from < 15) {
        await migrator.addColumn(seatingPlansTable, seatingPlansTable.columns);
        await migrator.addColumn(
          seatingPlanPositionsTable,
          seatingPlanPositionsTable.colIndex,
        );
        await migrator.addColumn(
          seatingPlanPositionsTable,
          seatingPlanPositionsTable.rowIndex,
        );
      }
      if (from < 16) {
        await migrator.addColumn(
          seatingPlansTable,
          seatingPlansTable.isDefault,
        );
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
