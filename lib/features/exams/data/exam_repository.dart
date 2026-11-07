import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/exam_calculator.dart';
import '../domain/exam_diff.dart';
import '../domain/exam_structure.dart';
import '../domain/grade_scheme.dart';

/// Participation status of a student in an exam.
enum ExamAttendance {
  present,
  absent,
  excused;

  static ExamAttendance parse(String? raw) => switch (raw) {
    'absent' => ExamAttendance.absent,
    'excused' => ExamAttendance.excused,
    _ => ExamAttendance.present,
  };
}

/// Everything needed to grade one exam, read in one go.
class ExamSnapshot {
  const ExamSnapshot({
    required this.exam,
    required this.items,
    required this.meta,
    required this.scheme,
    required this.scores,
    required this.participants,
  });

  final Exam exam;
  final List<ExamItem> items;
  final ExamStructureMeta meta;
  final GradeScheme scheme;

  /// student id -> expectation id -> points.
  final Map<int, Map<int, double>> scores;
  final Map<int, ExamParticipant> participants;

  ExamCalculator get calculator =>
      ExamCalculator(items: items, meta: meta, scheme: scheme);

  ExamAttendance attendanceOf(int studentId) =>
      ExamAttendance.parse(participants[studentId]?.status);

  Map<int, double> scoresOf(int studentId) => scores[studentId] ?? const {};
}

ExamItem examItemFromRow(ExamExpectation row) => ExamItem(
  id: row.id,
  matchKey: row.matchKey,
  kind: ExpectationKind.parse(row.kind),
  task: row.task,
  part: row.part,
  groupKey: row.groupKey,
  scoreKey: row.scoreKey,
  description: row.description,
  label: row.label,
  maxPoints: row.maxPoints,
  sortOrder: row.sortOrder,
);

class ExamRepository {
  ExamRepository(this._db);

  final AppDatabase _db;
  final _random = Random();

  // -- Reading ----------------------------------------------------------------

  Stream<List<Exam>> watchExamsForGroup(int groupId) {
    return (_db.select(_db.examsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Stream<Exam?> watchExam(int examId) => (_db.select(
    _db.examsTable,
  )..where((t) => t.id.equals(examId))).watchSingleOrNull();

  Future<Exam?> getExam(int examId) => (_db.select(
    _db.examsTable,
  )..where((t) => t.id.equals(examId))).getSingleOrNull();

  Stream<List<ExamExpectation>> watchExpectations(int examId) {
    return (_db.select(_db.examExpectationsTable)
          ..where((t) => t.examId.equals(examId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<List<ExamExpectation>> getExpectations(int examId) {
    return (_db.select(_db.examExpectationsTable)
          ..where((t) => t.examId.equals(examId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Stream<List<ExamScore>> watchScores(int examId) => (_db.select(
    _db.examScoresTable,
  )..where((t) => t.examId.equals(examId))).watch();

  Future<List<ExamScore>> getScores(int examId) => (_db.select(
    _db.examScoresTable,
  )..where((t) => t.examId.equals(examId))).get();

  Stream<List<ExamParticipant>> watchParticipants(int examId) => (_db.select(
    _db.examParticipantsTable,
  )..where((t) => t.examId.equals(examId))).watch();

  Future<List<ExamParticipant>> getParticipants(int examId) => (_db.select(
    _db.examParticipantsTable,
  )..where((t) => t.examId.equals(examId))).get();

  /// Hashes of every stored exam document still referenced by an exam.
  Future<Set<String>> referencedDocumentHashes() async {
    final exams = await _db.select(_db.examsTable).get();
    return {
      for (final exam in exams) ...[?exam.taskSheetSha256, ?exam.rubricSha256],
    };
  }

  Future<ExamSnapshot?> loadSnapshot(int examId) async {
    final exam = await getExam(examId);
    if (exam == null) return null;
    return snapshotOf(
      exam,
      await getExpectations(examId),
      await getScores(examId),
      await getParticipants(examId),
    );
  }

  static ExamSnapshot snapshotOf(
    Exam exam,
    List<ExamExpectation> expectations,
    List<ExamScore> scores,
    List<ExamParticipant> participants,
  ) {
    final byStudent = <int, Map<int, double>>{};
    for (final score in scores) {
      byStudent.putIfAbsent(score.studentId, () => {})[score.expectationId] =
          score.points;
    }
    return ExamSnapshot(
      exam: exam,
      items: [for (final row in expectations) examItemFromRow(row)],
      meta: ExamStructureMeta.decode(exam.structureJson),
      scheme: GradeScheme.decode(exam.gradeSchemeJson),
      scores: byStudent,
      participants: {for (final p in participants) p.studentId: p},
    );
  }

  // -- Exams ------------------------------------------------------------------

  Future<int> createExam({
    required int groupId,
    required String title,
    required DateTime date,
    required String categoryId,
    required String categoryName,
    required GradeScheme scheme,
    ExamStructureMeta meta = const ExamStructureMeta(),
    String source = 'manual',
  }) {
    return _db
        .into(_db.examsTable)
        .insert(
          ExamsTableCompanion.insert(
            groupId: groupId,
            title: title.trim(),
            date: _dateOnly(date),
            categoryId: categoryId,
            categoryName: categoryName,
            source: Value(source),
            gradeSchemeJson: scheme.encode(),
            structureJson: Value(meta.encode()),
          ),
        );
  }

  Future<void> updateExamDetails({
    required int examId,
    required String title,
    required DateTime date,
    required String categoryId,
    required String categoryName,
  }) async {
    await _db.transaction(() async {
      await (_db.update(
        _db.examsTable,
      )..where((t) => t.id.equals(examId))).write(
        ExamsTableCompanion(
          title: Value(title.trim()),
          date: Value(_dateOnly(date)),
          categoryId: Value(categoryId),
          categoryName: Value(categoryName),
        ),
      );
      await syncGradeEntries(examId);
    });
  }

  /// Unlinks an exam from its Typst document: its structure and scheme
  /// become editable in the app.
  Future<void> setSource(int examId, String source) async {
    await (_db.update(_db.examsTable)..where((t) => t.id.equals(examId))).write(
      ExamsTableCompanion(source: Value(source)),
    );
  }

  Future<void> deleteExam(int examId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.gradeEntriesTable,
      )..where((t) => t.examId.equals(examId))).go();
      await (_db.delete(
        _db.examScoresTable,
      )..where((t) => t.examId.equals(examId))).go();
      await (_db.delete(
        _db.examParticipantsTable,
      )..where((t) => t.examId.equals(examId))).go();
      await (_db.delete(
        _db.examExpectationsTable,
      )..where((t) => t.examId.equals(examId))).go();
      await (_db.delete(
        _db.examsTable,
      )..where((t) => t.id.equals(examId))).go();
    });
  }

  Future<void> updateScheme(int examId, GradeScheme scheme) async {
    await _db.transaction(() async {
      await (_db.update(_db.examsTable)..where((t) => t.id.equals(examId)))
          .write(ExamsTableCompanion(gradeSchemeJson: Value(scheme.encode())));
      await syncGradeEntries(examId);
    });
  }

  Future<void> updateMeta(int examId, ExamStructureMeta meta) async {
    await _db.transaction(() async {
      await (_db.update(_db.examsTable)..where((t) => t.id.equals(examId)))
          .write(ExamsTableCompanion(structureJson: Value(meta.encode())));
      await syncGradeEntries(examId);
    });
  }

  // -- Manual structure -------------------------------------------------------

  Future<int> addExpectation(int examId, ExamItem item) async {
    return _db.transaction(() async {
      final existing = await getExpectations(examId);
      var sortOrder = existing.isEmpty
          ? 0
          : existing.map((e) => e.sortOrder).reduce(max) + 1;
      // Keep a task's expectations together: insert after the last one of
      // the same task and shift everything behind it.
      final sameTask = existing
          .where((e) => examItemFromRow(e).taskKey == item.taskKey)
          .toList();
      if (item.sortOrder <= 0 && sameTask.isNotEmpty) {
        sortOrder = sameTask.last.sortOrder + 1;
        for (final e in existing.where((e) => e.sortOrder >= sortOrder)) {
          await (_db.update(
            _db.examExpectationsTable,
          )..where((t) => t.id.equals(e.id))).write(
            ExamExpectationsTableCompanion(sortOrder: Value(e.sortOrder + 1)),
          );
        }
      }
      final id = await _db
          .into(_db.examExpectationsTable)
          .insert(
            _companionFor(
              examId,
              item.copyWith(
                matchKey: item.matchKey.isEmpty ? _manualKey() : item.matchKey,
                sortOrder: item.sortOrder > 0 ? item.sortOrder : sortOrder,
              ),
            ),
          );
      await syncGradeEntries(examId);
      return id;
    });
  }

  Future<void> updateExpectation(int examId, ExamItem item) async {
    final id = item.id;
    if (id == null) throw ArgumentError('Expectation has no id.');
    await _db.transaction(() async {
      await (_db.update(
        _db.examExpectationsTable,
      )..where((t) => t.id.equals(id))).write(
        _companionFor(examId, item).copyWith(id: const Value.absent()),
      );
      await _clampScores(id, item.maxPoints);
      await syncGradeEntries(examId);
    });
  }

  Future<void> deleteExpectation(int examId, int expectationId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.examScoresTable,
      )..where((t) => t.expectationId.equals(expectationId))).go();
      await (_db.delete(
        _db.examExpectationsTable,
      )..where((t) => t.id.equals(expectationId))).go();
      await syncGradeEntries(examId);
    });
  }

  Future<void> reorderExpectations(int examId, List<int> orderedIds) async {
    await _db.transaction(() async {
      for (final (index, id) in orderedIds.indexed) {
        await (_db.update(_db.examExpectationsTable)
              ..where((t) => t.id.equals(id) & t.examId.equals(examId)))
            .write(ExamExpectationsTableCompanion(sortOrder: Value(index)));
      }
    });
  }

  // -- Scores and participants ------------------------------------------------

  /// Sets (or with `null` clears) the points of one student for one
  /// expectation, then updates the student's grade entry.
  Future<void> setScore({
    required int examId,
    required int expectationId,
    required int studentId,
    required double? points,
  }) async {
    await _db.transaction(() async {
      final expectation = await (_db.select(
        _db.examExpectationsTable,
      )..where((t) => t.id.equals(expectationId))).getSingle();
      final existing =
          await (_db.select(_db.examScoresTable)..where(
                (t) =>
                    t.expectationId.equals(expectationId) &
                    t.studentId.equals(studentId),
              ))
              .getSingleOrNull();
      if (points == null) {
        if (existing != null) {
          await (_db.delete(
            _db.examScoresTable,
          )..where((t) => t.id.equals(existing.id))).go();
        }
      } else {
        if (points < 0 || points > expectation.maxPoints + 1e-9) {
          throw RangeError.range(points, 0, expectation.maxPoints.ceil());
        }
        if (existing == null) {
          await _db
              .into(_db.examScoresTable)
              .insert(
                ExamScoresTableCompanion.insert(
                  examId: examId,
                  expectationId: expectationId,
                  studentId: studentId,
                  points: points,
                ),
              );
        } else if (existing.points != points) {
          await (_db.update(_db.examScoresTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(ExamScoresTableCompanion(points: Value(points)));
        }
      }
      await syncGradeEntries(examId, studentIds: [studentId]);
    });
  }

  Future<void> setParticipant({
    required int examId,
    required int studentId,
    ExamAttendance attendance = ExamAttendance.present,
    String? gradeOverride,
    String? overrideReason,
    String? note,
  }) async {
    await _db.transaction(() async {
      final override = (gradeOverride?.trim().isEmpty ?? true)
          ? null
          : gradeOverride!.trim();
      final existing =
          await (_db.select(_db.examParticipantsTable)..where(
                (t) => t.examId.equals(examId) & t.studentId.equals(studentId),
              ))
              .getSingleOrNull();
      final companion = ExamParticipantsTableCompanion(
        status: Value(attendance.name),
        gradeOverride: Value(override),
        overrideReason: Value(override == null ? null : overrideReason?.trim()),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
      );
      if (existing == null) {
        await _db
            .into(_db.examParticipantsTable)
            .insert(
              companion.copyWith(
                examId: Value(examId),
                studentId: Value(studentId),
              ),
            );
      } else {
        await (_db.update(
          _db.examParticipantsTable,
        )..where((t) => t.id.equals(existing.id))).write(companion);
      }
      await syncGradeEntries(examId, studentIds: [studentId]);
    });
  }

  // -- Typst import -----------------------------------------------------------

  /// Applies an accepted import: structure, scheme, label mapping and stored
  /// documents, in one transaction. Scores of kept expectations stay (clamped
  /// to lowered maxima); scores of removed ones are deleted.
  Future<void> applyImport({
    required int examId,
    required ImportPlan plan,
    required ExamStructureMeta meta,
    required GradeScheme scheme,
    required String gradeLabelMappingJson,
    required String manifestSha256,
    required int assessioFormat,
    String? taskSheetSha256,
    String? rubricSha256,
  }) async {
    await _db.transaction(() async {
      // Free match keys first: a kept item may take over the key of a
      // deleted one.
      for (final item in plan.deleted) {
        await (_db.delete(
          _db.examScoresTable,
        )..where((t) => t.expectationId.equals(item.id!))).go();
        await (_db.delete(
          _db.examExpectationsTable,
        )..where((t) => t.id.equals(item.id!))).go();
      }
      final kept = plan.kept;
      for (final entry in kept.entries) {
        await (_db.update(
          _db.examExpectationsTable,
        )..where((t) => t.id.equals(entry.key))).write(
          ExamExpectationsTableCompanion(matchKey: Value('tmp:${entry.key}')),
        );
      }
      for (final entry in kept.entries) {
        await (_db.update(
          _db.examExpectationsTable,
        )..where((t) => t.id.equals(entry.key))).write(
          _companionFor(examId, entry.value).copyWith(id: const Value.absent()),
        );
        await _clampScores(entry.key, entry.value.maxPoints);
      }
      for (final item in plan.inserted) {
        await _db
            .into(_db.examExpectationsTable)
            .insert(_companionFor(examId, item.copyWith(id: null)));
      }
      await (_db.update(
        _db.examsTable,
      )..where((t) => t.id.equals(examId))).write(
        ExamsTableCompanion(
          source: const Value('typst'),
          structureJson: Value(meta.encode()),
          gradeSchemeJson: Value(scheme.encode()),
          gradeLabelMappingJson: Value(gradeLabelMappingJson),
          manifestSha256: Value(manifestSha256),
          assessioFormat: Value(assessioFormat),
          lastImportedAt: Value(DateTime.now()),
          taskSheetSha256: Value(taskSheetSha256),
          rubricSha256: Value(rubricSha256),
        ),
      );
      await syncGradeEntries(examId);
    });
  }

  // -- Grade entries ----------------------------------------------------------

  /// Brings the grade entries owned by the exam in line with the scores.
  ///
  /// Present students with complete scores get the computed grade (or their
  /// override); absent, excused and incomplete students get none.
  Future<void> syncGradeEntries(int examId, {Iterable<int>? studentIds}) async {
    final snapshot = await loadSnapshot(examId);
    if (snapshot == null) return;
    final exam = snapshot.exam;

    final Set<int> students;
    if (studentIds != null) {
      students = studentIds.toSet();
    } else {
      final groupStudents = await (_db.select(
        _db.studentsTable,
      )..where((t) => t.groupId.equals(exam.groupId))).get();
      final withEntries = await (_db.select(
        _db.gradeEntriesTable,
      )..where((t) => t.examId.equals(examId))).get();
      students = {
        ...groupStudents.map((s) => s.id),
        ...withEntries.map((e) => e.studentId),
        ...snapshot.scores.keys,
      };
    }

    final calculator = snapshot.calculator;
    for (final studentId in students) {
      final participant = snapshot.participants[studentId];
      final attendance = snapshot.attendanceOf(studentId);
      String? grade;
      if (attendance == ExamAttendance.present) {
        final override = participant?.gradeOverride;
        if (override != null && override.isNotEmpty) {
          grade = override;
        } else {
          final result = calculator.compute(snapshot.scoresOf(studentId));
          if (result.complete) grade = result.grade;
        }
      }
      await _writeGradeEntry(exam, studentId, grade);
    }
  }

  Future<void> _writeGradeEntry(Exam exam, int studentId, String? grade) async {
    final existing =
        await (_db.select(_db.gradeEntriesTable)..where(
              (t) => t.examId.equals(exam.id) & t.studentId.equals(studentId),
            ))
            .getSingleOrNull();
    if (grade == null) {
      if (existing != null) {
        await (_db.delete(
          _db.gradeEntriesTable,
        )..where((t) => t.id.equals(existing.id))).go();
      }
      return;
    }
    final companion = GradeEntriesTableCompanion(
      date: Value(exam.date),
      sessionLabel: Value(_truncate(exam.title, 120)),
      value: Value(_truncate(grade, 24)),
      categoryId: Value(exam.categoryId),
      categoryName: Value(exam.categoryName),
    );
    if (existing == null) {
      await _db
          .into(_db.gradeEntriesTable)
          .insert(
            companion.copyWith(
              studentId: Value(studentId),
              examId: Value(exam.id),
            ),
          );
    } else if (existing.value != companion.value.value ||
        existing.date != exam.date ||
        existing.sessionLabel != companion.sessionLabel.value ||
        existing.categoryId != exam.categoryId ||
        existing.categoryName != exam.categoryName) {
      await (_db.update(
        _db.gradeEntriesTable,
      )..where((t) => t.id.equals(existing.id))).write(companion);
    }
  }

  // -- Helpers ----------------------------------------------------------------

  Future<void> _clampScores(int expectationId, double maxPoints) async {
    await (_db.update(_db.examScoresTable)..where(
          (t) =>
              t.expectationId.equals(expectationId) &
              t.points.isBiggerThanValue(maxPoints),
        ))
        .write(ExamScoresTableCompanion(points: Value(maxPoints)));
  }

  ExamExpectationsTableCompanion _companionFor(int examId, ExamItem item) {
    return ExamExpectationsTableCompanion(
      id: item.id == null ? const Value.absent() : Value(item.id!),
      examId: Value(examId),
      matchKey: Value(item.matchKey),
      kind: Value(item.kind.name),
      task: Value(item.task),
      part: Value(item.part),
      groupKey: Value(item.groupKey),
      scoreKey: Value(item.scoreKey),
      description: Value(item.description),
      label: Value(item.label),
      maxPoints: Value(item.maxPoints),
      sortOrder: Value(item.sortOrder),
    );
  }

  String _manualKey() =>
      'manual:${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _truncate(String value, int length) =>
      value.length <= length ? value : value.substring(0, length);
}
