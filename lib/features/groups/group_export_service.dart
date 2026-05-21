import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/utils/grade_categories.dart';

/// Provides CSV export methods for a single group.
///
/// Each method returns the saved [File] so the caller can share it.
class GroupExportService {
  const GroupExportService(this._database);

  final AppDatabase _database;

  // ---------------------------------------------------------------------------
  // 1. Grades matrix: students × sessions → grade value
  // ---------------------------------------------------------------------------

  Future<File> exportGradesCsv({
    required int groupId,
    required String groupName,
  }) async {
    final group = await (_database.select(_database.groupsTable)
          ..where((t) => t.id.equals(groupId)))
        .getSingle();
    final students = await (_database.select(_database.studentsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.lastName),
            (t) => OrderingTerm.asc(t.firstName),
          ]))
        .get();
    final gradeEntries = await (_database.select(_database.gradeEntriesTable)
          ..where(
            (t) => t.studentId.isIn([for (final s in students) s.id]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    final categories = parseGradeCategories(group.gradeCategoriesJson);
    final scaleEntries = parseGradeScaleEntries(group.gradeScaleJson);

    // Build ordered list of unique session keys: (date, categoryId, label).
    final sessionKeys = <_SessionKey>[];
    final sessionKeySet = <String>{};
    for (final e in gradeEntries) {
      final key = _SessionKey(
        date: DateUtils.dateOnly(e.date),
        categoryId: e.categoryId,
        categoryName: e.categoryName,
        label: e.sessionLabel,
      );
      if (sessionKeySet.add(key.id)) {
        sessionKeys.add(key);
      }
    }
    sessionKeys.sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : a.categoryId.compareTo(b.categoryId);
    });

    // Index grades: studentId → sessionKey.id → grade label
    final gradeIndex = <int, Map<String, String>>{};
    for (final e in gradeEntries) {
      final key = _SessionKey(
        date: DateUtils.dateOnly(e.date),
        categoryId: e.categoryId,
        categoryName: e.categoryName,
        label: e.sessionLabel,
      );
      gradeIndex.putIfAbsent(e.studentId, () => {})[key.id] = e.value;
    }

    final dateFormat = DateFormat.yMd();
    final buf = StringBuffer();

    // Header
    buf.write('Name');
    for (final key in sessionKeys) {
      final label = key.label.isEmpty
          ? '${dateFormat.format(key.date)} (${key.categoryName})'
          : '${dateFormat.format(key.date)} ${key.label} (${key.categoryName})';
      buf.write(';${_escapeCsv(label)}');
    }
    buf.write(';Ø\n');

    // Rows
    for (final student in students) {
      final name = '${student.lastName}, ${student.firstName}';
      buf.write(_escapeCsv(name));

      final studentGrades = gradeIndex[student.id] ?? {};
      final gradeInputs = <({double value, String categoryId})>[];

      for (final key in sessionKeys) {
        final value = studentGrades[key.id] ?? '';
        buf.write(';${_escapeCsv(value)}');
        if (value.isNotEmpty) {
          final num = gradeValueToNumber(value, scaleEntries);
          if (num != null) {
            gradeInputs.add((value: num, categoryId: key.categoryId));
          }
        }
      }

      // Weighted average
      final avg = calculateWeightedAverage(gradeInputs, categories);
      buf.write(';${avg != null ? avg.toStringAsFixed(2) : ''}');
      buf.write('\n');
    }

    return _saveAndReturn(
      content: buf.toString(),
      filename: '${_sanitize(groupName)}_grades.csv',
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Attendance sheet: students × session dates
  // ---------------------------------------------------------------------------

  Future<File> exportAttendanceCsv({
    required int groupId,
    required String groupName,
  }) async {
    final students = await (_database.select(_database.studentsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.lastName),
            (t) => OrderingTerm.asc(t.firstName),
          ]))
        .get();
    final logs = await (_database.select(_database.attendanceLogsTable)
          ..where(
            (t) => t.studentId.isIn([for (final s in students) s.id]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    // Collect ordered unique dates
    final dates = <DateTime>[];
    final dateSet = <String>{};
    for (final l in logs) {
      final d = DateUtils.dateOnly(l.date);
      final key = d.toIso8601String();
      if (dateSet.add(key)) dates.add(d);
    }
    dates.sort();

    // Index: studentId → date key → (isAbsent, isExcused)
    final index = <int, Map<String, (bool, bool)>>{};
    for (final l in logs) {
      final d = DateUtils.dateOnly(l.date);
      index.putIfAbsent(l.studentId, () => {})[d.toIso8601String()] =
          (l.isAbsent, l.isExcused);
    }

    final dateFormat = DateFormat.yMd();
    final buf = StringBuffer();

    // Header
    buf.write('Name');
    for (final d in dates) {
      buf.write(';${dateFormat.format(d)}');
    }
    buf.write(';Absent;Excused;Rate %\n');

    // Rows
    for (final student in students) {
      final name = '${student.lastName}, ${student.firstName}';
      buf.write(_escapeCsv(name));

      final studentLog = index[student.id] ?? {};
      var absentCount = 0;
      var excusedCount = 0;

      for (final d in dates) {
        final entry = studentLog[d.toIso8601String()];
        if (entry == null) {
          buf.write(';✓');
        } else {
          final (isAbsent, isExcused) = entry;
          if (!isAbsent) {
            buf.write(';✓');
          } else if (isExcused) {
            buf.write(';E');
            absentCount++;
            excusedCount++;
          } else {
            buf.write(';A');
            absentCount++;
          }
        }
      }

      final rate = dates.isEmpty
          ? ''
          : (absentCount / dates.length * 100).toStringAsFixed(1);
      buf.write(';$absentCount;$excusedCount;$rate\n');
    }

    return _saveAndReturn(
      content: buf.toString(),
      filename: '${_sanitize(groupName)}_attendance.csv',
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Homework & material compliance
  // ---------------------------------------------------------------------------

  Future<File> exportHomeworkMaterialCsv({
    required int groupId,
    required String groupName,
  }) async {
    final students = await (_database.select(_database.studentsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.lastName),
            (t) => OrderingTerm.asc(t.firstName),
          ]))
        .get();
    final studentIds = [for (final s in students) s.id];

    final hwLogs = await (_database.select(_database.homeworkLogsTable)
          ..where((t) => t.studentId.isIn(studentIds))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    final matLogs = await (_database.select(_database.materialLogsTable)
          ..where((t) => t.studentId.isIn(studentIds))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    final dateFormat = DateFormat.yMd();
    final buf = StringBuffer();

    _writeComplianceSection(
      buf: buf,
      title: 'Homework',
      students: students,
      dates: _uniqueDates(hwLogs.map((e) => e.date)),
      index: _buildBoolIndex(
        hwLogs.map((l) => (l.studentId, l.date, l.hadHomework)),
      ),
      dateFormat: dateFormat,
    );

    buf.write('\n');

    _writeComplianceSection(
      buf: buf,
      title: 'Material',
      students: students,
      dates: _uniqueDates(matLogs.map((e) => e.date)),
      index: _buildBoolIndex(
        matLogs.map((l) => (l.studentId, l.date, l.hadMaterial)),
      ),
      dateFormat: dateFormat,
    );

    return _saveAndReturn(
      content: buf.toString(),
      filename: '${_sanitize(groupName)}_homework_material.csv',
    );
  }

  void _writeComplianceSection({
    required StringBuffer buf,
    required String title,
    required List<Student> students,
    required List<DateTime> dates,
    required Map<int, Map<String, bool>> index,
    required DateFormat dateFormat,
  }) {
    buf.write(title);
    for (final d in dates) {
      buf.write(';${dateFormat.format(d)}');
    }
    buf.write(';Rate %\n');

    for (final student in students) {
      final name = '${student.lastName}, ${student.firstName}';
      buf.write(_escapeCsv(name));

      final studentLog = index[student.id] ?? {};
      var doneCount = 0;

      for (final d in dates) {
        final done = studentLog[d.toIso8601String()];
        if (done == null) {
          buf.write(';');
        } else {
          buf.write(done ? ';✓' : ';✗');
          if (done) doneCount++;
        }
      }

      final rate = dates.isEmpty
          ? ''
          : (doneCount / dates.length * 100).toStringAsFixed(1);
      buf.write(';$rate\n');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Full student summary (flat)
  // ---------------------------------------------------------------------------

  Future<File> exportSummaryCsv({
    required int groupId,
    required String groupName,
  }) async {
    final group = await (_database.select(_database.groupsTable)
          ..where((t) => t.id.equals(groupId)))
        .getSingle();
    final students = await (_database.select(_database.studentsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.lastName),
            (t) => OrderingTerm.asc(t.firstName),
          ]))
        .get();
    final studentIds = [for (final s in students) s.id];

    final categories = parseGradeCategories(group.gradeCategoriesJson);
    final scaleEntries = parseGradeScaleEntries(group.gradeScaleJson);

    final gradeEntries = await (_database.select(_database.gradeEntriesTable)
          ..where((t) => t.studentId.isIn(studentIds)))
        .get();
    final absenceLogs = await (_database.select(_database.attendanceLogsTable)
          ..where(
            (t) =>
                t.studentId.isIn(studentIds) & t.isAbsent.equals(true),
          ))
        .get();
    final homeworkLogs = await (_database.select(_database.homeworkLogsTable)
          ..where((t) => t.studentId.isIn(studentIds)))
        .get();
    final materialLogs = await (_database.select(_database.materialLogsTable)
          ..where((t) => t.studentId.isIn(studentIds)))
        .get();

    // Group by student
    final gradesByStudent = <int, List<GradeEntry>>{};
    for (final g in gradeEntries) {
      gradesByStudent.putIfAbsent(g.studentId, () => []).add(g);
    }
    final absencesByStudent = <int, List<AttendanceLog>>{};
    for (final a in absenceLogs) {
      absencesByStudent.putIfAbsent(a.studentId, () => []).add(a);
    }
    final homeworkByStudent = <int, List<HomeworkLog>>{};
    for (final h in homeworkLogs) {
      homeworkByStudent.putIfAbsent(h.studentId, () => []).add(h);
    }
    final materialByStudent = <int, List<MaterialLog>>{};
    for (final m in materialLogs) {
      materialByStudent.putIfAbsent(m.studentId, () => []).add(m);
    }

    final buf = StringBuffer();

    // Header
    buf.write('Name');
    for (final cat in categories) {
      buf.write(';Ø ${_escapeCsv(cat.name)}');
    }
    buf.write(';Ø Total;Absences;Excused;HW rate %;Material rate %\n');

    // Rows
    for (final student in students) {
      final name = '${student.lastName}, ${student.firstName}';
      buf.write(_escapeCsv(name));

      final grades = gradesByStudent[student.id] ?? [];
      final absences = absencesByStudent[student.id] ?? [];
      final homework = homeworkByStudent[student.id] ?? [];
      final material = materialByStudent[student.id] ?? [];

      // Per-category averages
      final allGradeInputs = <({double value, String categoryId})>[];
      for (final cat in categories) {
        final catGrades =
            grades.where((g) => g.categoryId == cat.id).toList();
        final inputs = <({double value, String categoryId})>[];
        for (final g in catGrades) {
          final num = gradeValueToNumber(g.value, scaleEntries);
          if (num != null) inputs.add((value: num, categoryId: g.categoryId));
        }
        allGradeInputs.addAll(inputs);
        final avg = calculateWeightedAverage(inputs, categories);
        buf.write(';${avg != null ? avg.toStringAsFixed(2) : ''}');
      }

      // Weighted total average
      final total = calculateWeightedAverage(allGradeInputs, categories);
      buf.write(';${total != null ? total.toStringAsFixed(2) : ''}');

      // Absences
      final absentCount = absences.length;
      final excusedCount = absences.where((a) => a.isExcused).length;
      buf.write(';$absentCount;$excusedCount');

      // Homework rate
      final hwTotal = homework.length;
      final hwDone = homework.where((h) => h.hadHomework).length;
      buf.write(
        ';${hwTotal > 0 ? (hwDone / hwTotal * 100).toStringAsFixed(1) : ''}',
      );

      // Material rate
      final matTotal = material.length;
      final matDone = material.where((m) => m.hadMaterial).length;
      buf.write(
        ';${matTotal > 0 ? (matDone / matTotal * 100).toStringAsFixed(1) : ''}',
      );

      buf.write('\n');
    }

    return _saveAndReturn(
      content: buf.toString(),
      filename: '${_sanitize(groupName)}_summary.csv',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<File> _saveAndReturn({
    required String content,
    required String filename,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    // UTF-8 BOM for Excel compatibility.
    final bom = [0xEF, 0xBB, 0xBF];
    await file.writeAsBytes([...bom, ...utf8.encode(content)]);
    return file;
  }

  List<DateTime> _uniqueDates(Iterable<DateTime> raw) {
    final seen = <String>{};
    final result = <DateTime>[];
    for (final d in raw) {
      final normalized = DateUtils.dateOnly(d);
      if (seen.add(normalized.toIso8601String())) result.add(normalized);
    }
    result.sort();
    return result;
  }

  String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Map<int, Map<String, bool>> _buildBoolIndex(
    Iterable<(int studentId, DateTime date, bool value)> entries,
  ) {
    final result = <int, Map<String, bool>>{};
    for (final (studentId, date, value) in entries) {
      result
          .putIfAbsent(studentId, () => {})[
              DateUtils.dateOnly(date).toIso8601String()] =
          value;
    }
    return result;
  }

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^\w\-]'), '_').replaceAll(RegExp(r'_+'), '_');
}

// Helper record for a unique session key.
class _SessionKey {
  _SessionKey({
    required this.date,
    required this.categoryId,
    required this.categoryName,
    required this.label,
  });

  final DateTime date;
  final String categoryId;
  final String categoryName;
  final String label;

  String get id => '${date.toIso8601String()}|$categoryId|$label';
}

/// Shares [file] on platforms that support a share sheet, otherwise just
/// keeps the saved file.
Future<void> shareOrSaveFile({
  required File file,
  required String mimeType,
  String? subject,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: subject,
      ),
    );
  }
  // On desktop the file is already saved; nothing more to do.
}
