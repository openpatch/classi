import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import 'data/exam_document_store.dart';
import 'data/exam_repository.dart';
import 'typst/exam_typst_workflow.dart';
import 'typst/typst_service.dart';
import 'typst/typst_settings.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(ref.watch(databaseProvider)),
);

final groupExamsProvider = StreamProvider.autoDispose.family<List<Exam>, int>(
  (ref, groupId) =>
      ref.watch(examRepositoryProvider).watchExamsForGroup(groupId),
);

final examProvider = StreamProvider.autoDispose.family<Exam?, int>(
  (ref, examId) => ref.watch(examRepositoryProvider).watchExam(examId),
);

final examExpectationsProvider = StreamProvider.autoDispose
    .family<List<ExamExpectation>, int>(
      (ref, examId) =>
          ref.watch(examRepositoryProvider).watchExpectations(examId),
    );

final examScoresProvider = StreamProvider.autoDispose
    .family<List<ExamScore>, int>(
      (ref, examId) => ref.watch(examRepositoryProvider).watchScores(examId),
    );

final examParticipantsProvider = StreamProvider.autoDispose
    .family<List<ExamParticipant>, int>(
      (ref, examId) =>
          ref.watch(examRepositoryProvider).watchParticipants(examId),
    );

/// Everything about one exam, kept current by the four streams above.
/// `AsyncData(null)` when the exam does not exist (any more).
final examSnapshotProvider = Provider.autoDispose
    .family<AsyncValue<ExamSnapshot?>, int>((ref, examId) {
      final exam = ref.watch(examProvider(examId));
      final expectations = ref.watch(examExpectationsProvider(examId));
      final scores = ref.watch(examScoresProvider(examId));
      final participants = ref.watch(examParticipantsProvider(examId));
      for (final value in [exam, expectations, scores, participants]) {
        if (value.hasError) {
          return AsyncError(
            value.error!,
            value.stackTrace ?? StackTrace.current,
          );
        }
      }
      if (!exam.hasValue ||
          !expectations.hasValue ||
          !scores.hasValue ||
          !participants.hasValue) {
        return const AsyncLoading();
      }
      final row = exam.value;
      if (row == null) return const AsyncData(null);
      return AsyncData(
        ExamRepository.snapshotOf(
          row,
          expectations.value!,
          scores.value!,
          participants.value!,
        ),
      );
    });

/// The open library's document folder, or `null` without a library.
final examDocumentStoreProvider = Provider<ExamDocumentStore?>((ref) {
  final path = ref.watch(selectedDatabasePathProvider);
  return path == null ? null : ExamDocumentStore(path);
});

final typstSettingsStoreProvider = Provider<TypstSettingsStore>(
  (ref) => TypstSettingsStore(),
);

/// The configured Typst binary path; bump [typstSettingsRevisionProvider]
/// after changing it.
final typstBinaryPathProvider = FutureProvider<String?>((ref) {
  ref.watch(typstSettingsRevisionProvider);
  return ref.watch(typstSettingsStoreProvider).binaryPath();
});

final typstSettingsRevisionProvider = StateProvider<int>((ref) => 0);

/// Whether this device can talk to Typst at all.
final typstSupportedProvider = Provider<bool>(
  (ref) => TypstService.isSupportedPlatform,
);

final typstWorkflowProvider = FutureProvider<ExamTypstWorkflow>((ref) async {
  final binary = await ref.watch(typstBinaryPathProvider.future);
  return ExamTypstWorkflow(TypstService(configuredBinary: binary));
});

/// Where an exam's Typst document lives on this device.
final examTypstLinkProvider = FutureProvider.autoDispose
    .family<TypstLink?, int>((ref, examId) {
      ref.watch(typstSettingsRevisionProvider);
      final path = ref.watch(selectedDatabasePathProvider);
      if (path == null) return Future.value(null);
      return ref.watch(typstSettingsStoreProvider).link(path, examId);
    });

/// Whether the linked Typst document changed since the last accepted import
/// (desktop only). Errors count as "unchanged": the banner is a hint, the
/// import itself reports problems.
final examTypstChangedProvider = FutureProvider.autoDispose.family<bool, int>((
  ref,
  examId,
) async {
  if (!TypstService.isSupportedPlatform) return false;
  final exam = await ref.watch(examProvider(examId).future);
  if (exam == null || exam.source != 'typst') return false;
  final link = await ref.watch(examTypstLinkProvider(examId).future);
  if (link == null) return false;
  try {
    final workflow = await ref.watch(typstWorkflowProvider.future);
    final manifest = await workflow.readManifest(link);
    return manifest.sha256 != exam.manifestSha256;
  } on Object {
    return false;
  }
});
