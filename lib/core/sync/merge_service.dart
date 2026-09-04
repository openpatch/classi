import 'dart:developer' as developer;

import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../database/encrypted_database_file.dart';

/// The outcome of a three-way merge: a summary of what changed and whether
/// any row-level conflicts were found that the merge could not resolve.
class MergeResult {
  MergeResult({
    this.tablesMerged = 0,
    this.rowsAdded = 0,
    this.rowsUpdated = 0,
    this.rowsDeleted = 0,
    List<MergeConflict>? conflicts,
  }) : conflicts = conflicts ?? [];

  /// Number of tables that were processed.
  int tablesMerged;

  /// Rows that existed in local or remote but not the base (new in one side).
  int rowsAdded;

  /// Rows whose content differs from the base (changed in one or both sides).
  int rowsUpdated;

  /// Rows that existed in the base but were removed in both local and remote.
  int rowsDeleted;

  /// Row-level conflicts the merge could not resolve automatically. Each
  /// entry names the table and the primary key of the conflicting row.
  /// When this is non-empty, the caller must decide how to handle them.
  final List<MergeConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// A single row that was changed on both sides since the merge base in ways
/// the last-write-wins heuristic cannot resolve (e.g. same updatedAt, or
/// the row was deleted on one side and modified on the other).
class MergeConflict {
  const MergeConflict({
    required this.tableName,
    required this.rowId,
    required this.description,
  });

  final String tableName;
  final int rowId;
  final String description;

  @override
  String toString() => '$tableName#$rowId: $description';
}

/// Thrown when the three snapshots handed to [MergeService.merge] were not
/// written at the same schema version. Merging across versions would write
/// rows shaped for one schema into another, so the merge refuses to start.
class MergeSchemaMismatch implements Exception {
  const MergeSchemaMismatch({
    required this.baseVersion,
    required this.localVersion,
    required this.remoteVersion,
  });

  final int baseVersion;
  final int localVersion;
  final int remoteVersion;

  @override
  String toString() =>
      'MergeSchemaMismatch: base v$baseVersion, local v$localVersion, '
      'remote v$remoteVersion';
}

/// Performs a three-way merge of two SQLite database snapshots against a
/// common base, using the `updated_at` column on each table to resolve
/// concurrent edits with last-write-wins per row.
///
/// The merge works on raw SQLite databases (not Drift objects) because the
/// remote and base snapshots are temporary files that exist only for the
/// duration of the merge. The local database is the one the app has open;
/// the merged result is written back into it.
///
/// All three databases must have the same schema (same tables, same columns).
/// The [MergeService] assumes the `updated_at` column exists on every table
/// (added in schema version 28).
class MergeService {
  /// Tables to merge, in dependency order (parents before children so that
  /// FK constraints are satisfied during the merge).
  static const List<String> _tableNames = [
    'school_years_table',
    'groups_table',
    'timeframes_table',
    'students_table',
    'sessions_table',
    'grade_entries_table',
    'attendance_logs_table',
    'homework_logs_table',
    'material_logs_table',
    'lesson_slots_table',
    'lists_table',
    'list_items_table',
    'notes_table',
    'seating_plans_table',
    'seating_plan_positions_table',
    'student_relations_table',
    'timeframe_grades_table',
  ];

  /// Merges [remotePath] and [localPath] against [basePath], writing the
  /// result into [localPath].
  ///
  /// [basePath] and [remotePath] are paths to SQLite database files. The
  /// [localPath] database is the one that will receive the merged result;
  /// it must be closed (or the merge must run on a copy) because the merge
  /// writes directly to it.
  ///
  /// Each snapshot carries its own security metadata and therefore its own
  /// SQLCipher key, so all three are passed separately. Pass `null` only for
  /// a plaintext file (test fixtures); a real library opened without its key
  /// fails on the first query.
  ///
  /// The write side runs in a single transaction: a merge that fails halfway
  /// would otherwise leave the library holding a mix of both versions with no
  /// way back.
  ///
  /// Returns a [MergeResult] summarizing the merge. If [MergeResult.hasConflicts]
  /// is true, the caller should surface them to the user for manual
  /// resolution.
  Future<MergeResult> merge({
    required String basePath,
    required String localPath,
    required String remotePath,
    required String? baseKey,
    required String? localKey,
    required String? remoteKey,
  }) async {
    final result = MergeResult();

    final base = openLibraryDatabaseFile(basePath, databaseKey: baseKey);
    final local = openLibraryDatabaseFile(localPath, databaseKey: localKey);
    final remote = openLibraryDatabaseFile(remotePath, databaseKey: remoteKey);

    try {
      _requireMatchingSchemas(base: base, local: local, remote: remote);

      local.execute('BEGIN IMMEDIATE');
      try {
        for (final tableName in _tableNames) {
          _mergeTable(
            base: base,
            local: local,
            remote: remote,
            tableName: tableName,
            result: result,
          );
        }
        local.execute('COMMIT');
      } on Object {
        local.execute('ROLLBACK');
        rethrow;
      }
    } finally {
      base.close();
      local.close();
      remote.close();
    }

    developer.log(
      'Merge complete: ${result.tablesMerged} tables, '
      '${result.rowsAdded} added, ${result.rowsUpdated} updated, '
      '${result.rowsDeleted} deleted, ${result.conflicts.length} conflicts',
      name: 'classi.merge',
    );

    return result;
  }

  /// Refuses to merge snapshots that were written at different schema
  /// versions.
  ///
  /// Column lists are read from the local database and applied to rows coming
  /// from the others. If a snapshot is older, its rows are missing columns
  /// the local schema requires and NULL gets written into `NOT NULL` columns;
  /// if it is newer, its extra columns are dropped on the floor. Both are
  /// silent data loss, so the merge stops instead and leaves the caller to
  /// bring the snapshots to a common version first.
  void _requireMatchingSchemas({
    required sqlite3.Database base,
    required sqlite3.Database local,
    required sqlite3.Database remote,
  }) {
    final localVersion = _schemaVersionOf(local);
    final baseVersion = _schemaVersionOf(base);
    final remoteVersion = _schemaVersionOf(remote);
    if (baseVersion != localVersion || remoteVersion != localVersion) {
      throw MergeSchemaMismatch(
        baseVersion: baseVersion,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
      );
    }
  }

  int _schemaVersionOf(sqlite3.Database db) {
    final rows = db.select('PRAGMA user_version');
    if (rows.isEmpty) return 0;
    final value = rows.first.values.first;
    return value is int ? value : 0;
  }

  void _mergeTable({
    required sqlite3.Database base,
    required sqlite3.Database local,
    required sqlite3.Database remote,
    required String tableName,
    required MergeResult result,
  }) {
    // Check that the table exists in all three databases.
    if (!_tableExists(base, tableName) ||
        !_tableExists(local, tableName) ||
        !_tableExists(remote, tableName)) {
      return;
    }
    result.tablesMerged++;

    final columns = _columnsFor(local, tableName);
    if (columns.isEmpty) return;

    final baseRows = _loadRows(base, tableName, columns);
    final localRows = _loadRows(local, tableName, columns);
    final remoteRows = _loadRows(remote, tableName, columns);

    final allIds = <int>{
      ...baseRows.keys,
      ...localRows.keys,
      ...remoteRows.keys,
    };

    for (final id in allIds) {
      final baseRow = baseRows[id];
      final localRow = localRows[id];
      final remoteRow = remoteRows[id];

      // Three-way comparison for this row.
      if (localRow != null && remoteRow != null) {
        // Row exists on both sides.
        if (baseRow == null) {
          // New on both sides — same ID, potentially different content.
          // This is a true conflict only if the content differs.
          if (_rowsEqual(localRow, remoteRow, columns)) {
            // Same content — no conflict, just take either.
            continue;
          }
          // Different content with the same ID. Try last-write-wins.
          final localTs = _updatedAtOf(localRow);
          final remoteTs = _updatedAtOf(remoteRow);
          if (localTs == remoteTs) {
            result.conflicts.add(MergeConflict(
              tableName: tableName,
              rowId: id,
              description: 'Row created on both sides with the same ID and '
                  'timestamp but different content',
            ));
            continue;
          }
          // Take the newer one.
          if (remoteTs > localTs) {
            _updateRow(local, tableName, columns, id, remoteRow);
            result.rowsUpdated++;
          }
          // Local is newer — already in place.
        } else {
          // Row existed in the base — compare changes.
          final baseTs = _updatedAtOf(baseRow);
          final localTs = _updatedAtOf(localRow);
          final remoteTs = _updatedAtOf(remoteRow);

          final localChanged = localTs != baseTs || !_rowsEqual(baseRow, localRow, columns);
          final remoteChanged = remoteTs != baseTs || !_rowsEqual(baseRow, remoteRow, columns);

          if (localChanged && remoteChanged) {
            // Changed on both sides — last-write-wins.
            if (localTs == remoteTs) {
              // Same timestamp — check if content is actually the same.
              if (_rowsEqual(localRow, remoteRow, columns)) {
                continue; // Same content, no conflict.
              }
              result.conflicts.add(MergeConflict(
                tableName: tableName,
                rowId: id,
                description: 'Row modified on both sides with the same '
                    'timestamp but different content',
              ));
              continue;
            }
            if (remoteTs > localTs) {
              _updateRow(local, tableName, columns, id, remoteRow);
              result.rowsUpdated++;
            }
            // Local is newer — already in place.
          } else if (remoteChanged) {
            // Only remote changed — take it.
            _updateRow(local, tableName, columns, id, remoteRow);
            result.rowsUpdated++;
          }
          // Only local changed or neither — local is already correct.
        }
      } else if (localRow == null && remoteRow != null) {
        // Row exists on remote but not local.
        if (baseRow != null) {
          // Existed in base, deleted on local. Check if remote changed it.
          final baseTs = _updatedAtOf(baseRow);
          final remoteTs = _updatedAtOf(remoteRow);
          if (remoteTs != baseTs || !_rowsEqual(baseRow, remoteRow, columns)) {
            // Deleted on local, modified on remote — conflict.
            result.conflicts.add(MergeConflict(
              tableName: tableName,
              rowId: id,
              description: 'Row deleted locally but modified remotely',
            ));
            continue;
          }
          // Deleted on local, unchanged on remote — the deletion wins.
          result.rowsDeleted++;
        } else {
          // New on remote — insert it.
          _insertRow(local, tableName, id, columns, remoteRow);
          result.rowsAdded++;
        }
      } else if (localRow != null && remoteRow == null) {
        // Row exists on local but not remote.
        if (baseRow != null) {
          // Existed in base, deleted on remote. Check if local changed it.
          final baseTs = _updatedAtOf(baseRow);
          final localTs = _updatedAtOf(localRow);
          if (localTs != baseTs || !_rowsEqual(baseRow, localRow, columns)) {
            // Deleted on remote, modified on local — keep local (the
            // modification wins over the deletion in LWW).
            continue;
          }
          // Deleted on remote, unchanged on local — the deletion wins.
          _deleteRow(local, tableName, id);
          result.rowsDeleted++;
        }
        // New on local — keep it (already in place).
      } else {
        // Row exists only in base — deleted on both sides. Nothing to do.
        result.rowsDeleted++;
      }
    }
  }

  /// Reads the column names (excluding `id` which is the PK) from the table.
  ///
  /// `id` is left out because it is what rows are matched on and must never
  /// be rewritten by an UPDATE. Inserts add it back explicitly — see
  /// [_insertRow].
  List<String> _columnsFor(sqlite3.Database db, String tableName) {
    final result = db.select("PRAGMA table_info('$tableName')");
    final cols = <String>[];
    for (final row in result) {
      final name = row['name'] as String;
      if (name != 'id') {
        cols.add(name);
      }
    }
    return cols;
  }

  /// Loads all rows from a table, keyed by primary key.
  Map<int, Map<String, dynamic>> _loadRows(
    sqlite3.Database db,
    String tableName,
    List<String> columns,
  ) {
    final result = db.select('SELECT * FROM $tableName');
    final rows = <int, Map<String, dynamic>>{};
    for (final row in result) {
      final id = row['id'] as int;
      rows[id] = Map<String, dynamic>.from(row);
    }
    return rows;
  }

  /// Extracts the `updated_at` timestamp from a row as an integer (seconds
  /// since epoch). Returns 0 if the column doesn't exist or is null.
  int _updatedAtOf(Map<String, dynamic> row) {
    final value = row['updated_at'];
    if (value == null) return 0;
    if (value is int) return value;
    return 0;
  }

  /// Compares two rows for equality across all columns except `updated_at`
  /// (which is a bookkeeping column, not user data).
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

  /// Inserts a row that exists on one side only, keeping its primary key.
  ///
  /// The `id` has to be carried over verbatim: every child table stores the
  /// parent's id, and those references are copied across by this same merge.
  /// Letting SQLite hand out a fresh autoincrement id here would silently
  /// repoint every one of them at a different row.
  void _insertRow(
    sqlite3.Database db,
    String tableName,
    int id,
    List<String> columns,
    Map<String, dynamic> row,
  ) {
    final insertColumns = ['id', ...columns];
    final colNames = insertColumns.join(', ');
    final placeholders = List.filled(insertColumns.length, '?').join(', ');
    final values = <Object?>[id, ...columns.map((c) => row[c])];
    db.execute(
      'INSERT INTO $tableName ($colNames) VALUES ($placeholders)',
      values,
    );
  }

  void _updateRow(
    sqlite3.Database db,
    String tableName,
    List<String> columns,
    int id,
    Map<String, dynamic> row,
  ) {
    final setClause = columns.map((c) => '$c = ?').join(', ');
    final values = columns.map((c) => row[c]).toList();
    values.add(id);
    db.execute(
      'UPDATE $tableName SET $setClause WHERE id = ?',
      values,
    );
  }

  void _deleteRow(sqlite3.Database db, String tableName, int id) {
    db.execute('DELETE FROM $tableName WHERE id = ?', [id]);
  }

  bool _tableExists(sqlite3.Database db, String tableName) {
    final result = db.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return result.isNotEmpty;
  }
}
