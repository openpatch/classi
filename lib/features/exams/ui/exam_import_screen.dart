import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/app_bar_title.dart';
import '../../../shared/widgets/content_constraints.dart';
import '../../groups/group_detail_screen.dart'
    show groupProvider, groupStudentsProvider;
import '../data/exam_repository.dart';
import '../domain/exam_calculator.dart';
import '../domain/exam_diff.dart';
import '../domain/exam_structure.dart';
import '../domain/grade_label_mapping.dart';
import '../domain/grade_scheme.dart';
import '../exam_providers.dart';
import '../typst/exam_typst_workflow.dart';
import 'exam_actions.dart';
import 'exam_format.dart';

/// Shows what importing the Typst document changes, and applies it on
/// accept. Pops `true` when applied.
class ExamImportScreen extends ConsumerStatefulWidget {
  const ExamImportScreen({
    required this.examId,
    required this.result,
    this.isNew = false,
    super.key,
  });

  final int examId;
  final TypstReadResult result;
  final bool isNew;

  @override
  ConsumerState<ExamImportScreen> createState() => _ExamImportScreenState();
}

class _ExamImportScreenState extends ConsumerState<ExamImportScreen> {
  Map<String, String?>? _mapping;
  final Set<String> _split = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final snapshotValue = ref.watch(examSnapshotProvider(widget.examId));
    final snapshot = snapshotValue.value;
    final group = snapshot == null
        ? null
        : ref.watch(groupProvider(snapshot.exam.groupId)).value;
    final students = snapshot == null
        ? const <Student>[]
        : ref.watch(groupStudentsProvider(snapshot.exam.groupId)).value ??
              const [];

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          title: 'exam_import_review'.tr(),
          subtitle: snapshot?.exam.title,
        ),
      ),
      body: snapshot == null || group == null
          ? const Center(child: CircularProgressIndicator())
          : _body(context, snapshot, group, students),
    );
  }

  Widget _body(
    BuildContext context,
    ExamSnapshot snapshot,
    Group group,
    List<Student> students,
  ) {
    final imported = widget.result.exam;
    final scale = parseGradeScaleEntries(group.gradeScaleJson);
    final previous = _decodeMapping(snapshot.exam.gradeLabelMappingJson);
    final mapping = _mapping ??= suggestGradeLabelMapping(
      [for (final level in imported.scale) level.grade],
      scale,
      previous: previous,
    );
    final unmapped = mapping.values.any((v) => v == null);

    final schemeAfter = GradeScheme(
      thresholds: [
        for (final level in imported.scale)
          GradeThreshold(
            label: mapping[level.grade] ?? level.grade,
            minPercent: level.minPercent,
            sourceLabel: level.grade,
          ),
      ],
    );
    final diff = diffExamStructure(
      before: snapshot.items,
      after: imported.items,
      metaBefore: snapshot.meta,
      metaAfter: imported.meta,
      schemeBefore: snapshot.scheme,
      schemeAfter: schemeAfter,
    );
    final plan = ImportPlan(diff, splitUncertain: _split);
    final after = ExamCalculator(
      items: plan.resultingItems,
      meta: imported.meta,
      scheme: schemeAfter,
    );
    final changes = previewGradeChanges(
      scoresByStudent: snapshot.scores,
      before: snapshot.calculator,
      after: after,
      plan: plan,
    );
    final names = {for (final s in students) s.id: studentName(s)};
    final removedScores = changes.fold(0, (s, c) => s + c.removedScores);
    final clamped = changes.fold(0, (s, c) => s + c.clampedItems);
    final gradeChanges = changes
        .where((c) => c.gradeChanged || c.before.complete != c.after.complete)
        .toList();
    final maxMismatch =
        imported.maxPoints != null &&
        (imported.maxPoints! - after.maxPoints).abs() > 1e-9;
    final first = snapshot.items.isEmpty;
    final visibleChanges = diff.items
        .where((c) => c.type != ItemChangeType.unchanged)
        .toList();

    return Column(
      children: [
        Expanded(
          child: ContentConstraints(
            child: ListView(
              padding: appScreenPadding,
              children: [
                Card(
                  child: Padding(
                    padding: appCardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first
                              ? 'exam_import_first'.tr(
                                  namedArgs: {
                                    'count': '${imported.items.length}',
                                    'points': formatPoints(
                                      context,
                                      after.maxPoints,
                                    ),
                                  },
                                )
                              : diff.hasChanges
                              ? 'exam_import_summary'.tr(
                                  namedArgs: {
                                    'added': '${plan.inserted.length}',
                                    'removed': '${plan.deleted.length}',
                                    'changed': '${diff.changed.length}',
                                  },
                                )
                              : 'exam_import_no_changes'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (maxMismatch) ...[
                          const SizedBox(height: 8),
                          _Warning(
                            'exam_import_max_mismatch'.tr(
                              namedArgs: {
                                'typst': formatPoints(
                                  context,
                                  imported.maxPoints!,
                                ),
                                'classi': formatPoints(
                                  context,
                                  after.maxPoints,
                                ),
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                _section(context, 'exam_import_grades'.tr(), [
                  Text('exam_import_grades_hint'.tr()),
                  const SizedBox(height: AppSpacing.small),
                  for (final level in imported.scale)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${level.grade}  (≥ ${formatPercent(context, level.minPercent)} %)',
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 16),
                        const SizedBox(width: AppSpacing.small),
                        DropdownButton<String>(
                          value: mapping[level.grade],
                          hint: Text('exam_import_choose_grade'.tr()),
                          items: [
                            for (final entry in scale)
                              DropdownMenuItem(
                                value: entry.label,
                                child: Text(entry.label),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => mapping[level.grade] = value),
                        ),
                      ],
                    ),
                ]),
                if (!first && visibleChanges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.large),
                  _section(context, 'exam_import_changes'.tr(), [
                    for (final change in visibleChanges)
                      _changeTile(context, change, imported.meta),
                    if (diff.metaChanged)
                      ListTile(
                        leading: const Icon(Icons.account_tree_outlined),
                        title: Text('exam_import_meta_changed'.tr()),
                      ),
                    if (diff.schemeChanged)
                      ListTile(
                        leading: const Icon(Icons.stairs_outlined),
                        title: Text('exam_import_scheme_changed'.tr()),
                      ),
                  ]),
                ],
                if (removedScores > 0 ||
                    clamped > 0 ||
                    gradeChanges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.large),
                  _section(context, 'exam_import_consequences'.tr(), [
                    if (removedScores > 0)
                      _Warning(
                        'exam_import_removed_scores'.tr(
                          namedArgs: {'count': '$removedScores'},
                        ),
                      ),
                    if (clamped > 0)
                      _Warning(
                        'exam_import_clamped'.tr(
                          namedArgs: {'count': '$clamped'},
                        ),
                      ),
                    for (final change in gradeChanges)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.swap_horiz),
                        title: Text(
                          names[change.studentId] ?? '#${change.studentId}',
                        ),
                        trailing: Text(
                          '${_gradeText(change.before)}  →  ${_gradeText(change.after)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (unmapped)
                  Expanded(
                    child: Text(
                      'exam_import_unmapped'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text('exam_import_decline'.tr()),
                ),
                const SizedBox(width: AppSpacing.medium),
                FilledButton.icon(
                  onPressed: _saving || unmapped
                      ? null
                      : () =>
                            _accept(plan, imported.meta, schemeAfter, mapping),
                  icon: const Icon(Icons.check),
                  label: Text('exam_import_accept'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _gradeText(StudentExamResult result) =>
      result.complete ? (result.grade ?? '–') : '(${result.grade ?? '–'})';

  Widget _changeTile(
    BuildContext context,
    ItemChange change,
    ExamStructureMeta meta,
  ) {
    final item = (change.after ?? change.before)!;
    final heading = '${taskHeading(item, meta)} · ${item.description}';
    final (icon, text) = switch (change.type) {
      ItemChangeType.added => (
        Icons.add_circle_outline,
        'exam_change_added'.tr(),
      ),
      ItemChangeType.removed => (
        Icons.remove_circle_outline,
        'exam_change_removed'.tr(),
      ),
      _ => (Icons.edit_outlined, _describe(context, change)),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(heading, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(text),
        ),
        if (change.uncertain)
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 56),
            dense: true,
            value: _split.contains(change.after!.matchKey),
            title: Text('exam_change_treat_as_new'.tr()),
            subtitle: Text(
              'exam_change_uncertain'.tr(
                namedArgs: {'before': change.before!.description},
              ),
            ),
            onChanged: (value) => setState(() {
              if (value) {
                _split.add(change.after!.matchKey);
              } else {
                _split.remove(change.after!.matchKey);
              }
            }),
          ),
      ],
    );
  }

  String _describe(BuildContext context, ItemChange change) {
    final parts = <String>[
      if (change.pointsChanged)
        'exam_change_points'.tr(
          namedArgs: {
            'before': formatPoints(context, change.before!.maxPoints),
            'after': formatPoints(context, change.after!.maxPoints),
          },
        ),
      if (change.textChanged) 'exam_change_text'.tr(),
      if (change.placementChanged) 'exam_change_moved'.tr(),
    ];
    return parts.isEmpty ? 'exam_change_text'.tr() : parts.join(' · ');
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.small),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _accept(
    ImportPlan plan,
    ExamStructureMeta meta,
    GradeScheme scheme,
    Map<String, String?> mapping,
  ) async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(examRepositoryProvider);
      await applyTypstImport(
        ref,
        examId: widget.examId,
        result: widget.result,
        apply: (taskSheet, rubric) => repository.applyImport(
          examId: widget.examId,
          plan: plan,
          meta: meta,
          scheme: scheme,
          gradeLabelMappingJson: jsonEncode(mapping),
          manifestSha256: widget.result.exam.sha256,
          assessioFormat: widget.result.exam.format,
          taskSheetSha256: taskSheet,
          rubricSha256: rubric,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showTypstError(context, error);
    }
  }

  static Map<String, String> _decodeMapping(String? raw) {
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final e in decoded.entries)
          if (e.value is String) '${e.key}': e.value as String,
      };
    } on FormatException {
      return const {};
    }
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: scheme.error, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
