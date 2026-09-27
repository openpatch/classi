import 'package:archive/archive.dart';
import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_export_service.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:classi/shared/utils/grade_categories.dart';
import 'package:classi/shared/utils/ods_writer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupExportService service;
  late int groupId;
  late int adaId;
  late int alanId;

  final monday = DateTime(2026, 9, 7);

  setUp(() async {
    database = AppDatabase.test(NativeDatabase.memory());
    service = GroupExportService(database);
    groupId = await GroupRepository(database).createGroup(
      name: '10A',
      colorHex: '#FF3949AB',
      gradeScale: defaultGradeScaleEntries,
      gradeCategories: const [
        GradeCategory(
          id: 'written',
          name: 'Written',
          weight: 1,
          colorHex: '#FF1E88E5',
        ),
        GradeCategory(
          id: 'test',
          name: 'Test',
          weight: 1,
          colorHex: '#FF8E24AA',
          parentId: 'written',
        ),
        GradeCategory(
          id: 'oral',
          name: 'Oral',
          weight: 1,
          colorHex: '#FF00897B',
        ),
      ],
    );
    final students = StudentRepository(database);
    adaId = await students.addStudent(
      groupId: groupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    alanId = await students.addStudent(
      groupId: groupId,
      firstName: 'Alan',
      lastName: 'Turing',
    );

    Future<void> grade(int studentId, String categoryId, String value) =>
        database
            .into(database.gradeEntriesTable)
            .insert(
              GradeEntriesTableCompanion.insert(
                studentId: studentId,
                date: monday,
                sessionLabel: 'Fractions',
                value: value,
                categoryId: Value(categoryId),
                categoryName: Value(categoryId),
              ),
            );
    await grade(adaId, 'test', '1');
    await grade(adaId, 'oral', '3');
    await grade(alanId, 'oral', '2');

    for (final period in [1, 5]) {
      await database
          .into(database.attendanceLogsTable)
          .insert(
            AttendanceLogsTableCompanion.insert(
              studentId: adaId,
              date: monday,
              periodStart: Value(period),
              isAbsent: const Value(false),
            ),
          );
    }
    await database
        .into(database.attendanceLogsTable)
        .insert(
          AttendanceLogsTableCompanion.insert(
            studentId: alanId,
            date: monday,
            periodStart: const Value(5),
            isAbsent: const Value(true),
            isExcused: const Value(true),
          ),
        );
  });

  tearDown(() => database.close());

  List<String> texts(List<OdsCell> row) => [
    for (final cell in row)
      switch (cell) {
        OdsText(:final value) => value,
        OdsNumber(:final value) => '$value',
        OdsPercent(:final value) => '${(value * 100).round()}%',
        OdsEmpty() => '',
      },
  ];

  test('writes a sheet each for grades, attendance, homework, material '
      'and the summary', () async {
    final sheets = await service.buildGroupSheets(groupId);

    expect(sheets.map((s) => s.name), [
      'grades',
      'attendance',
      'homework',
      'material',
      'export_summary_sheet',
    ]);

    final grades = sheets[0].rows;
    expect(grades.first.first, isA<OdsText>());
    expect(texts(grades[1]).first, 'Lovelace, Ada');
    // Ada: Written (only Test, 1) and Oral 3 weigh equally.
    expect(texts(grades[1]).last, '2.0');
    expect(texts(grades[2]).last, '2.0');
  });

  test('keeps two lessons of one day apart in the attendance sheet', () async {
    final attendance = (await service.buildGroupSheets(groupId))[1].rows;

    expect(attendance.first.length, 1 + 2 + 4);
    expect(texts(attendance[2]), [
      'Turing, Alan',
      '✓',
      'export_code_excused',
      '1.0',
      '1.0',
      '0.0',
      '50%',
    ]);
  });

  test('sums up parent categories in the summary', () async {
    final summary = (await service.buildGroupSheets(groupId))[4].rows;

    expect(texts(summary.first).take(5), [
      'name',
      'Ø Written',
      'Ø Written › Test',
      'Ø Oral',
      'Ø average',
    ]);
    expect(texts(summary[1]).sublist(1, 5), ['1.0', '1.0', '3.0', '2.0']);
  });

  test('encodes the sheets as an .ods file', () async {
    final bytes = await service.buildGroupSpreadsheet(groupId);
    final archive = ZipDecoder().decodeBytes(bytes);

    expect(archive.files.first.name, 'mimetype');
    expect(archive.findFile('content.xml'), isNotNull);
  });
}
