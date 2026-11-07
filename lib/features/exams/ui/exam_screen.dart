import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/app_bar_title.dart';
import '../../../shared/widgets/content_constraints.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../grades/grade_distribution.dart';
import '../../groups/group_detail_screen.dart'
    show groupProvider, groupStudentsProvider;
import '../data/exam_repository.dart';
import '../domain/exam_calculator.dart';
import '../exam_providers.dart';
import 'exam_actions.dart';
import 'exam_analysis_tab.dart';
import 'exam_format.dart';
import 'exam_points_grid.dart';
import 'exam_scheme_tab.dart';
import 'exam_structure_tab.dart';

String examStudentLocation(int groupId, int examId, int studentId) =>
    '${examLocation(groupId, examId)}/students/$studentId';

enum _ExamMenu {
  edit,
  taskSheet,
  rubric,
  typstImport,
  typstChoose,
  typstExport,
  typstUnlink,
  delete,
}

class ExamScreen extends ConsumerWidget {
  const ExamScreen({required this.groupId, required this.examId, super.key});

  final int groupId;
  final int examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotValue = ref.watch(examSnapshotProvider(examId));
    final group = ref.watch(groupProvider(groupId)).value;
    final students =
        ref.watch(groupStudentsProvider(groupId)).value ?? const <Student>[];

    final snapshot = snapshotValue.value;
    if (snapshotValue.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('${snapshotValue.error}')),
      );
    }
    if (snapshot == null || group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: snapshotValue.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.assignment_outlined,
                title: 'exam_missing'.tr(),
              ),
      );
    }

    final exam = snapshot.exam;
    final typstSupported = ref.watch(typstSupportedProvider);
    final isTypst = exam.source == 'typst';
    final dateLabel = DateFormat.yMMMd(
      context.locale.toLanguageTag(),
    ).format(exam.date);
    final changed = ref.watch(examTypstChangedProvider(examId)).value ?? false;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle(
            title: exam.title,
            subtitle: '${group.name} · $dateLabel · ${exam.categoryName}',
          ),
          actions: [
            if (exam.rubricSha256 != null)
              IconButton(
                tooltip: 'exam_rubric'.tr(),
                icon: const Icon(Icons.fact_check_outlined),
                onPressed: () => openExamDocument(
                  context,
                  ref,
                  sha256: exam.rubricSha256,
                  title: 'exam_rubric'.tr(),
                  subtitle: exam.title,
                ),
              ),
            PopupMenuButton<_ExamMenu>(
              onSelected: (value) =>
                  _onMenu(context, ref, value, snapshot, group, students),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ExamMenu.edit,
                  child: Text('exam_edit'.tr()),
                ),
                if (exam.taskSheetSha256 != null)
                  PopupMenuItem(
                    value: _ExamMenu.taskSheet,
                    child: Text('exam_task_sheet'.tr()),
                  ),
                if (exam.rubricSha256 != null)
                  PopupMenuItem(
                    value: _ExamMenu.rubric,
                    child: Text('exam_rubric'.tr()),
                  ),
                if (typstSupported) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ExamMenu.typstImport,
                    child: Text(
                      isTypst
                          ? 'exam_typst_reimport'.tr()
                          : 'exam_typst_link'.tr(),
                    ),
                  ),
                  if (isTypst) ...[
                    PopupMenuItem(
                      value: _ExamMenu.typstChoose,
                      child: Text('exam_typst_choose'.tr()),
                    ),
                    PopupMenuItem(
                      value: _ExamMenu.typstExport,
                      child: Text('exam_export_rubrics'.tr()),
                    ),
                    PopupMenuItem(
                      value: _ExamMenu.typstUnlink,
                      child: Text('exam_typst_unlink'.tr()),
                    ),
                  ],
                ],
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _ExamMenu.delete,
                  child: Text('delete'.tr()),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'exam_tab_results'.tr()),
              Tab(text: 'exam_tab_points'.tr()),
              Tab(text: 'exam_tab_structure'.tr()),
              Tab(text: 'exam_tab_scheme'.tr()),
              Tab(text: 'exam_tab_analysis'.tr()),
            ],
          ),
        ),
        body: Column(
          children: [
            if (changed)
              MaterialBanner(
                leading: const Icon(Icons.sync_problem_outlined),
                content: Text('exam_typst_changed_banner'.tr()),
                actions: [
                  TextButton(
                    onPressed: () =>
                        importFromTypst(context, ref, examId: examId),
                    child: Text('exam_typst_review'.tr()),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  ExamResultsTab(
                    snapshot: snapshot,
                    group: group,
                    students: students,
                  ),
                  ExamPointsTab(
                    snapshot: snapshot,
                    group: group,
                    students: students,
                  ),
                  ExamStructureTab(snapshot: snapshot),
                  ExamSchemeTab(snapshot: snapshot, group: group),
                  ExamAnalysisTab(
                    snapshot: snapshot,
                    group: group,
                    students: students,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    _ExamMenu value,
    ExamSnapshot snapshot,
    Group group,
    List<Student> students,
  ) async {
    final exam = snapshot.exam;
    switch (value) {
      case _ExamMenu.edit:
        await editExamDetails(context, ref, exam, group);
      case _ExamMenu.taskSheet:
        await openExamDocument(
          context,
          ref,
          sha256: exam.taskSheetSha256,
          title: 'exam_task_sheet'.tr(),
          subtitle: exam.title,
        );
      case _ExamMenu.rubric:
        await openExamDocument(
          context,
          ref,
          sha256: exam.rubricSha256,
          title: 'exam_rubric'.tr(),
          subtitle: exam.title,
        );
      case _ExamMenu.typstImport:
        await importFromTypst(context, ref, examId: exam.id);
      case _ExamMenu.typstChoose:
        await importFromTypst(
          context,
          ref,
          examId: exam.id,
          chooseDocument: true,
        );
      case _ExamMenu.typstExport:
        await exportFilledRubrics(
          context,
          ref,
          snapshot: snapshot,
          students: students,
        );
      case _ExamMenu.typstUnlink:
        await unlinkTypst(context, ref, exam);
      case _ExamMenu.delete:
        if (await deleteExam(context, ref, exam) && context.mounted) {
          context.pop();
        }
    }
  }
}

/// One row of results per student.
class StudentRow {
  StudentRow({required this.student, required this.snapshot}) {
    final scores = snapshot.scoresOf(student.id);
    result = snapshot.calculator.compute(scores);
    participant = snapshot.participants[student.id];
    status = statusOf(
      result: result,
      attendance: participant?.status ?? 'present',
      hasOverride: participant?.gradeOverride != null,
      hasScores: scores.isNotEmpty,
    );
  }

  final Student student;
  final ExamSnapshot snapshot;
  late final StudentExamResult result;
  late final ExamParticipant? participant;
  late final ExamStudentStatus status;

  bool get present =>
      status != ExamStudentStatus.absent && status != ExamStudentStatus.excused;

  /// The grade that counts: override, else the grade of a complete result.
  String? get finalGrade =>
      participant?.gradeOverride ??
      (present && result.complete ? result.grade : null);
}

class ExamResultsTab extends ConsumerWidget {
  const ExamResultsTab({
    required this.snapshot,
    required this.group,
    required this.students,
    super.key,
  });

  final ExamSnapshot snapshot;
  final Group group;
  final List<Student> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (students.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'exam_no_students'.tr(),
      );
    }
    final rows = [
      for (final s in students) StudentRow(student: s, snapshot: snapshot),
    ];
    final scale = parseGradeScaleEntries(group.gradeScaleJson);
    final graded = rows.where((r) => r.finalGrade != null).toList();
    final present = rows.where((r) => r.present).toList();
    final completed = present.where((r) => r.result.complete).toList();
    final distribution = computeGradeDistribution(
      graded.map((r) => r.finalGrade!),
      scale,
    );
    final meanPercent = completed.isEmpty
        ? null
        : completed.fold(0.0, (s, r) => s + r.result.percent) /
              completed.length;
    final maxPoints = snapshot.calculator.maxPoints;

    return ContentConstraints(
      child: ListView(
        padding: appScreenPadding,
        children: [
          Card(
            child: Padding(
              padding: appCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.task_alt, size: 18),
                        label: Text(
                          'exam_graded_count'.tr(
                            namedArgs: {
                              'graded': '${graded.length}',
                              'total': '${present.length}',
                            },
                          ),
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.functions, size: 18),
                        label: Text(
                          'exam_max_points'.tr(
                            namedArgs: {
                              'points': formatPoints(context, maxPoints),
                            },
                          ),
                        ),
                      ),
                      if (meanPercent != null)
                        Chip(
                          avatar: const Icon(Icons.percent, size: 18),
                          label: Text(
                            'exam_mean_percent'.tr(
                              namedArgs: {
                                'percent': formatPercent(context, meanPercent),
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (graded.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.large),
                    GradeDistributionChart(
                      distribution: distribution,
                      gradeScale: scale,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, row) in rows.indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  _ResultTile(row: row, snapshot: snapshot, group: group),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({
    required this.row,
    required this.snapshot,
    required this.group,
  });

  final StudentRow row;
  final ExamSnapshot snapshot;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final result = row.result;
    final grade =
        row.finalGrade ??
        (row.present && result.grade != null ? '(${result.grade})' : '–');
    return ListTile(
      onTap: () => context.push(
        examStudentLocation(group.id, snapshot.exam.id, row.student.id),
      ),
      leading: Tooltip(
        message: labelForStatus(row.status),
        child: Icon(iconForStatus(row.status)),
      ),
      title: Text(studentName(row.student)),
      subtitle: row.present
          ? Text(
              '${formatPoints(context, result.total)} / ${formatPoints(context, result.maxPoints)} · '
              '${formatPercent(context, result.percent)} %'
              '${result.complete ? '' : ' · ${'exam_missing_count'.tr(namedArgs: {'count': '${result.missing}'})}'}',
            )
          : Text(labelForStatus(row.status)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(grade, style: theme.textTheme.titleMedium),
          IconButton(
            tooltip: 'exam_participation'.tr(),
            icon: const Icon(Icons.more_vert),
            onPressed: () => showParticipantDialog(
              context,
              ref,
              snapshot: snapshot,
              student: row.student,
              scale: parseGradeScaleEntries(group.gradeScaleJson),
            ),
          ),
        ],
      ),
    );
  }
}

/// Attendance, grade override and note of one student.
Future<void> showParticipantDialog(
  BuildContext context,
  WidgetRef ref, {
  required ExamSnapshot snapshot,
  required Student student,
  required List<GradeScaleEntry> scale,
}) async {
  final participant = snapshot.participants[student.id];
  var attendance = ExamAttendance.parse(participant?.status);
  String? override = participant?.gradeOverride;
  final reason = TextEditingController(text: participant?.overrideReason);
  final note = TextEditingController(text: participant?.note);

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(studentName(student)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ExamAttendance>(
                segments: [
                  ButtonSegment(
                    value: ExamAttendance.present,
                    label: Text('exam_present'.tr()),
                  ),
                  ButtonSegment(
                    value: ExamAttendance.absent,
                    label: Text('exam_status_absent'.tr()),
                  ),
                  ButtonSegment(
                    value: ExamAttendance.excused,
                    label: Text('exam_status_excused'.tr()),
                  ),
                ],
                selected: {attendance},
                onSelectionChanged: (value) =>
                    setState(() => attendance = value.single),
              ),
              const SizedBox(height: AppSpacing.large),
              DropdownButtonFormField<String?>(
                initialValue: override,
                decoration: InputDecoration(
                  labelText: 'exam_grade_override'.tr(),
                  helperText: 'exam_grade_override_hint'.tr(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('exam_no_override'.tr()),
                  ),
                  for (final entry in scale)
                    DropdownMenuItem<String?>(
                      value: entry.label,
                      child: Text(entry.label),
                    ),
                ],
                onChanged: attendance == ExamAttendance.present
                    ? (value) => setState(() => override = value)
                    : null,
              ),
              if (override != null && attendance == ExamAttendance.present)
                TextField(
                  controller: reason,
                  decoration: InputDecoration(
                    labelText: 'exam_override_reason'.tr(),
                  ),
                ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: note,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(labelText: 'exam_note'.tr()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('save'.tr()),
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    await ref
        .read(examRepositoryProvider)
        .setParticipant(
          examId: snapshot.exam.id,
          studentId: student.id,
          attendance: attendance,
          gradeOverride: attendance == ExamAttendance.present ? override : null,
          overrideReason: reason.text,
          note: note.text,
        );
  }
  reason.dispose();
  note.dispose();
}

/// Point entry: a keyboard grid on wide screens, a student list otherwise
/// (each student opens the per-student entry).
class ExamPointsTab extends StatelessWidget {
  const ExamPointsTab({
    required this.snapshot,
    required this.group,
    required this.students,
    super.key,
  });

  final ExamSnapshot snapshot;
  final Group group;
  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    if (snapshot.items.where((i) => i.kind.isScored).isEmpty) {
      return EmptyState(
        icon: Icons.list_alt_outlined,
        title: 'exam_no_expectations'.tr(),
        body: 'exam_no_expectations_hint'.tr(),
      );
    }
    if (students.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'exam_no_students'.tr(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return ExamPointsGrid(snapshot: snapshot, students: students);
        }
        return ExamResultsTab(
          snapshot: snapshot,
          group: group,
          students: students,
        );
      },
    );
  }
}
