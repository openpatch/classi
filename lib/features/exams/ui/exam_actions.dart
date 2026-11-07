import 'dart:developer' as developer;
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/utils/grade_categories.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../groups/group_export_service.dart';
import '../../settings/grade_system_controller.dart';
import '../data/exam_repository.dart';
import '../domain/grade_scheme.dart';
import '../exam_providers.dart';
import '../typst/exam_typst_workflow.dart';
import '../typst/typst_service.dart';
import 'exam_form_sheet.dart';
import 'exam_format.dart';
import 'exam_import_screen.dart';
import 'exam_pdf_screen.dart';

String examLocation(int groupId, int examId) =>
    '/groups/$groupId/exams/$examId';

/// The scheme a new manual exam starts with: the thresholds of the grade
/// system matching the group's scale, else the NRW defaults for its size.
GradeScheme initialSchemeFor(
  List<GradeScaleEntry> scale,
  GradeSystemController systems,
) {
  final defaults = defaultThresholdsFor(scale);
  final template = systems.matchingSystem(scale)?.thresholds;
  if (template == null) return GradeScheme(thresholds: defaults);
  return GradeScheme(
    thresholds: [
      for (final t in defaults)
        t.copyWith(minPercent: template[t.label] ?? t.minPercent),
    ],
  );
}

Future<void> createExam(
  BuildContext context,
  WidgetRef ref,
  Group group,
) async {
  final categories = parseGradeCategories(group.gradeCategoriesJson);
  final typst = ref.read(typstSupportedProvider);
  final form = await showExamFormSheet(
    context: context,
    categories: categories,
    offerTypst: typst,
  );
  if (form == null || !context.mounted) return;

  final repository = ref.read(examRepositoryProvider);
  final scale = parseGradeScaleEntries(group.gradeScaleJson);
  final examId = await repository.createExam(
    groupId: group.id,
    title: form.title,
    date: form.date,
    categoryId: form.category.id,
    categoryName: form.category.name,
    scheme: initialSchemeFor(scale, ref.read(gradeSystemControllerProvider)),
  );
  if (!context.mounted) return;

  if (form.fromTypst) {
    final imported = await importFromTypst(
      context,
      ref,
      examId: examId,
      isNew: true,
    );
    if (!imported) {
      await repository.deleteExam(examId);
      return;
    }
  }
  if (context.mounted) context.push(examLocation(group.id, examId));
}

Future<void> editExamDetails(
  BuildContext context,
  WidgetRef ref,
  Exam exam,
  Group group,
) async {
  final form = await showExamFormSheet(
    context: context,
    categories: parseGradeCategories(group.gradeCategoriesJson),
    initialTitle: exam.title,
    initialDate: exam.date,
    initialCategoryId: exam.categoryId,
    editing: true,
  );
  if (form == null) return;
  await ref
      .read(examRepositoryProvider)
      .updateExamDetails(
        examId: exam.id,
        title: form.title,
        date: form.date,
        categoryId: form.category.id,
        categoryName: form.category.name,
      );
}

Future<bool> deleteExam(BuildContext context, WidgetRef ref, Exam exam) async {
  final confirmed = await showConfirmDialog(
    context: context,
    title: 'exam_delete'.tr(),
    body: 'exam_delete_body'.tr(namedArgs: {'title': exam.title}),
  );
  if (!confirmed) return false;
  final repository = ref.read(examRepositoryProvider);
  await repository.deleteExam(exam.id);
  await _collectDocumentGarbage(ref);
  final path = ref.read(selectedDatabasePathProvider);
  if (path != null) {
    await ref.read(typstSettingsStoreProvider).setLink(path, exam.id, null);
  }
  return true;
}

Future<void> _collectDocumentGarbage(WidgetRef ref) async {
  final store = ref.read(examDocumentStoreProvider);
  if (store == null) return;
  try {
    await store.collectGarbage(
      await ref.read(examRepositoryProvider).referencedDocumentHashes(),
    );
  } on FileSystemException catch (error) {
    developer.log(
      'Document cleanup failed',
      name: 'classi.exams',
      error: error,
    );
  }
}

Future<void> openExamDocument(
  BuildContext context,
  WidgetRef ref, {
  required String? sha256,
  required String title,
  required String subtitle,
}) async {
  final file = await ref.read(examDocumentStoreProvider)?.read(sha256);
  if (!context.mounted) return;
  if (file == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('exam_document_missing'.tr())));
    return;
  }
  await ExamPdfScreen.open(
    context,
    file: file,
    title: title,
    subtitle: subtitle,
  );
}

// -- Typst --------------------------------------------------------------------

/// Picks the Typst document and its project root for [examId].
Future<TypstLink?> chooseTypstLink(
  BuildContext context,
  WidgetRef ref, {
  TypstLink? current,
}) async {
  final session = ref.read(appSessionProvider);
  session.suspendBackgroundLock();
  FilePickerResult? picked;
  try {
    picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['typ'],
      initialDirectory: current == null ? null : p.dirname(current.mainFile),
    );
  } finally {
    session.resumeBackgroundLock();
  }
  final path = picked?.files.single.path;
  if (path == null || !context.mounted) return null;

  var root = current != null && p.isWithin(current.root, path)
      ? current.root
      : TypstLink.guessRoot(path);
  return showDialog<TypstLink>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text('exam_typst_root'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('exam_typst_root_hint'.tr()),
            const SizedBox(height: 12),
            Text(
              'exam_typst_document'.tr(),
              style: Theme.of(dialogContext).textTheme.labelLarge,
            ),
            SelectableText(path),
            const SizedBox(height: 8),
            Text(
              'exam_typst_root'.tr(),
              style: Theme.of(dialogContext).textTheme.labelLarge,
            ),
            SelectableText(root),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              session.suspendBackgroundLock();
              String? folder;
              try {
                folder = await FilePicker.getDirectoryPath(
                  initialDirectory: root,
                );
              } finally {
                session.resumeBackgroundLock();
              }
              if (folder == null) return;
              if (!p.isWithin(folder, path)) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('exam_typst_root_invalid'.tr())),
                  );
                }
                return;
              }
              setState(() => root = folder!);
            },
            child: Text('exam_typst_change_root'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(TypstLink(mainFile: path, root: root)),
            child: Text('continue'.tr()),
          ),
        ],
      ),
    ),
  );
}

/// Runs [task] behind a modal progress indicator.
Future<T> _withProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() task,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

Future<void> showTypstError(BuildContext context, Object error) {
  final details = switch (error) {
    TypstFailureException(:final message, :final details) => (message, details),
    TypstUnavailableException(:final message) => (message, ''),
    _ => ('exam_typst_failed'.tr(), '$error'),
  };
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('exam_typst_failed'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details.$1),
            if (details.$2.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                details.$2,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (details.$2.isNotEmpty)
          TextButton(
            onPressed: () => Clipboard.setData(
              ClipboardData(text: '${details.$1}\n${details.$2}'),
            ),
            child: Text('copy'.tr()),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('ok'.tr()),
        ),
      ],
    ),
  );
}

/// Reads the exam's Typst document, shows what changed, and applies it on
/// accept. Asks for the document first when the exam has no link on this
/// device (or [chooseDocument] is set). Returns whether an import was applied.
Future<bool> importFromTypst(
  BuildContext context,
  WidgetRef ref, {
  required int examId,
  bool isNew = false,
  bool chooseDocument = false,
}) async {
  final databasePath = ref.read(selectedDatabasePathProvider);
  if (databasePath == null) return false;
  final settings = ref.read(typstSettingsStoreProvider);
  var link = await settings.link(databasePath, examId);
  if (!context.mounted) return false;
  if (link == null || chooseDocument) {
    link = await chooseTypstLink(context, ref, current: link);
    if (link == null || !context.mounted) return false;
  }

  final TypstReadResult result;
  try {
    final workflow = await ref.read(typstWorkflowProvider.future);
    if (!context.mounted) return false;
    final chosen = link;
    result = await _withProgress(
      context,
      'exam_typst_reading'.tr(),
      () => workflow.read(chosen),
    );
  } on Object catch (error, stack) {
    developer.log(
      'Typst import failed',
      name: 'classi.exams',
      error: error,
      stackTrace: stack,
    );
    if (context.mounted) await showTypstError(context, error);
    return false;
  }
  if (!context.mounted) {
    await result.dispose();
    return false;
  }

  try {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ExamImportScreen(examId: examId, result: result, isNew: isNew),
      ),
    );
    if (accepted != true) return false;
    await settings.setLink(databasePath, examId, link);
    ref.read(typstSettingsRevisionProvider.notifier).state++;
    await _collectDocumentGarbage(ref);
    return true;
  } finally {
    await result.dispose();
  }
}

/// Stores the PDFs of [result] and applies the import. Used by the import
/// screen once the teacher accepts.
Future<void> applyTypstImport(
  WidgetRef ref, {
  required int examId,
  required TypstReadResult result,
  required Future<void> Function(String? taskSheet, String? rubric) apply,
}) async {
  final store = ref.read(examDocumentStoreProvider);
  final taskSheet = await store?.put(result.taskSheet);
  final rubric = await store?.put(result.rubric);
  await apply(taskSheet, rubric);
}

enum _ExportMode { combined, perStudent }

/// Renders filled Erwartungshorizonte for all graded students. Nothing is
/// stored in the library; the PDF goes where the teacher saves it.
Future<void> exportFilledRubrics(
  BuildContext context,
  WidgetRef ref, {
  required ExamSnapshot snapshot,
  required List<Student> students,
}) async {
  final databasePath = ref.read(selectedDatabasePathProvider);
  if (databasePath == null) return;
  final link = await ref
      .read(typstSettingsStoreProvider)
      .link(databasePath, snapshot.exam.id);
  if (!context.mounted) return;
  if (link == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('exam_typst_no_link'.tr())));
    return;
  }

  final calculator = snapshot.calculator;
  final included = <RubricStudent>[];
  var skipped = 0;
  for (final student in students) {
    final attendance = snapshot.attendanceOf(student.id);
    if (attendance != ExamAttendance.present) continue;
    final scores = snapshot.scoresOf(student.id);
    final result = calculator.compute(scores);
    final override = snapshot.participants[student.id]?.gradeOverride;
    if (!result.complete && override == null) {
      skipped++;
      continue;
    }
    included.add(
      RubricStudent(
        name: studentName(student),
        grade: override ?? result.grade,
        scores: {
          for (final item in snapshot.items)
            if (item.scoreKey != null &&
                item.id != null &&
                scores.containsKey(item.id))
              item.scoreKey!: scores[item.id]!,
        },
      ),
    );
  }
  if (included.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('exam_export_nobody'.tr())));
    return;
  }

  final mode = await showDialog<_ExportMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text('exam_export_rubrics'.tr()),
      children: [
        if (skipped > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'exam_export_skipped'.tr(namedArgs: {'count': '$skipped'}),
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(_ExportMode.combined),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text('exam_export_combined'.tr()),
            subtitle: Text(
              'exam_export_combined_hint'.tr(
                namedArgs: {'count': '${included.length}'},
              ),
            ),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(_ExportMode.perStudent),
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text('exam_export_per_student'.tr()),
            subtitle: Text('exam_export_per_student_hint'.tr()),
          ),
        ),
      ],
    ),
  );
  if (mode == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final session = ref.read(appSessionProvider);
  try {
    final workflow = await ref.read(typstWorkflowProvider.future);
    if (!context.mounted) return;
    final exam = await _withProgress(
      context,
      'exam_typst_reading'.tr(),
      () => workflow.readManifest(link),
    );
    if (exam.sha256 != snapshot.exam.manifestSha256) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('exam_typst_changed'.tr()),
            content: Text('exam_export_review_first'.tr()),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('ok'.tr()),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final baseName = _safeFileName(snapshot.exam.title);

    if (mode == _ExportMode.combined) {
      final temp = await Directory.systemTemp.createTemp('classi-rubrics-');
      try {
        final file = File(p.join(temp.path, '$baseName.pdf'));
        if (!context.mounted) return;
        await _withProgress(
          context,
          'exam_export_rendering'.tr(),
          () => workflow.exportRubrics(
            link: link,
            exam: exam,
            students: included,
            output: file,
          ),
        );
        if (!context.mounted) return;
        final saved = await shareOrSaveFile(
          file: file,
          filename: p.basename(file.path),
          mimeType: 'application/pdf',
          subject: snapshot.exam.title,
          savePathResolver: () async {
            session.suspendBackgroundLock();
            try {
              return await FilePicker.saveFile(
                fileName: p.basename(file.path),
                type: FileType.custom,
                allowedExtensions: const ['pdf'],
              );
            } finally {
              session.resumeBackgroundLock();
            }
          },
        );
        if (saved) {
          messenger.showSnackBar(
            SnackBar(content: Text('export_success'.tr())),
          );
        }
      } finally {
        await temp.delete(recursive: true);
      }
      return;
    }

    session.suspendBackgroundLock();
    String? folder;
    try {
      folder = await FilePicker.getDirectoryPath();
    } finally {
      session.resumeBackgroundLock();
    }
    if (folder == null || !context.mounted) return;
    final target = folder;
    await _withProgress(context, 'exam_export_rendering'.tr(), () async {
      for (final student in included) {
        await workflow.exportRubrics(
          link: link,
          exam: exam,
          students: [student],
          output: File(
            p.join(target, '${baseName}_${_safeFileName(student.name)}.pdf'),
          ),
        );
      }
    });
    messenger.showSnackBar(SnackBar(content: Text('export_success'.tr())));
  } on Object catch (error, stack) {
    developer.log(
      'Rubric export failed',
      name: 'classi.exams',
      error: error,
      stackTrace: stack,
    );
    if (context.mounted) await showTypstError(context, error);
  }
}

String _safeFileName(String value) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[^\w\-äöüÄÖÜß ]+'), '')
      .replaceAll(' ', '_');
  return cleaned.isEmpty ? 'exam' : cleaned;
}

/// Forgets the Typst document on this device and makes the exam editable.
Future<void> unlinkTypst(BuildContext context, WidgetRef ref, Exam exam) async {
  final confirmed = await showConfirmDialog(
    context: context,
    title: 'exam_typst_unlink'.tr(),
    body: 'exam_typst_unlink_body'.tr(),
    confirmKey: 'exam_typst_unlink',
  );
  if (!confirmed) return;
  final path = ref.read(selectedDatabasePathProvider);
  if (path != null) {
    await ref.read(typstSettingsStoreProvider).setLink(path, exam.id, null);
  }
  await ref.read(examRepositoryProvider).setSource(exam.id, 'manual');
  ref.read(typstSettingsRevisionProvider.notifier).state++;
}
