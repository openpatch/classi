import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_ui.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/content_constraints.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/exam_repository.dart';
import '../domain/exam_structure.dart';
import '../exam_providers.dart';
import 'exam_format.dart';

/// The Erwartungshorizont: expectations grouped by task. Editable for manual
/// exams; read-only when the exam follows a Typst document.
class ExamStructureTab extends ConsumerWidget {
  const ExamStructureTab({required this.snapshot, super.key});

  final ExamSnapshot snapshot;

  bool get _editable => snapshot.exam.source != 'typst';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = groupByTask(snapshot.items);
    final calculator = snapshot.calculator;

    return Scaffold(
      floatingActionButton: _editable
          ? FloatingActionButton.extended(
              heroTag: 'exam-add-expectation-${snapshot.exam.id}',
              onPressed: () => _editItem(context, ref, null),
              icon: const Icon(Icons.add),
              label: Text('exam_add_expectation'.tr()),
            )
          : null,
      body: snapshot.items.isEmpty
          ? EmptyState(
              icon: Icons.list_alt_outlined,
              title: 'exam_no_expectations'.tr(),
              body: _editable ? 'exam_no_expectations_hint'.tr() : null,
            )
          : ContentConstraints(
              child: ListView(
                padding: appScreenPadding.copyWith(bottom: 96),
                children: [
                  if (!_editable)
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text('exam_managed_by_typst'.tr()),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.functions),
                      title: Text(
                        'exam_max_points'.tr(
                          namedArgs: {
                            'points': formatPoints(
                              context,
                              calculator.maxPoints,
                            ),
                          },
                        ),
                      ),
                      subtitle: snapshot.meta.electiveGroups.isEmpty
                          ? null
                          : Text(
                              snapshot.meta.electiveGroups
                                  .map(
                                    (g) => 'exam_elective_group_summary'.tr(
                                      namedArgs: {
                                        'label': g.label,
                                        'count': '${g.countedTasks}',
                                      },
                                    ),
                                  )
                                  .join(' · '),
                            ),
                      trailing: _editable
                          ? TextButton(
                              onPressed: () =>
                                  _editElectiveGroups(context, ref),
                              child: Text('exam_elective_groups'.tr()),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        4,
                        AppSpacing.medium,
                        4,
                        AppSpacing.small,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              taskHeading(group.items.first, snapshot.meta),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            formatPoints(
                              context,
                              group.items.fold(0.0, (s, i) => s + i.maxPoints),
                            ),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final (index, item) in group.items.indexed) ...[
                            if (index > 0) const Divider(height: 1),
                            ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(
                                  item.part ?? '•',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                              title: Text(
                                item.description.isEmpty
                                    ? '–'
                                    : item.description,
                              ),
                              subtitle:
                                  item.label == null &&
                                      item.kind != ExpectationKind.alternative
                                  ? null
                                  : Text(
                                      [
                                        ?item.label,
                                        if (item.kind ==
                                            ExpectationKind.alternative)
                                          'exam_kind_alternative'.tr(),
                                      ].join(' · '),
                                    ),
                              trailing: Text(
                                item.kind == ExpectationKind.alternative
                                    ? ''
                                    : formatPoints(context, item.maxPoints),
                                style: theme.textTheme.titleSmall,
                              ),
                              onTap: _editable
                                  ? () => _editItem(context, ref, item)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    ExamItem? item,
  ) async {
    final result = await showDialog<_ItemEdit>(
      context: context,
      builder: (_) => _ItemDialog(
        item: item,
        meta: snapshot.meta,
        suggestedTask: _nextTask(),
      ),
    );
    if (result == null) return;
    final repository = ref.read(examRepositoryProvider);
    final examId = snapshot.exam.id;
    if (result.delete && item != null) {
      final scored = snapshot.scores.values
          .where((s) => s.containsKey(item.id))
          .length;
      if (scored > 0 && context.mounted) {
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'exam_delete_expectation'.tr(),
          body: 'exam_delete_expectation_body'.tr(
            namedArgs: {'count': '$scored'},
          ),
        );
        if (!confirmed) return;
      }
      await repository.deleteExpectation(examId, item.id!);
      return;
    }
    final edited = result.item!;
    if (item == null) {
      await repository.addExpectation(examId, edited);
    } else {
      await repository.updateExpectation(examId, edited.copyWith(id: item.id));
    }
  }

  String _nextTask() {
    if (snapshot.items.isEmpty) return '1';
    final last = snapshot.items.last;
    return last.task;
  }

  Future<void> _editElectiveGroups(BuildContext context, WidgetRef ref) async {
    final groups = snapshot.items
        .where((i) => i.kind == ExpectationKind.elective)
        .map((i) => i.groupKey ?? '')
        .toSet()
        .toList();
    if (groups.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('exam_no_elective_groups'.tr())));
      return;
    }
    final counts = {
      for (final g in groups)
        g: TextEditingController(text: '${snapshot.meta.countedTasksFor(g)}'),
    };
    final labels = {
      for (final g in groups)
        g: TextEditingController(
          text: snapshot.meta.electiveGroupLabel(g) ?? g,
        ),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('exam_elective_groups'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('exam_elective_groups_hint'.tr()),
              for (final g in groups)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: labels[g],
                        decoration: InputDecoration(
                          labelText: 'exam_group_label'.tr(
                            namedArgs: {'id': g},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    SizedBox(
                      width: 96,
                      child: TextField(
                        controller: counts[g],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'exam_counted_tasks'.tr(),
                        ),
                      ),
                    ),
                  ],
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
    );
    if (saved == true) {
      await ref
          .read(examRepositoryProvider)
          .updateMeta(
            snapshot.exam.id,
            snapshot.meta.copyWith(
              electiveGroups: [
                for (final g in groups)
                  ElectiveGroupInfo(
                    id: g,
                    label: labels[g]!.text.trim().isEmpty
                        ? g
                        : labels[g]!.text.trim(),
                    countedTasks: (int.tryParse(counts[g]!.text) ?? 1).clamp(
                      1,
                      99,
                    ),
                  ),
              ],
            ),
          );
    }
    for (final c in [...counts.values, ...labels.values]) {
      c.dispose();
    }
  }
}

class _ItemEdit {
  const _ItemEdit({this.item, this.delete = false});

  final ExamItem? item;
  final bool delete;
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({
    required this.item,
    required this.meta,
    required this.suggestedTask,
  });

  final ExamItem? item;
  final ExamStructureMeta meta;
  final String suggestedTask;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _form = GlobalKey<FormState>();
  late ExpectationKind _kind = widget.item?.kind ?? ExpectationKind.regular;
  late final _task = TextEditingController(
    text: widget.item?.task ?? widget.suggestedTask,
  );
  late final _part = TextEditingController(text: widget.item?.part ?? '');
  late final _group = TextEditingController(text: widget.item?.groupKey ?? '');
  late final _description = TextEditingController(
    text: widget.item?.description ?? '',
  );
  late final _label = TextEditingController(text: widget.item?.label ?? '');
  late final _points = TextEditingController(
    text: widget.item == null ? '' : _formatInitial(widget.item!.maxPoints),
  );

  static String _formatInitial(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  @override
  void dispose() {
    for (final c in [_task, _part, _group, _description, _label, _points]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsTask = _kind != ExpectationKind.additional;
    return AlertDialog(
      title: Text(
        widget.item == null
            ? 'exam_add_expectation'.tr()
            : 'exam_edit_expectation'.tr(),
      ),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ExpectationKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: 'exam_kind'.tr()),
                items: [
                  for (final kind in ExpectationKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text('exam_kind_${kind.name}'.tr()),
                    ),
                ],
                onChanged: (value) => setState(() => _kind = value ?? _kind),
              ),
              if (needsTask)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _task,
                        decoration: InputDecoration(
                          labelText: 'exam_task_number'.tr(),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'exam_task_number'.tr()
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: TextFormField(
                        controller: _part,
                        decoration: InputDecoration(
                          labelText: 'exam_part'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_kind == ExpectationKind.elective ||
                  _kind == ExpectationKind.regular)
                TextFormField(
                  controller: _group,
                  decoration: InputDecoration(
                    labelText: _kind == ExpectationKind.elective
                        ? 'exam_elective_group'.tr()
                        : 'exam_task_group'.tr(),
                    helperText: _kind == ExpectationKind.elective
                        ? 'exam_elective_group_hint'.tr()
                        : null,
                  ),
                ),
              TextFormField(
                controller: _description,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'exam_expectation_text'.tr(),
                ),
              ),
              TextFormField(
                controller: _label,
                decoration: InputDecoration(
                  labelText: 'exam_expectation_label'.tr(),
                  helperText: 'exam_expectation_label_hint'.tr(),
                ),
              ),
              if (_kind != ExpectationKind.alternative)
                TextFormField(
                  controller: _points,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'exam_max_points_label'.tr(),
                  ),
                  validator: (v) {
                    final value = parsePoints(v ?? '');
                    return value == null || value < 0
                        ? 'exam_max_points_label'.tr()
                        : null;
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.item != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _ItemEdit(delete: true)),
            child: Text('delete'.tr()),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(onPressed: _save, child: Text('save'.tr())),
      ],
    );
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final kind = _kind;
    final item = ExamItem(
      matchKey: widget.item?.matchKey ?? '',
      kind: kind,
      task: kind == ExpectationKind.additional ? '' : _task.text.trim(),
      part: kind == ExpectationKind.additional ? null : optional(_part),
      groupKey: kind == ExpectationKind.elective
          ? (optional(_group) ?? '')
          : (kind == ExpectationKind.regular ? optional(_group) : null),
      description: _description.text.trim(),
      label: optional(_label),
      maxPoints: kind == ExpectationKind.alternative
          ? 0
          : parsePoints(_points.text)!,
      sortOrder: widget.item?.sortOrder ?? 0,
      scoreKey: widget.item?.scoreKey,
    );
    Navigator.of(context).pop(_ItemEdit(item: item));
  }
}
