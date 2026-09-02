import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
// QueryStreamFetcher is the argument type of createStream, which [AppDatabase]
// overrides below. Drift neither exports nor publishes the type, so there is no
// public way to spell that signature; a drift upgrade that moves it fails to
// compile, and database_close_stream_test.dart covers the behaviour it guards.
// ignore: implementation_imports
import 'package:drift/src/runtime/executor/stream_queries.dart';

import 'cipher_opener.dart';
import 'database_indexes.dart';
import 'tables/attendance_logs_table.dart';
import 'tables/grade_entries_table.dart';
import 'tables/groups_table.dart';
import 'tables/homework_logs_table.dart';
import 'tables/lesson_slots_table.dart';
import 'tables/list_items_table.dart';
import 'tables/lists_table.dart';
import 'tables/material_logs_table.dart';
import 'tables/notes_table.dart';
import 'tables/school_years_table.dart';
import 'tables/seating_plan_positions_table.dart';
import 'tables/seating_plans_table.dart';
import 'tables/sessions_table.dart';
import 'tables/student_relations_table.dart';
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
typedef LessonSlot = LessonSlotsTableData;
typedef TimeframeGrade = TimeframeGradesTableData;

@DriftDatabase(
  tables: [
    AttendanceLogsTable,
    GroupsTable,
    StudentsTable,
    StudentRelationsTable,
    GradeEntriesTable,
    MaterialLogsTable,
    HomeworkLogsTable,
    LessonSlotsTable,
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

  /// Whether this open call created the schema, i.e. the library is brand new.
  ///
  /// Lets the session controller finish seeding with values that need the app's
  /// locale (timeframe labels), which the database layer has no business
  /// reaching for.
  bool wasCreated = false;

  /// The schema version this build of the app writes.
  ///
  /// Exposed statically so callers can compare it against the version on disk
  /// before opening (and therefore migrating) a library.
  static const int currentSchemaVersion = 26;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();

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
      wasCreated = true;
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
      if (from < 24) {
        await migrator.createTable(lessonSlotsTable);
        // Sessions gained the period they are held in, and the unique key
        // grew to include it so a group can hold two lessons on one day.
        // A unique key is part of the CREATE TABLE statement, so the table
        // has to be rewritten instead of just extended.
        // ignore: experimental_member_use
        await migrator.alterTable(
          TableMigration(
            sessionsTable,
            newColumns: [sessionsTable.periodStart, sessionsTable.periodEnd],
          ),
        );
      }
      if (from < 25) {
        // The database had no indexes at all until here, so every lookup by
        // group, student or date was a full table scan. Purely additive.
        await _createIndexes();
      }
      if (from < 26) {
        await migrator.createTable(studentRelationsTable);
        // Purely additive, and `IF NOT EXISTS` everywhere, so re-running the
        // whole set is the cheapest way to pick up the new table's indexes.
        await _createIndexes();
      }
    },
  );

  /// Creates every index in [databaseIndexStatements].
  ///
  /// Shared by `onCreate` and the version 25 migration step so a fresh library
  /// and a migrated one end up with exactly the same indexes.
  ///
  /// A failure is logged and skipped rather than propagated: an index is an
  /// optimization, and letting one abort the migration would leave a teacher
  /// unable to open their library over a query plan.
  Future<void> _createIndexes() async {
    for (final statement in databaseIndexStatements) {
      try {
        await customStatement(statement);
      } on Object catch (error) {
        developer.log(
          'Skipped an index: $statement',
          name: 'classi.database',
          error: error,
        );
      }
    }
  }

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

  /// Re-runs every open query stream against the current data.
  ///
  /// Drift only re-runs a stream when it is told the tables behind it changed,
  /// and that notification has to travel from the background isolate the
  /// library actually runs in. When one is missed — the app was away while it
  /// was delivered — writes keep landing but every screen goes on drawing what
  /// it last saw, and only restarting the app brings it back. Coming back to
  /// the app is the moment to catch up.
  void refreshAllStreams() {
    markTablesUpdated(allTables);
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

  /// Whether [close] has been asked for. See [createStream].
  bool _isClosing = false;

  /// Drops the failures a screen's still-open query streams run into while the
  /// library is closing.
  ///
  /// Locking, switching libraries and auto-importing all close the database
  /// under whatever screen is on top, and its streams can have a select in
  /// flight. Drift then reports "the connection was closed", which the UI would
  /// show as an error report for a teardown the app itself asked for. Once the
  /// close is over the screen is gone anyway, so there is nothing left to tell
  /// the teacher. Failures outside a close still reach the UI.
  @override
  // ignore: invalid_use_of_internal_member
  Stream<T> createStream<T extends Object>(QueryStreamFetcher<T> stmt) {
    return super
        .createStream(stmt)
        .handleError((_, _) {}, test: (_) => _isClosing);
  }

  @override
  Future<void> close() {
    _isClosing = true;
    return super.close();
  }
}
