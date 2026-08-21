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
import 'tables/school_years_table.dart';
import 'tables/seating_plan_positions_table.dart';
import 'tables/seating_plans_table.dart';
import 'tables/sessions_table.dart';
import 'tables/students_table.dart';
import 'tables/timeframe_grades_table.dart';
import 'tables/timeframes_table.dart';

part 'app_database.g.dart';

typedef Group = GroupsTableData;
typedef Student = StudentsTableData;
typedef GradeEntry = GradeEntriesTableData;
typedef MaterialLog = MaterialLogsTableData;
typedef HomeworkLog = HomeworkLogsTableData;
typedef AttendanceLog = AttendanceLogsTableData;
typedef Session = SessionsTableData;
typedef SchoolYear = SchoolYearsTableData;
typedef Timeframe = TimeframesTableData;
typedef TimeframeGrade = TimeframeGradesTableData;

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
    SchoolYearsTable,
    SeatingPlansTable,
    SeatingPlanPositionsTable,
    SessionsTable,
    TimeframesTable,
    TimeframeGradesTable,
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
  int get schemaVersion => 23;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();

      // Start a fresh library off with the school year we are in, so groups
      // and timeframes have somewhere to live right away.
      final startYear = _schoolYearStart(DateTime.now());
      await into(schoolYearsTable).insert(
        SchoolYearsTableCompanion.insert(
          label: _schoolYearLabel(startYear),
          startDate: DateTime(startYear, 8, 1),
          endDate: DateTime(startYear + 1, 7, 31),
        ),
      );
    },
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
      if (from < 17) {
        await migrator.createTable(sessionsTable);
      }
      if (from < 18) {
        // Backfill sessions from existing grade entries.
        // Grade entries belong to students, students belong to groups.
        // Sessions are unique on (group_id, date, category_id), so we group
        // there and pick the first label / category_name / created_at.
        await customStatement('''
          INSERT INTO sessions_table
            (group_id, date, label, category_id, category_name, created_at)
          SELECT
            s.group_id,
            ge.date,
            MIN(ge.session_label),
            ge.category_id,
            MIN(ge.category_name),
            MIN(ge.created_at)
          FROM grade_entries_table ge
          JOIN students_table s ON ge.student_id = s.id
          GROUP BY s.group_id, ge.date, ge.category_id
          ON CONFLICT(group_id, date, category_id) DO UPDATE SET
            label = excluded.label,
            category_name = excluded.category_name
        ''');
        // Backfill sessions from attendance logs for dates that have no
        // session yet. Attendance has no label or category, so defaults are
        // used. ON CONFLICT DO NOTHING preserves sessions already created
        // from grade entries above.
        await customStatement('''
          INSERT INTO sessions_table
            (group_id, date, label, category_id, category_name, created_at)
          SELECT
            s.group_id,
            al.date,
            '',
            'sonstige-mitarbeit',
            'Sonstige Mitarbeit',
            MIN(al.created_at)
          FROM attendance_logs_table al
          JOIN students_table s ON al.student_id = s.id
          GROUP BY s.group_id, al.date
          ON CONFLICT(group_id, date, category_id) DO NOTHING
        ''');
      }
      if (from < 19) {
        await migrator.createTable(timeframesTable);
      }
      if (from < 21) {
        await migrator.createTable(timeframeGradesTable);
      }
      if (from < 22) {
        await migrator.addColumn(studentsTable, studentsTable.callName);
      }
      if (from < 23) {
        await _migrateTimeframesToSchoolYears(migrator);
      }
    },
  );

  /// A school year runs from August 1st until July 31st of the following year.
  /// Returns the calendar year the school year containing [date] started in.
  static int _schoolYearStart(DateTime date) =>
      date.month >= 8 ? date.year : date.year - 1;

  static String _schoolYearLabel(int startYear) =>
      '$startYear/${(startYear + 1).toString().substring(2)}';

  /// SQL that buckets the unix-timestamp [column] into a school year id, using
  /// the ids handed out while creating the rows in [yearIds].
  static String _schoolYearIdSql(String column, Map<int, int> yearIds) {
    final startYear =
        "CAST(strftime('%Y', $column, 'unixepoch', 'localtime') AS INTEGER) - "
        "(CASE WHEN CAST(strftime('%m', $column, 'unixepoch', 'localtime') "
        'AS INTEGER) >= 8 THEN 0 ELSE 1 END)';
    final cases = [
      for (final entry in yearIds.entries)
        'WHEN $startYear = ${entry.key} THEN ${entry.value}',
    ].join(' ');
    return 'CASE $cases ELSE ${yearIds.values.first} END';
  }

  /// Moves timeframes off groups and onto school years shared by all groups.
  ///
  /// Every existing timeframe and group is bucketed into the school year it
  /// falls into, timeframes that were identical across groups are merged into
  /// a single one, and their grades are remapped onto the survivor.
  Future<void> _migrateTimeframesToSchoolYears(Migrator migrator) async {
    await migrator.createTable(schoolYearsTable);
    await migrator.addColumn(groupsTable, groupsTable.schoolYearId);

    final dates = await customSelect(
      'SELECT start_date AS date FROM timeframes_table '
      'UNION ALL SELECT created_at AS date FROM groups_table',
    ).get();

    final startYears = <int>{
      for (final row in dates) _schoolYearStart(row.read<DateTime>('date')),
      _schoolYearStart(DateTime.now()),
    }.toList()..sort();

    final yearIds = <int, int>{};
    for (final startYear in startYears) {
      yearIds[startYear] = await into(schoolYearsTable).insert(
        SchoolYearsTableCompanion.insert(
          label: _schoolYearLabel(startYear),
          startDate: DateTime(startYear, 8, 1),
          endDate: DateTime(startYear + 1, 7, 31),
        ),
      );
    }

    // Assign groups while timeframes still know which group they belonged to:
    // the year of the group's latest timeframe, falling back to its own age.
    await customStatement('''
      UPDATE groups_table SET school_year_id = (
        SELECT ${_schoolYearIdSql('t.start_date', yearIds)}
        FROM timeframes_table t
        WHERE t.group_id = groups_table.id
        ORDER BY t.start_date DESC
        LIMIT 1
      )
    ''');
    await customStatement('''
      UPDATE groups_table
      SET school_year_id = ${_schoolYearIdSql('created_at', yearIds)}
      WHERE school_year_id IS NULL
    ''');

    // Rewriting the table drops and re-creates it, so keep the grades that
    // reference it out of reach of a cascading delete.
    await customStatement(
      'CREATE TABLE _timeframe_grades_backup AS '
      'SELECT * FROM timeframe_grades_table',
    );

    await migrator.alterTable(
      TableMigration(
        timeframesTable,
        newColumns: [timeframesTable.schoolYearId],
        columnTransformer: {
          timeframesTable.schoolYearId: CustomExpression<int>(
            _schoolYearIdSql('start_date', yearIds),
          ),
        },
      ),
    );

    await customStatement(
      'INSERT OR IGNORE INTO timeframe_grades_table '
      '(id, timeframe_id, student_id, grade) '
      'SELECT id, timeframe_id, student_id, grade '
      'FROM _timeframe_grades_backup',
    );
    await customStatement('DROP TABLE _timeframe_grades_backup');

    // Merge timeframes that were duplicated across groups, keeping the oldest.
    const survivors =
        'SELECT MIN(id) AS keep_id, school_year_id, label, start_date, end_date '
        'FROM timeframes_table '
        'GROUP BY school_year_id, label, start_date, end_date';
    await customStatement('''
      DELETE FROM timeframe_grades_table WHERE id IN (
        SELECT g.id FROM timeframe_grades_table g
        JOIN timeframes_table t ON t.id = g.timeframe_id
        JOIN ($survivors) k ON k.school_year_id = t.school_year_id
          AND k.label = t.label AND k.start_date = t.start_date
          AND k.end_date = t.end_date
        WHERE g.timeframe_id <> k.keep_id AND EXISTS (
          SELECT 1 FROM timeframe_grades_table e
          WHERE e.timeframe_id = k.keep_id AND e.student_id = g.student_id
        )
      )
    ''');
    await customStatement('''
      UPDATE timeframe_grades_table SET timeframe_id = (
        SELECT k.keep_id FROM timeframes_table t
        JOIN ($survivors) k ON k.school_year_id = t.school_year_id
          AND k.label = t.label AND k.start_date = t.start_date
          AND k.end_date = t.end_date
        WHERE t.id = timeframe_grades_table.timeframe_id
      )
    ''');
    await customStatement(
      'DELETE FROM timeframes_table WHERE id NOT IN '
      '(SELECT keep_id FROM ($survivors))',
    );
  }

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
