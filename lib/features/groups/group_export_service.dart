import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/ods_writer.dart';
import '../attendance/attendance_statistics.dart';

/// Exports a group as one OpenDocument spreadsheet (`.ods`) with a sheet
/// each for grades, attendance, homework, material and a summary per
/// student.
class GroupExportService {
  const GroupExportService(this._database, {String Function(String)? translate})
    : _translate = translate ?? _untranslated;

  final AppDatabase _database;

  /// Looks up the text for a translation key, for sheet names and headers.
  final String Function(String key) _translate;

  static String _untranslated(String key) => key;

  Future<({File file, String filename})> exportGroupOds({
    required int groupId,
    required String groupName,
  }) async {
    final bytes = await buildGroupSpreadsheet(groupId);
    final dir = await getTemporaryDirectory();
    final filename = '${_sanitize(groupName)}.ods';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return (file: file, filename: filename);
  }

  /// The spreadsheet [exportGroupOds] writes, as bytes.
  Future<Uint8List> buildGroupSpreadsheet(int groupId) async {
    return encodeOds(await buildGroupSheets(groupId));
  }

  /// The sheets of the export, before they are written out.
  Future<List<OdsSheet>> buildGroupSheets(int groupId) async {
    final data = await _load(groupId);
    return [
      _gradesSheet(data),
      _attendanceSheet(data),
      _complianceSheet(
        data,
        name: _translate('homework'),
        logs: [
          for (final log in data.homework)
            (
              studentId: log.studentId,
              date: log.date,
              periodStart: log.periodStart,
              done: log.hadHomework,
            ),
        ],
      ),
      _complianceSheet(
        data,
        name: _translate('material'),
        logs: [
          for (final log in data.material)
            (
              studentId: log.studentId,
              date: log.date,
              periodStart: log.periodStart,
              done: log.hadMaterial,
            ),
        ],
      ),
      _summarySheet(data),
    ];
  }

  Future<_ExportData> _load(int groupId) async {
    final group = await (_database.select(
      _database.groupsTable,
    )..where((t) => t.id.equals(groupId))).getSingle();
    final students =
        await (_database.select(_database.studentsTable)
              ..where((t) => t.groupId.equals(groupId))
              ..orderBy([
                (t) => OrderingTerm.asc(t.lastName),
                (t) => OrderingTerm.asc(t.firstName),
              ]))
            .get();
    final studentIds = [for (final s in students) s.id];

    return _ExportData(
      students: students,
      categories: parseGradeCategories(group.gradeCategoriesJson),
      scale: parseGradeScaleEntries(group.gradeScaleJson),
      grades:
          await (_database.select(_database.gradeEntriesTable)
                ..where((t) => t.studentId.isIn(studentIds))
                ..orderBy([(t) => OrderingTerm.asc(t.date)]))
              .get(),
      attendance:
          await (_database.select(_database.attendanceLogsTable)
                ..where((t) => t.studentId.isIn(studentIds))
                ..orderBy([(t) => OrderingTerm.asc(t.date)]))
              .get(),
      homework:
          await (_database.select(_database.homeworkLogsTable)
                ..where((t) => t.studentId.isIn(studentIds))
                ..orderBy([(t) => OrderingTerm.asc(t.date)]))
              .get(),
      material:
          await (_database.select(_database.materialLogsTable)
                ..where((t) => t.studentId.isIn(studentIds))
                ..orderBy([(t) => OrderingTerm.asc(t.date)]))
              .get(),
    );
  }

  // ---------------------------------------------------------------------------
  // Grades: students × graded sessions, with the weighted average
  // ---------------------------------------------------------------------------

  OdsSheet _gradesSheet(_ExportData data) {
    final sessionKeys = <_SessionKey>[];
    final seen = <String>{};
    final gradeIndex = <int, Map<String, String>>{};
    for (final entry in data.grades) {
      final key = _SessionKey(
        date: DateUtils.dateOnly(entry.date),
        categoryId: entry.categoryId,
        categoryName: entry.categoryName,
        label: entry.sessionLabel,
      );
      if (seen.add(key.id)) sessionKeys.add(key);
      gradeIndex.putIfAbsent(entry.studentId, () => {})[key.id] = entry.value;
    }
    sessionKeys.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.categoryId.compareTo(b.categoryId);
    });

    final dateFormat = DateFormat.yMd();
    final rows = <List<OdsCell>>[
      [
        OdsCell.text(_translate('name'), bold: true),
        for (final key in sessionKeys)
          OdsCell.text(
            [
              dateFormat.format(key.date),
              if (key.label.isNotEmpty) key.label,
              '(${_categoryName(key.categoryId, key.categoryName, data.categories)})',
            ].join(' '),
            bold: true,
          ),
        OdsCell.text('Ø', bold: true),
      ],
    ];

    for (final student in data.students) {
      final studentGrades = gradeIndex[student.id] ?? const {};
      final values = <String, List<double>>{};
      final row = <OdsCell>[OdsCell.text(_name(student))];
      for (final key in sessionKeys) {
        final value = studentGrades[key.id];
        row.add(value == null ? const OdsCell.empty() : _gradeCell(value));
        final number = value == null
            ? null
            : gradeValueToNumber(value, data.scale);
        if (number != null) {
          values.putIfAbsent(key.categoryId, () => []).add(number);
        }
      }
      final average = calculateWeightedAverage(
        _categoryMeans(values),
        data.categories,
      );
      row.add(_averageCell(average));
      rows.add(row);
    }

    return OdsSheet(name: _translate('grades'), rows: rows);
  }

  // ---------------------------------------------------------------------------
  // Attendance: students × lessons held
  // ---------------------------------------------------------------------------

  OdsSheet _attendanceSheet(_ExportData data) {
    final lessons = _lessons(
      data.attendance.map((log) => (log.date, log.periodStart)),
    );
    final index = <int, Map<_Lesson, AttendanceLog>>{};
    for (final log in data.attendance) {
      index.putIfAbsent(
        log.studentId,
        () => {},
      )[_lessonOf(log.date, log.periodStart)] = log;
    }
    final stats = {
      for (final student in computeGroupAttendanceStats(
        studentIds: [for (final s in data.students) s.id],
        logs: data.attendance,
      ).students)
        student.studentId: student,
    };

    final rows = <List<OdsCell>>[
      [
        OdsCell.text(_translate('name'), bold: true),
        for (final lesson in lessons)
          OdsCell.text(_lessonLabel(lesson), bold: true),
        OdsCell.text(_translate('absent'), bold: true),
        OdsCell.text(_translate('excused'), bold: true),
        OdsCell.text(_translate('late'), bold: true),
        OdsCell.text(_translate('attendance_rate'), bold: true),
      ],
    ];

    for (final student in data.students) {
      final logs = index[student.id] ?? const {};
      final studentStats = stats[student.id]!;
      rows.add([
        OdsCell.text(_name(student)),
        for (final lesson in lessons)
          OdsCell.text(switch (logs[lesson]) {
            AttendanceLog(isAbsent: true, isExcused: true) => _translate(
              'export_code_excused',
            ),
            AttendanceLog(isAbsent: true) => _translate('export_code_absent'),
            AttendanceLog(isLate: true) => _translate('export_code_late'),
            _ => '✓',
          }),
        OdsCell.number(studentStats.absent.toDouble()),
        OdsCell.number(studentStats.excused.toDouble()),
        OdsCell.number(studentStats.late.toDouble()),
        switch (studentStats.attendanceRate) {
          final rate? => OdsCell.percent(rate),
          null => const OdsCell.empty(),
        },
      ]);
    }

    return OdsSheet(name: _translate('attendance'), rows: rows);
  }

  // ---------------------------------------------------------------------------
  // Homework and material: students × lessons they were checked in
  // ---------------------------------------------------------------------------

  OdsSheet _complianceSheet(
    _ExportData data, {
    required String name,
    required List<({int studentId, DateTime date, int periodStart, bool done})>
    logs,
  }) {
    final lessons = _lessons(logs.map((log) => (log.date, log.periodStart)));
    final index = <int, Map<_Lesson, bool>>{};
    for (final log in logs) {
      index.putIfAbsent(
        log.studentId,
        () => {},
      )[_lessonOf(log.date, log.periodStart)] = log.done;
    }

    final rows = <List<OdsCell>>[
      [
        OdsCell.text(_translate('name'), bold: true),
        for (final lesson in lessons)
          OdsCell.text(_lessonLabel(lesson), bold: true),
        OdsCell.text('%', bold: true),
      ],
    ];

    for (final student in data.students) {
      final studentLogs = index[student.id] ?? const {};
      var checked = 0;
      var done = 0;
      final row = <OdsCell>[OdsCell.text(_name(student))];
      for (final lesson in lessons) {
        final value = studentLogs[lesson];
        if (value == null) {
          row.add(const OdsCell.empty());
          continue;
        }
        checked++;
        if (value) done++;
        row.add(OdsCell.text(value ? '✓' : '✗'));
      }
      row.add(
        checked == 0 ? const OdsCell.empty() : OdsCell.percent(done / checked),
      );
      rows.add(row);
    }

    return OdsSheet(name: name, rows: rows);
  }

  // ---------------------------------------------------------------------------
  // Summary: one row per student
  // ---------------------------------------------------------------------------

  OdsSheet _summarySheet(_ExportData data) {
    final gradesByStudent = <int, Map<String, List<double>>>{};
    for (final entry in data.grades) {
      final number = gradeValueToNumber(entry.value, data.scale);
      if (number == null) continue;
      gradesByStudent
          .putIfAbsent(entry.studentId, () => {})
          .putIfAbsent(entry.categoryId, () => [])
          .add(number);
    }
    final attendance = {
      for (final student in computeGroupAttendanceStats(
        studentIds: [for (final s in data.students) s.id],
        logs: data.attendance,
      ).students)
        student.studentId: student,
    };

    final rows = <List<OdsCell>>[
      [
        OdsCell.text(_translate('name'), bold: true),
        for (final category in data.categories)
          OdsCell.text(
            'Ø ${categoryPathName(category, data.categories)}',
            bold: true,
          ),
        OdsCell.text('Ø ${_translate('average')}', bold: true),
        OdsCell.text(_translate('absent'), bold: true),
        OdsCell.text(_translate('excused'), bold: true),
        OdsCell.text(_translate('late'), bold: true),
        OdsCell.text(_translate('attendance_rate'), bold: true),
        OdsCell.text('${_translate('homework')} %', bold: true),
        OdsCell.text('${_translate('material')} %', bold: true),
      ],
    ];

    for (final student in data.students) {
      final means = _categoryMeans(gradesByStudent[student.id] ?? const {});
      final meanByCategory = {
        for (final mean in means) mean.categoryId: mean.value,
      };
      final stats = attendance[student.id]!;
      final homework = data.homework.where((h) => h.studentId == student.id);
      final material = data.material.where((m) => m.studentId == student.id);

      rows.add([
        OdsCell.text(_name(student)),
        for (final category in data.categories)
          _averageCell(
            isParentCategory(category.id, data.categories)
                ? parentCategoryAverage(category.id, means, data.categories)
                : meanByCategory[category.id],
          ),
        _averageCell(calculateWeightedAverage(means, data.categories)),
        OdsCell.number(stats.absent.toDouble()),
        OdsCell.number(stats.excused.toDouble()),
        OdsCell.number(stats.late.toDouble()),
        switch (stats.attendanceRate) {
          final rate? => OdsCell.percent(rate),
          null => const OdsCell.empty(),
        },
        _rateCell(homework.length, homework.where((h) => h.hadHomework).length),
        _rateCell(material.length, material.where((m) => m.hadMaterial).length),
      ]);
    }

    return OdsSheet(name: _translate('export_summary_sheet'), rows: rows);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<({double value, String categoryId})> _categoryMeans(
    Map<String, List<double>> values,
  ) => [
    for (final entry in values.entries)
      (
        value: entry.value.reduce((a, b) => a + b) / entry.value.length,
        categoryId: entry.key,
      ),
  ];

  static String _categoryName(
    String categoryId,
    String fallbackName,
    List<GradeCategory> categories,
  ) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return categoryPathName(category, categories);
      }
    }
    return fallbackName;
  }

  /// A grade as a number when its label is one ("2", "13"), so the teacher
  /// can calculate with it, and as text otherwise ("2+").
  static OdsCell _gradeCell(String value) {
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    return number == null ? OdsCell.text(value) : OdsCell.number(number);
  }

  static OdsCell _averageCell(double? value) => value == null
      ? const OdsCell.empty()
      : OdsCell.number(value, decimals: 2);

  static OdsCell _rateCell(int total, int done) =>
      total == 0 ? const OdsCell.empty() : OdsCell.percent(done / total);

  static String _name(Student student) =>
      '${student.lastName}, ${student.firstName}';

  static _Lesson _lessonOf(DateTime date, int periodStart) =>
      (DateUtils.dateOnly(date), periodStart);

  static List<_Lesson> _lessons(Iterable<(DateTime, int)> raw) {
    final lessons =
        {for (final (date, period) in raw) _lessonOf(date, period)}.toList()
          ..sort((a, b) {
            final byDate = a.$1.compareTo(b.$1);
            return byDate != 0 ? byDate : a.$2.compareTo(b.$2);
          });
    return lessons;
  }

  static String _lessonLabel(_Lesson lesson) {
    final date = DateFormat.yMd().format(lesson.$1);
    return lesson.$2 == 0 ? date : '$date (${lesson.$2}.)';
  }

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^\w\-]'), '_').replaceAll(RegExp(r'_+'), '_');
}

/// A lesson as attendance, homework and material are kept: the day and the
/// period it starts in, 0 for a whole-day entry.
typedef _Lesson = (DateTime, int);

class _ExportData {
  const _ExportData({
    required this.students,
    required this.categories,
    required this.scale,
    required this.grades,
    required this.attendance,
    required this.homework,
    required this.material,
  });

  final List<Student> students;
  final List<GradeCategory> categories;
  final List<GradeScaleEntry> scale;
  final List<GradeEntry> grades;
  final List<AttendanceLog> attendance;
  final List<HomeworkLog> homework;
  final List<MaterialLog> material;
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

/// Delivers [file] to the user.
///
/// On Android/iOS shows a share sheet so the user can pick the destination.
/// On desktop, [savePathResolver] is called to obtain the target path
/// (e.g. via a FilePicker dialog). If it returns `null` the export is
/// cancelled and this function returns `false`.
Future<bool> shareOrSaveFile({
  required File file,
  required String filename,
  required String mimeType,
  String? subject,

  /// Called on desktop to resolve where the user wants to save the file.
  /// Should open a save-file dialog and return the chosen path, or null.
  Future<String?> Function()? savePathResolver,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: subject,
      ),
    );
    return true;
  }

  // Desktop: ask the caller for a save path.
  final savePath = savePathResolver != null ? await savePathResolver() : null;
  if (savePath == null) return false; // user cancelled or no resolver

  final bytes = await file.readAsBytes();
  await File(savePath).writeAsBytes(bytes);
  return true;
}
