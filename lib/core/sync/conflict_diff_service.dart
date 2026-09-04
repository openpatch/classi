import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// A summary of what differs between two backup archives, shown on the
/// conflict resolution screen to help the user pick a side.
class ConflictDiffSummary {
  ConflictDiffSummary({
    this.rowsOnlyOnThisDevice = 0,
    this.rowsOnlyOnServer = 0,
    this.rowsChangedOnThisDevice = 0,
    this.rowsChangedOnServer = 0,
    this.rowsChangedOnBoth = 0,
    this.tableSummaries = const [],
  });

  /// Rows that exist only in this device's version (new or added locally).
  final int rowsOnlyOnThisDevice;

  /// Rows that exist only in the server's version (new or added remotely).
  final int rowsOnlyOnServer;

  /// Rows that differ from the common state on this device only.
  final int rowsChangedOnThisDevice;

  /// Rows that differ from the common state on the server only.
  final int rowsChangedOnServer;

  /// Rows that were changed on both sides (potential conflicts).
  final int rowsChangedOnBoth;

  /// Per-table breakdown of the differences.
  final List<ConflictDiffTableSummary> tableSummaries;

  /// Whether the changes are non-overlapping (safe to auto-merge).
  bool get canAutoMerge => rowsChangedOnBoth == 0;

  /// Total number of differing rows across all tables.
  int get totalDifferences =>
      rowsOnlyOnThisDevice +
      rowsOnlyOnServer +
      rowsChangedOnThisDevice +
      rowsChangedOnServer +
      rowsChangedOnBoth;
}

/// Per-table breakdown of differences between two backup versions.
class ConflictDiffTableSummary {
  const ConflictDiffTableSummary({
    required this.tableName,
    required this.displayName,
    required this.onlyOnThisDevice,
    required this.onlyOnServer,
    required this.changedOnThisDevice,
    required this.changedOnServer,
    required this.changedOnBoth,
  });

  final String tableName;

  /// A human-readable name for the table, e.g. "Students" for
  /// `students_table`.
  final String displayName;

  final int onlyOnThisDevice;
  final int onlyOnServer;
  final int changedOnThisDevice;
  final int changedOnServer;
  final int changedOnBoth;

  bool get hasDifferences =>
      onlyOnThisDevice > 0 ||
      onlyOnServer > 0 ||
      changedOnThisDevice > 0 ||
      changedOnServer > 0 ||
      changedOnBoth > 0;
}

/// Compares two backup archives and produces a summary of what differs.
///
/// The comparison works by restoring both archives into in-memory SQLite
/// databases and comparing row-by-row across every table. It does not need
/// a merge base — it's a direct two-way comparison, which is what the user
/// sees on the conflict screen.
class ConflictDiffService {
  /// Compares [thisDeviceBytes] (the conflict copy) against
  /// [serverBytes] (the canonical backup) and returns a summary.
  ///
  /// Both are `.classi-backup` ZIP archives containing a `data.db` SQLite
  /// file. The comparison loads both into memory, so it should not be used
  /// for very large libraries.
  ConflictDiffSummary compare({
    required Uint8List thisDeviceBytes,
    required Uint8List serverBytes,
  }) {
    final thisDeviceDb = _extractDatabase(thisDeviceBytes);
    final serverDb = _extractDatabase(serverBytes);

    try {
      return _compareDatabases(thisDeviceDb, serverDb);
    } finally {
      thisDeviceDb.close();
      serverDb.close();
    }
  }

  sqlite3.Database _extractDatabase(Uint8List archiveBytes) {
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final dbFile = archive.findFile('data.db');
    if (dbFile == null) {
      throw StateError('Backup archive does not contain data.db');
    }
    final dbBytes = Uint8List.fromList(dbFile.content as List<int>);

    // Write to a temp file because sqlite3 can't open from bytes directly.
    final tempPath = '${Directory.systemTemp.path}/conflict-diff-${DateTime.now().microsecondsSinceEpoch}.db';
    File(tempPath).writeAsBytesSync(dbBytes);
    final db = sqlite3.sqlite3.open(tempPath);
    // Clean up the temp file after opening; SQLite has already read the
    // header and the database is now in memory via the page cache.
    File(tempPath).deleteSync();
    return db;
  }

  ConflictDiffSummary _compareDatabases(
    sqlite3.Database thisDevice,
    sqlite3.Database server,
  ) {
    var onlyOnThisDevice = 0;
    var onlyOnServer = 0;
    var changedOnThisDevice = 0;
    var changedOnServer = 0;
    var changedOnBoth = 0;
    final tableSummaries = <ConflictDiffTableSummary>[];

    for (final entry in _tableDisplayNames.entries) {
      final tableName = entry.key;
      final displayName = entry.value;

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
      var tChanged = 0;
      var sChanged = 0;
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

      // For tables where both rows exist and differ, we count them as
      // "changed on both" since we don't have a base. This is conservative
      // — some of these might be one-sided changes — but it's the safe
      // classification for the UI.
      tChanged = 0;
      sChanged = 0;

      if (tOnly > 0 || sOnly > 0 || both > 0) {
        tableSummaries.add(ConflictDiffTableSummary(
          tableName: tableName,
          displayName: displayName,
          onlyOnThisDevice: tOnly,
          onlyOnServer: sOnly,
          changedOnThisDevice: tChanged,
          changedOnServer: sChanged,
          changedOnBoth: both,
        ));
      }
    }

    return ConflictDiffSummary(
      rowsOnlyOnThisDevice: onlyOnThisDevice,
      rowsOnlyOnServer: onlyOnServer,
      rowsChangedOnThisDevice: changedOnThisDevice,
      rowsChangedOnServer: changedOnServer,
      rowsChangedOnBoth: changedOnBoth,
      tableSummaries: tableSummaries,
    );
  }

  static const Map<String, String> _tableDisplayNames = {
    'school_years_table': 'School Years',
    'groups_table': 'Groups',
    'timeframes_table': 'Timeframes',
    'students_table': 'Students',
    'sessions_table': 'Lessons',
    'grade_entries_table': 'Grades',
    'attendance_logs_table': 'Attendance',
    'homework_logs_table': 'Homework',
    'material_logs_table': 'Materials',
    'lesson_slots_table': 'Schedule',
    'lists_table': 'Lists',
    'list_items_table': 'List Items',
    'notes_table': 'Notes',
    'seating_plans_table': 'Seating Plans',
    'seating_plan_positions_table': 'Seating Positions',
    'student_relations_table': 'Seating Rules',
    'timeframe_grades_table': 'Timeframe Grades',
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
