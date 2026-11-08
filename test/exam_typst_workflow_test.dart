import 'dart:io';

import 'package:classi/features/exams/domain/exam_structure.dart';
import 'package:classi/features/exams/typst/exam_typst_workflow.dart';
import 'package:classi/features/exams/typst/typst_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// A typst-assessio checkout: `ASSESSIO_DIR`, else the usual sibling folder.
String? _assessioDir() {
  final candidates = [
    Platform.environment['ASSESSIO_DIR'],
    p.join(
      Platform.environment['HOME'] ?? '',
      'Sources/openpatch/typst-assessio',
    ),
  ];
  for (final dir in candidates) {
    if (dir != null && File(p.join(dir, 'lib.typ')).existsSync()) return dir;
  }
  return null;
}

Future<bool> _hasTypst() async {
  try {
    await TypstService().version();
    return true;
  } on Object {
    return false;
  }
}

void main() {
  test('wrapper finds the assessio import as written', () {
    expect(
      ExamTypstWorkflow.findAssessioImport(
        '#import "@local/assessio:0.1.0": *',
      ),
      '"@local/assessio:0.1.0"',
    );
    expect(
      ExamTypstWorkflow.findAssessioImport(
        '#set text(lang: "de")\n  #import "../lib.typ": task',
      ),
      '"../lib.typ"',
    );
    expect(
      ExamTypstWorkflow.findAssessioImport('#import "other.typ": *'),
      isNull,
    );
  });

  test('reads, renders and exports a real assessio document', () async {
    final assessio = _assessioDir();
    if (assessio == null || !await _hasTypst()) {
      markTestSkipped('typst or typst-assessio not available');
      return;
    }
    // Work on a copy: rendering writes a temporary wrapper next to the exam.
    final project = await Directory.systemTemp.createTemp('assessio-project');
    addTearDown(() => project.delete(recursive: true));
    for (final name in ['lib.typ', 'i18n.typ', 'grades.typ']) {
      await File(p.join(assessio, name)).copy(p.join(project.path, name));
    }
    await Directory(p.join(project.path, 'examples')).create();
    final main = await File(
      p.join(assessio, 'examples', 'basic.typ'),
    ).copy(p.join(project.path, 'examples', 'basic.typ'));

    final link = TypstLink(mainFile: main.path, root: project.path);
    final workflow = ExamTypstWorkflow(TypstService());
    final result = await workflow.read(link);
    addTearDown(result.dispose);

    expect(
      result.exam.items.where((i) => i.kind == ExpectationKind.additional),
      hasLength(1),
    );
    expect(result.exam.maxPoints, 9);
    expect((await result.taskSheet.readAsBytes()).take(4), '%PDF'.codeUnits);
    expect((await result.rubric.readAsBytes()).take(4), '%PDF'.codeUnits);

    final output = File(p.join(project.path, 'rubrics.pdf'));
    await workflow.exportRubrics(
      link: link,
      exam: result.exam,
      students: [
        RubricStudent(
          name: 'Ada Lovelace',
          scores: {for (final i in result.exam.items) i.scoreKey!: i.maxPoints},
          grade: '1',
        ),
        const RubricStudent(name: 'Grace Hopper', scores: {}, grade: null),
      ],
      output: output,
    );
    expect((await output.readAsBytes()).take(4), '%PDF'.codeUnits);

    // No wrapper or data file is left behind in the teacher's folder.
    final leftovers = Directory(p.join(project.path, 'examples'))
        .listSync()
        .map((e) => p.basename(e.path))
        .where((name) => name.startsWith('.classi-'));
    expect(leftovers, isEmpty);

    final text = await _pdfText(output);
    if (text != null) {
      expect(text, contains('Ada Lovelace'));
      expect(text, contains('Grace Hopper'));
      expect(text, isNot(contains('Solve the quadratic equation')));
    }
  });

  test('renders documents that get assessio from a template', () async {
    final assessio = _assessioDir();
    if (assessio == null || !await _hasTypst()) {
      markTestSkipped('typst or typst-assessio not available');
      return;
    }
    final project = await Directory.systemTemp.createTemp('assessio-template');
    addTearDown(() => project.delete(recursive: true));
    for (final name in ['lib.typ', 'i18n.typ', 'grades.typ']) {
      await File(p.join(assessio, name)).copy(p.join(project.path, name));
    }
    // A school template (like magistera's klausur) that passes assessio on.
    await File(
      p.join(project.path, 'template.typ'),
    ).writeAsString('#import "lib.typ": *\n#let school = "Test"\n');
    final main = File(p.join(project.path, 'exam.typ'));
    await main.writeAsString('''
#import "template.typ": *
#set text(lang: "de")
#task(1)[Rechne. #expectation(points: 2, [Ergebnis richtig.])]
''');
    final link = TypstLink(mainFile: main.path, root: project.path);
    final workflow = ExamTypstWorkflow(TypstService());
    expect(
      ExamTypstWorkflow.findAssessioImport(await main.readAsString()),
      isNull,
    );

    final result = await workflow.read(link);
    addTearDown(result.dispose);
    expect(result.exam.items.single.maxPoints, 2);
    expect((await result.rubric.readAsBytes()).take(4), '%PDF'.codeUnits);
    final text = await _pdfText(result.rubric);
    if (text != null) {
      expect(text, contains('Ergebnis richtig.'));
      expect(text, isNot(contains('Rechne.')));
    }
  });

  test('explains a document without any assessio', () async {
    if (!await _hasTypst()) {
      markTestSkipped('typst not available');
      return;
    }
    final project = await Directory.systemTemp.createTemp('no-assessio');
    addTearDown(() => project.delete(recursive: true));
    final main = File(p.join(project.path, 'exam.typ'));
    await main.writeAsString('= Just a document\n');
    await expectLater(
      ExamTypstWorkflow(
        TypstService(),
      ).read(TypstLink(mainFile: main.path, root: project.path)),
      throwsA(isA<TypstFailureException>()),
    );
  });

  test('large student data goes through a temporary file', () async {
    final assessio = _assessioDir();
    if (assessio == null || !await _hasTypst()) {
      markTestSkipped('typst or typst-assessio not available');
      return;
    }
    final project = await Directory.systemTemp.createTemp('assessio-project');
    addTearDown(() => project.delete(recursive: true));
    for (final name in ['lib.typ', 'i18n.typ', 'grades.typ']) {
      await File(p.join(assessio, name)).copy(p.join(project.path, name));
    }
    await Directory(p.join(project.path, 'examples')).create();
    final main = await File(
      p.join(assessio, 'examples', 'basic.typ'),
    ).copy(p.join(project.path, 'examples', 'basic.typ'));
    final link = TypstLink(mainFile: main.path, root: project.path);
    final workflow = ExamTypstWorkflow(TypstService());
    final exam = await workflow.readManifest(link);

    final padding = 'x' * (ExamTypstWorkflow.maxInlineDataBytes + 10);
    final output = File(p.join(project.path, 'big.pdf'));
    await workflow.exportRubrics(
      link: link,
      exam: exam,
      students: [
        RubricStudent(
          name: 'Big $padding'.substring(0, 20),
          scores: {padding: 0},
        ),
      ],
      output: output,
    );
    expect(await output.exists(), isTrue);
    expect(
      Directory(
        p.join(project.path, 'examples'),
      ).listSync().where((e) => p.basename(e.path).startsWith('.classi-')),
      isEmpty,
    );
  });
}

Future<String?> _pdfText(File pdf) async {
  try {
    final result = await Process.run('pdftotext', [pdf.path, '-']);
    return result.exitCode == 0 ? result.stdout as String : null;
  } on ProcessException {
    return null;
  }
}
