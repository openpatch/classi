import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../domain/assessio_manifest.dart';
import 'typst_service.dart';

/// Where an exam's Typst document lives on this device.
class TypstLink {
  const TypstLink({required this.mainFile, required this.root});

  final String mainFile;

  /// Typst project root (`--root`): must contain everything the document
  /// imports, e.g. `../vorlage.typ`.
  final String root;

  Map<String, String> toJson() => {'main': mainFile, 'root': root};

  static TypstLink? fromJson(Object? json) {
    if (json is! Map || json['main'] is! String || json['root'] is! String) {
      return null;
    }
    return TypstLink(
      mainFile: json['main'] as String,
      root: json['root'] as String,
    );
  }

  /// Default root: the nearest folder above [mainFile] that looks like a
  /// project (`.git`, `typst.toml`), else the file's own folder.
  static String guessRoot(String mainFile) {
    var dir = Directory(p.dirname(mainFile));
    while (true) {
      if (Directory(p.join(dir.path, '.git')).existsSync() ||
          File(p.join(dir.path, 'typst.toml')).existsSync()) {
        return dir.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return p.dirname(mainFile);
  }
}

/// The document read from Typst, with freshly rendered PDFs in a temporary
/// folder. Call [dispose] once the PDFs were stored or discarded.
class TypstReadResult {
  TypstReadResult({
    required this.exam,
    required this.taskSheet,
    required this.rubric,
    required this.tempDirectory,
  });

  final ImportedExam exam;
  final File taskSheet;
  final File rubric;
  final Directory tempDirectory;

  Future<void> dispose() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  }
}

/// One student's filled Erwartungshorizont.
class RubricStudent {
  const RubricStudent({required this.name, required this.scores, this.grade});

  final String name;

  /// assessio score key ("2a.3") -> points.
  final Map<String, double> scores;
  final String? grade;

  Map<String, Object?> toJson() => {
    'name': name,
    'scores': scores,
    'grade': grade,
  };
}

/// Reads assessio documents and renders their PDFs through [TypstService].
///
/// Rubrics are rendered from a temporary wrapper next to the exam: it
/// includes the exam with assessio's own output suppressed, then renders the
/// rubric on fresh pages that are cut out with `--pages`. The wrapper must sit
/// in the exam's folder so the exam's relative imports resolve, and is always
/// deleted again. Student data travels on the command line, not on disk,
/// unless it is too long for one argument.
class ExamTypstWorkflow {
  ExamTypstWorkflow(this.typst);

  final TypstService typst;
  final _random = Random();

  /// Linux limits a single argument to 128 KiB; stay well below.
  static const int maxInlineDataBytes = 100000;

  Future<ImportedExam> readManifest(TypstLink link) async {
    final raw = await typst.queryValue(
      main: File(link.mainFile),
      root: Directory(link.root),
      label: 'assessio-manifest',
    );
    try {
      return parseAssessioManifest(raw);
    } on ManifestFormatException catch (error) {
      throw TypstFailureException(
        'The document does not provide an assessio manifest. '
        'Update assessio and make sure the document uses task().',
        details: error.message,
      );
    }
  }

  /// Reads the structure and renders task sheet and unfilled rubric.
  Future<TypstReadResult> read(TypstLink link) async {
    final exam = await readManifest(link);
    final temp = await Directory.systemTemp.createTemp('classi-exam-');
    try {
      final taskSheet = File(p.join(temp.path, 'task-sheet.pdf'));
      await typst.compile(
        input: File(link.mainFile),
        root: Directory(link.root),
        output: taskSheet,
      );
      final rubric = File(p.join(temp.path, 'rubric.pdf'));
      await _renderRubric(
        link,
        data: {
          'mode': 'blank',
          'lang': exam.lang,
          'grading_system': exam.gradingSystem,
          'scale': [for (final level in exam.scale) level.toJson()],
          'students': const <Object>[],
        },
        output: rubric,
      );
      return TypstReadResult(
        exam: exam,
        taskSheet: taskSheet,
        rubric: rubric,
        tempDirectory: temp,
      );
    } on Object {
      await temp.delete(recursive: true);
      rethrow;
    }
  }

  /// Renders filled rubrics for [students] into [output] (one PDF).
  Future<void> exportRubrics({
    required TypstLink link,
    required ImportedExam exam,
    required List<RubricStudent> students,
    required File output,
  }) async {
    await _renderRubric(
      link,
      data: {
        'mode': 'students',
        'lang': exam.lang,
        'grading_system': exam.gradingSystem,
        'scale': [for (final level in exam.scale) level.toJson()],
        'students': [for (final s in students) s.toJson()],
      },
      output: output,
    );
  }

  Future<void> _renderRubric(
    TypstLink link, {
    required Map<String, Object?> data,
    required File output,
  }) async {
    final main = File(link.mainFile);
    // Import assessio as the exam does. Documents built on a template that
    // re-exports assessio (`#import "@local/magistera:0.1.0": *`) have no
    // assessio import of their own: take the functions from the exam module.
    final directImport = findAssessioImport(await main.readAsString());
    final importTarget = directImport ?? jsonEncode(p.basename(main.path));
    final folder = p.dirname(main.path);
    final token =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';
    final wrapper = File(p.join(folder, '.classi-render-$token.typ'));
    File? dataFile;
    final encoded = jsonEncode(data);
    final Map<String, String> inputs;
    if (utf8.encode(encoded).length <= maxInlineDataBytes) {
      inputs = {'assessio-data': encoded};
    } else {
      dataFile = File(p.join(folder, '.classi-data-$token.json'));
      await dataFile.writeAsString(encoded, flush: true);
      inputs = {'assessio-data-file': p.basename(dataFile.path)};
    }
    try {
      await wrapper.writeAsString(
        wrapperSource(
          importTarget: importTarget,
          mainFileName: p.basename(main.path),
        ),
        flush: true,
      );
      final String start;
      try {
        start = await typst.queryValue(
          main: wrapper,
          root: Directory(link.root),
          label: 'assessio-rubric-start',
          inputs: inputs,
        );
      } on TypstFailureException catch (error) {
        if (directImport == null &&
            error.details.contains('unresolved import')) {
          throw TypstFailureException(
            'The document does not import assessio, and its template does not '
            'pass assessio on. Import assessio (or the template) with `*`.',
            details: error.details,
          );
        }
        rethrow;
      }
      final startPage = int.tryParse(start.trim());
      if (startPage == null) {
        throw TypstFailureException(
          'Could not find where the Erwartungshorizont starts.',
          details: start,
        );
      }
      await typst.compile(
        input: wrapper,
        root: Directory(link.root),
        output: output,
        inputs: inputs,
        pages: '$startPage-',
      );
    } finally {
      if (await wrapper.exists()) await wrapper.delete();
      if (dataFile != null && await dataFile.exists()) await dataFile.delete();
    }
  }

  /// The wrapper document; see the class documentation.
  static String wrapperSource({
    required String importTarget,
    required String mainFileName,
  }) {
    final include = jsonEncode(mainFileName);
    return '''
// Generated by classi to render an Erwartungshorizont. Safe to delete.
#import $importTarget: set-assessio-render-suppressed, render-blank-rubric, render-student-rubrics
#let data = if "assessio-data" in sys.inputs {
  json(bytes(sys.inputs.at("assessio-data")))
} else {
  json(sys.inputs.at("assessio-data-file"))
}
#set text(lang: data.lang)
#set-assessio-render-suppressed()
#include $include
#let scale = data.scale.map(level => (grade: level.grade, min: level.min))
#if data.mode == "blank" {
  render-blank-rubric(grading-system: data.grading_system, scale: scale)
} else {
  render-student-rubrics(data.students, grading-system: data.grading_system, scale: scale)
}
''';
  }

  /// The import target of assessio in [source], quoted as written:
  /// `"@local/assessio:0.1.0"`, `"../lib.typ"`, …
  static String? findAssessioImport(String source) {
    final pattern = RegExp(r'^\s*#import\s+("([^"]+)")\s*:', multiLine: true);
    for (final match in pattern.allMatches(source)) {
      final target = match.group(2)!;
      if (target.contains('assessio') || target.endsWith('lib.typ')) {
        return match.group(1);
      }
    }
    return null;
  }
}
