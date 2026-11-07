import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/exams/data/exam_repository.dart';
import 'package:classi/features/exams/domain/exam_diff.dart';
import 'package:classi/features/exams/domain/exam_structure.dart';
import 'package:classi/features/exams/domain/grade_scheme.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _scheme = GradeScheme(
  thresholds: [
    GradeThreshold(label: '1', minPercent: 87),
    GradeThreshold(label: '2', minPercent: 73),
    GradeThreshold(label: '3', minPercent: 59),
    GradeThreshold(label: '4', minPercent: 45),
    GradeThreshold(label: '5', minPercent: 18),
    GradeThreshold(label: '6', minPercent: 0),
  ],
);

void main() {
  late AppDatabase database;
  late ExamRepository exams;
  late int groupId;
  late int ada;
  late int grace;

  setUp(() async {
    database = AppDatabase.test(NativeDatabase.memory());
    exams = ExamRepository(database);
    groupId = await GroupRepository(
      database,
    ).createGroup(name: '8a', gradeScale: defaultGradeScaleEntries);
    final students = StudentRepository(database);
    ada = await students.addStudent(
      groupId: groupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    grace = await students.addStudent(
      groupId: groupId,
      firstName: 'Grace',
      lastName: 'Hopper',
    );
  });

  tearDown(() => database.close());

  Future<int> createExam() => exams.createExam(
    groupId: groupId,
    title: 'Klassenarbeit 1',
    date: DateTime(2026, 11, 3, 14, 30),
    categoryId: 'klassenarbeit',
    categoryName: 'Klassenarbeit',
    scheme: _scheme,
  );

  Future<List<GradeEntry>> gradeEntries() =>
      database.select(database.gradeEntriesTable).get();

  ExamItem item(String task, double points, {String text = 'x'}) => ExamItem(
    matchKey: '',
    kind: ExpectationKind.regular,
    task: task,
    description: text,
    maxPoints: points,
  );

  test(
    'a complete student gets a grade entry, an incomplete one none',
    () async {
      final examId = await createExam();
      final a = await exams.addExpectation(examId, item('1', 6));
      final b = await exams.addExpectation(examId, item('2', 4));

      await exams.setScore(
        examId: examId,
        expectationId: a,
        studentId: ada,
        points: 6,
      );
      expect(await gradeEntries(), isEmpty);

      await exams.setScore(
        examId: examId,
        expectationId: b,
        studentId: ada,
        points: 3,
      );
      final entries = await gradeEntries();
      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.studentId, ada);
      expect(entry.value, '1'); // 9 of 10; the cutoff for 1 is round(8.7) = 9.
      expect(entry.examId, examId);
      expect(entry.categoryId, 'klassenarbeit');
      expect(entry.sessionLabel, 'Klassenarbeit 1');
      expect(entry.date, DateTime(2026, 11, 3));
    },
  );

  test('grades follow scores, attendance and overrides', () async {
    final examId = await createExam();
    final a = await exams.addExpectation(examId, item('1', 10));

    await exams.setScore(
      examId: examId,
      expectationId: a,
      studentId: ada,
      points: 9,
    );
    expect((await gradeEntries()).single.value, '1');

    await exams.setScore(
      examId: examId,
      expectationId: a,
      studentId: ada,
      points: 5,
    );
    expect((await gradeEntries()).single.value, '4');

    await exams.setParticipant(
      examId: examId,
      studentId: ada,
      gradeOverride: '6',
      overrideReason: 'Täuschungsversuch',
    );
    expect((await gradeEntries()).single.value, '6');

    await exams.setParticipant(
      examId: examId,
      studentId: ada,
      attendance: ExamAttendance.absent,
    );
    expect(await gradeEntries(), isEmpty);

    await exams.setParticipant(examId: examId, studentId: ada);
    expect((await gradeEntries()).single.value, '4');

    await exams.setScore(
      examId: examId,
      expectationId: a,
      studentId: ada,
      points: null,
    );
    expect(await gradeEntries(), isEmpty);
  });

  test('points outside 0..max are rejected', () async {
    final examId = await createExam();
    final a = await exams.addExpectation(examId, item('1', 2));
    expect(
      () => exams.setScore(
        examId: examId,
        expectationId: a,
        studentId: ada,
        points: 2.5,
      ),
      throwsRangeError,
    );
    expect(
      () => exams.setScore(
        examId: examId,
        expectationId: a,
        studentId: ada,
        points: -1,
      ),
      throwsRangeError,
    );
  });

  test(
    'editing the structure updates grades; lowering a maximum clamps',
    () async {
      final examId = await createExam();
      final a = await exams.addExpectation(examId, item('1', 10));
      await exams.setScore(
        examId: examId,
        expectationId: a,
        studentId: grace,
        points: 10,
      );
      expect((await gradeEntries()).single.value, '1');

      final b = await exams.addExpectation(examId, item('2', 10));
      expect(
        await gradeEntries(),
        isEmpty,
        reason: 'new expectation is unscored',
      );
      await exams.setScore(
        examId: examId,
        expectationId: b,
        studentId: grace,
        points: 0,
      );
      expect((await gradeEntries()).single.value, '4'); // 10 of 20 = 50%

      final row = (await exams.getExpectations(
        examId,
      )).firstWhere((e) => e.id == a);
      await exams.updateExpectation(
        examId,
        examItemFromRow(row).copyWith(maxPoints: 4),
      );
      final scores = await exams.getScores(examId);
      expect(scores.firstWhere((s) => s.expectationId == a).points, 4);

      await exams.deleteExpectation(examId, b);
      expect(await exams.getScores(examId), hasLength(1));
      expect((await gradeEntries()).single.value, '1'); // 4 of 4
    },
  );

  test('changing the scheme or details rewrites the entries', () async {
    final examId = await createExam();
    final a = await exams.addExpectation(examId, item('1', 10));
    await exams.setScore(
      examId: examId,
      expectationId: a,
      studentId: ada,
      points: 5,
    );
    expect((await gradeEntries()).single.value, '4');

    await exams.updateScheme(
      examId,
      const GradeScheme(
        thresholds: [
          GradeThreshold(label: '1', minPercent: 50),
          GradeThreshold(label: '6', minPercent: 0),
        ],
      ),
    );
    expect((await gradeEntries()).single.value, '1');

    await exams.updateExamDetails(
      examId: examId,
      title: 'KA 1',
      date: DateTime(2026, 12, 1),
      categoryId: 'praesentation',
      categoryName: 'Präsentation',
    );
    final entry = (await gradeEntries()).single;
    expect(entry.sessionLabel, 'KA 1');
    expect(entry.categoryId, 'praesentation');
    expect(entry.date, DateTime(2026, 12, 1));
  });

  test('deleting an exam removes everything it owns', () async {
    final examId = await createExam();
    final a = await exams.addExpectation(examId, item('1', 10));
    await exams.setScore(
      examId: examId,
      expectationId: a,
      studentId: ada,
      points: 5,
    );
    await exams.setParticipant(
      examId: examId,
      studentId: grace,
      attendance: ExamAttendance.excused,
    );

    await exams.deleteExam(examId);
    expect(await gradeEntries(), isEmpty);
    expect(await database.select(database.examScoresTable).get(), isEmpty);
    expect(
      await database.select(database.examParticipantsTable).get(),
      isEmpty,
    );
    expect(
      await database.select(database.examExpectationsTable).get(),
      isEmpty,
    );
    expect(await database.select(database.examsTable).get(), isEmpty);
  });

  test('applying an import keeps, clamps, removes and adds', () async {
    final examId = await createExam();
    Future<int> addKeyed(String key, double points, int sort) =>
        exams.addExpectation(
          examId,
          item('1', points).copyWith(matchKey: key, sortOrder: sort),
        );
    final kept = await addKeyed('id:kept', 4, 1);
    final swapA = await addKeyed('id:a', 1, 2);
    final swapB = await addKeyed('id:b', 1, 3);
    final removed = await addKeyed('id:gone', 2, 4);
    for (final id in [kept, swapA, swapB, removed]) {
      await exams.setScore(
        examId: examId,
        expectationId: id,
        studentId: ada,
        points: 1,
      );
    }

    final snapshot = (await exams.loadSnapshot(examId))!;
    final after = [
      item('1', 2, text: 'kept').copyWith(matchKey: 'id:kept', sortOrder: 0),
      // Two expectations swap keys: must not trip the unique (exam, key) index.
      item('1', 1).copyWith(matchKey: 'id:b', sortOrder: 1),
      item('1', 1).copyWith(matchKey: 'id:a', sortOrder: 2),
      item('2', 3, text: 'new').copyWith(matchKey: 'id:new', sortOrder: 3),
    ];
    final plan = ImportPlan(
      diffExamStructure(
        before: snapshot.items,
        after: after,
        metaBefore: snapshot.meta,
        metaAfter: snapshot.meta,
        schemeBefore: snapshot.scheme,
        schemeAfter: snapshot.scheme,
      ),
    );
    await exams.applyImport(
      examId: examId,
      plan: plan,
      meta: const ExamStructureMeta(),
      scheme: _scheme,
      gradeLabelMappingJson: '{}',
      manifestSha256: 'abc',
      assessioFormat: 1,
      taskSheetSha256: 'sheet',
      rubricSha256: 'rubric',
    );

    final rows = await exams.getExpectations(examId);
    expect(rows.map((r) => r.matchKey), ['id:kept', 'id:b', 'id:a', 'id:new']);
    expect(rows.first.id, kept);
    expect(rows.first.maxPoints, 2);
    final scores = {
      for (final s in await exams.getScores(examId)) s.expectationId: s.points,
    };
    expect(scores, {kept: 1, swapA: 1, swapB: 1});
    final exam = (await exams.getExam(examId))!;
    expect(exam.source, 'typst');
    expect(exam.manifestSha256, 'abc');
    expect(await exams.referencedDocumentHashes(), {'sheet', 'rubric'});
    expect(
      await gradeEntries(),
      isEmpty,
      reason: 'new expectation is unscored',
    );
  });
}
