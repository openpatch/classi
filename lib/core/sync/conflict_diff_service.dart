import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../database/encrypted_database_file.dart';
import '../security/key_service.dart';

/// A summary of what differs between two backup archives, shown on the
/// conflict resolution screen to help the user pick a side.
class ConflictDiffSummary {
  ConflictDiffSummary({
    this.rowsOnlyOnThisDevice = 0,
    this.rowsOnlyOnServer = 0,
    this.rowsChangedOnBoth = 0,
    this.tableSummaries = const [],
  });

  /// Rows that exist only in this device's version (new or added locally).
  final int rowsOnlyOnThisDevice;

  /// Rows that exist only in the server's version (new or added remotely).
  final int rowsOnlyOnServer;

  /// Rows present on both sides whose content differs.
  ///
  /// This is a two-way comparison with no merge base, so there is no way to
  /// tell which side moved — every differing row counts here, which is the
  /// conservative reading for the UI. Once the merge base from step 6 is
  /// available this can be split into one-sided and genuine both-sides
  /// changes.
  final int rowsChangedOnBoth;

  /// Per-table breakdown of the differences.
  final List<ConflictDiffTableSummary> tableSummaries;

  /// Whether the changes are non-overlapping (safe to auto-merge).
  bool get canAutoMerge => rowsChangedOnBoth == 0;

  /// Total number of differing rows across all tables.
  int get totalDifferences =>
      rowsOnlyOnThisDevice + rowsOnlyOnServer + rowsChangedOnBoth;
}

/// Per-table breakdown of differences between two backup versions.
class ConflictDiffTableSummary {
  const ConflictDiffTableSummary({
    required this.tableName,
    required this.displayNameKey,
    required this.onlyOnThisDevice,
    required this.onlyOnServer,
    required this.changedOnBoth,
  });

  final String tableName;

  /// Translation key for the table's user-facing name, e.g. `students` for
  /// `students_table`. The UI resolves it — the service has no business
  /// deciding which language the teacher reads.
  final String displayNameKey;

  final int onlyOnThisDevice;
  final int onlyOnServer;
  final int changedOnBoth;

  bool get hasDifferences =>
      onlyOnThisDevice > 0 || onlyOnServer > 0 || changedOnBoth > 0;
}

/// Compares two backup archives and produces a summary of what differs.
///
/// The comparison works by unpacking both archives to disk, opening them as
/// SQLite databases and comparing row-by-row across every table. It does not
/// need a merge base — it's a direct two-way comparison, which is what the
/// user sees on the conflict screen.
class ConflictDiffService {
  ConflictDiffService({KeyService? keyService})
      : _keyService = keyService ?? KeyService();

  final KeyService _keyService;

  /// Compares [thisDeviceBytes] (the conflict copy) against
  /// [serverBytes] (the canonical backup) and returns a summary.
  ///
  /// Both are `.classi-backup` ZIP archives containing a `data.db` SQLite
  /// file. Library databases are SQLCipher-encrypted, so each archive's own
  /// security metadata is unpacked alongside it and [passphrase] is used to
  /// derive that snapshot's key — a backup written by another device carries
  /// its own salt, so the key has to be derived per archive rather than
  /// reused from the open library.
  ///
  /// The comparison loads every row of both databases into memory and does
  /// so synchronously, so callers run it off the UI isolate — see
  /// `AppSessionController.conflictDiff`. Nothing on this path may reach for
  /// a platform channel or that stops being possible.
  Future<ConflictDiffSummary> compare({
    required Uint8List thisDeviceBytes,
    required Uint8List serverBytes,
    required String? passphrase,
  }) async {
    final workspace = await Directory.systemTemp.createTemp('classi-diff');
    try {
      final thisDeviceDb = await _extractDatabase(
        archiveBytes: thisDeviceBytes,
        directory: Directory('${workspace.path}/this-device'),
        passphrase: passphrase,
      );
      try {
        final serverDb = await _extractDatabase(
          archiveBytes: serverBytes,
          directory: Directory('${workspace.path}/server'),
          passphrase: passphrase,
        );
        try {
          return _compareDatabases(thisDeviceDb, serverDb);
        } finally {
          serverDb.close();
        }
      } finally {
        thisDeviceDb.close();
      }
    } finally {
      // Only now that every handle is closed: deleting a file that SQLite
      // still has open fails outright on Windows, and elsewhere it leaves
      // SQLite reading from a file nothing can recover if it needs to.
      try {
        await workspace.delete(recursive: true);
      } on Object catch (error) {
        developer.log(
          'Could not clean up the conflict diff workspace',
          name: 'classi.sync',
          error: error,
        );
      }
    }
  }

  /// Unpacks a backup archive into [directory] and opens its database.
  ///
  /// Every entry is written out, not just `data.db`: the key is derived from
  /// the `.security.json` sidecar that sits next to the database, and the
  /// `-wal` file may still hold committed rows.
  Future<sqlite3.Database> _extractDatabase({
    required Uint8List archiveBytes,
    required Directory directory,
    required String? passphrase,
  }) async {
    await directory.create(recursive: true);
    final archive = ZipDecoder().decodeBytes(archiveBytes);

    var foundDatabase = false;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      // Guard against entry names that would escape the workspace.
      if (file.name.contains('/') || file.name.contains('\\')) continue;
      if (file.name == 'data.db') foundDatabase = true;
      File('${directory.path}/${file.name}')
          .writeAsBytesSync(Uint8List.fromList(file.content as List<int>));
    }
    if (!foundDatabase) {
      throw StateError('Backup archive does not contain data.db');
    }

    final dbFile = File('${directory.path}/data.db');
    return openLibraryDatabaseFile(
      dbFile.path,
      databaseKey: await _databaseKeyFor(dbFile: dbFile, passphrase: passphrase),
    );
  }

  /// Derives the SQLCipher key for an unpacked snapshot.
  ///
  /// Returns `null` when the snapshot has no security metadata, which means
  /// it is not encrypted — only ever the case for test fixtures.
  Future<String?> _databaseKeyFor({
    required File dbFile,
    required String? passphrase,
  }) async {
    if (passphrase == null) return null;
    if (!await _keyService.hasSecuritySetup(dbFile)) return null;
    return _keyService.deriveDatabaseKey(
      dbFile: dbFile,
      passphrase: passphrase,
    );
  }

  ConflictDiffSummary _compareDatabases(
    sqlite3.Database thisDevice,
    sqlite3.Database server,
  ) {
    var onlyOnThisDevice = 0;
    var onlyOnServer = 0;
    var changedOnBoth = 0;
    final tableSummaries = <ConflictDiffTableSummary>[];

    for (final entry in _tableDisplayNameKeys.entries) {
      final tableName = entry.key;
      final displayNameKey = entry.value;

      if (!_tableExists(thisDevice, tableName) ||
          !_tableExists(server, tableName)) {
        continue;
      }

      final columns = _columnsFor(thisDevice, tableName);
      if (columns.isEmpty) continue;

      final thisRows = _loadRows(thisDevice, tableName);
      final serverRows = _loadRows(server, tableName);

      var tOnly = 0;
      var sOnly = 0;
      var both = 0;

      final allIds = <int>{
        ...thisRows.keys,
        ...serverRows.keys,
      };

      for (final id in allIds) {
        final thisRow = thisRows[id];
        final serverRow = serverRows[id];

        if (thisRow != null && serverRow != null) {
          if (_rowsEqual(thisRow, serverRow, columns)) {
            // Same content — no difference.
            continue;
          }
          // Both exist but content differs. We can't tell which side
          // changed without a base, so classify as "changed on both".
          both++;
          changedOnBoth++;
        } else if (thisRow != null && serverRow == null) {
          tOnly++;
          onlyOnThisDevice++;
        } else if (thisRow == null && serverRow != null) {
          sOnly++;
          onlyOnServer++;
        }
      }

      if (tOnly > 0 || sOnly > 0 || both > 0) {
        tableSummaries.add(ConflictDiffTableSummary(
          tableName: tableName,
          displayNameKey: displayNameKey,
          onlyOnThisDevice: tOnly,
          onlyOnServer: sOnly,
          changedOnBoth: both,
        ));
      }
    }

    return ConflictDiffSummary(
      rowsOnlyOnThisDevice: onlyOnThisDevice,
      rowsOnlyOnServer: onlyOnServer,
      rowsChangedOnBoth: changedOnBoth,
      tableSummaries: tableSummaries,
    );
  }

  /// Translation keys for each table's user-facing name.
  static const Map<String, String> _tableDisplayNameKeys = {
    'school_years_table': 'school_years',
    'groups_table': 'groups',
    'timeframes_table': 'timeframes',
    'students_table': 'students',
    'sessions_table': 'conflict_diff_lessons',
    'grade_entries_table': 'grades',
    'attendance_logs_table': 'attendance',
    'homework_logs_table': 'homework',
    'material_logs_table': 'conflict_diff_materials',
    'lesson_slots_table': 'conflict_diff_schedule',
    'lists_table': 'lists',
    'list_items_table': 'conflict_diff_list_items',
    'notes_table': 'notes',
    'seating_plans_table': 'seating_plans',
    'seating_plan_positions_table': 'conflict_diff_seating_positions',
    'student_relations_table': 'conflict_diff_seating_rules',
    'timeframe_grades_table': 'timeframe_grades',
  };

  List<String> _columnsFor(sqlite3.Database db, String tableName) {
    final result = db.select("PRAGMA table_info('$tableName')");
    return [
      for (final row in result)
        row['name'] as String,
    ];
  }

  Map<int, Map<String, dynamic>> _loadRows(
    sqlite3.Database db,
    String tableName,
  ) {
    final result = db.select('SELECT * FROM $tableName');
    final rows = <int, Map<String, dynamic>>{};
    for (final row in result) {
      final id = row['id'] as int;
      rows[id] = Map<String, dynamic>.from(row);
    }
    return rows;
  }

  bool _rowsEqual(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    List<String> columns,
  ) {
    for (final col in columns) {
      if (col == 'updated_at') continue;
      if (a[col] != b[col]) return false;
    }
    return true;
  }

  bool _tableExists(sqlite3.Database db, String tableName) {
    final result = db.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return result.isNotEmpty;
  }
}
