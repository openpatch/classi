import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/content_constraints.dart';
import '../../groups/group_detail_screen.dart' show groupStudentsProvider;
import '../data/exam_repository.dart';
import '../domain/exam_calculator.dart';
import '../domain/exam_diff.dart';
import '../domain/grade_scheme.dart';
import '../exam_providers.dart';
import 'exam_format.dart';

/// Thresholds from percent to grade, with the resulting point cutoffs.
class ExamSchemeTab extends ConsumerWidget {
  const ExamSchemeTab({required this.snapshot, required this.group, super.key});

  final ExamSnapshot snapshot;
  final Group group;

  bool get _editable => snapshot.exam.source != 'typst';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final maxPoints = snapshot.calculator.maxPoints;
    final cutoffs = snapshot.scheme.cutoffs(maxPoints);

    return ContentConstraints(
      child: ListView(
        padding: appScreenPadding,
        children: [
          if (!_editable)
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('exam_scheme_from_typst'.tr()),
              ),
            ),
          Card(
            child: Padding(
              padding: appCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'exam_tab_scheme'.tr(),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (_editable)
                        FilledButton.tonalIcon(
                          onPressed: () => _edit(context, ref),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text('edit'.tr()),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'exam_scheme_rounding'.tr(
                      namedArgs: {'points': formatPoints(context, maxPoints)},
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (cutoffs.isEmpty)
                    Text('exam_scheme_empty'.tr())
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(),
                        2: FlexColumnWidth(),
                      },
                      children: [
                        TableRow(
                          children: [
                            Text(
                              'grade'.tr(),
                              style: theme.textTheme.labelLarge,
                            ),
                            Text(
                              'exam_scheme_percent'.tr(),
                              style: theme.textTheme.labelLarge,
                            ),
                            Text(
                              'exam_scheme_points'.tr(),
                              style: theme.textTheme.labelLarge,
                            ),
                          ],
                        ),
                        for (final c in cutoffs)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  c.threshold.sourceLabel != null &&
                                          c.threshold.sourceLabel !=
                                              c.threshold.label
                                      ? '${c.threshold.label}  (${c.threshold.sourceLabel})'
                                      : c.threshold.label,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  '≥ ${formatPercent(context, c.threshold.minPercent)} %',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text('≥ ${c.cutoff}'),
                              ),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final scale = parseGradeScaleEntries(group.gradeScaleJson);
    final systems = ref.read(gradeSystemControllerProvider).systems;
    final next = await showDialog<GradeScheme>(
      context: context,
      builder: (_) => _SchemeDialog(
        current: snapshot.scheme.isEmpty
            ? GradeScheme(thresholds: defaultThresholdsFor(scale))
            : snapshot.scheme,
        scale: scale,
        templates: [
          for (final s in systems)
            if (s.thresholds != null &&
                scale.every((e) => s.thresholds!.containsKey(e.label)))
              (name: s.name, thresholds: s.thresholds!),
        ],
      ),
    );
    if (next == null || !context.mounted) return;

    final students =
        ref.read(groupStudentsProvider(group.id)).value ?? const <Student>[];
    final after = ExamCalculator(
      items: snapshot.items,
      meta: snapshot.meta,
      scheme: next,
    );
    final changes = previewGradeChanges(
      scoresByStudent: snapshot.scores,
      before: snapshot.calculator,
      after: after,
    ).where((c) => c.gradeChanged && c.after.complete).toList();

    if (changes.isNotEmpty) {
      final names = {for (final s in students) s.id: studentName(s)};
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('exam_grade_changes'.tr()),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'exam_grade_changes_body'.tr(
                    namedArgs: {'count': '${changes.length}'},
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                for (final c in changes)
                  ListTile(
                    dense: true,
                    title: Text(names[c.studentId] ?? '#${c.studentId}'),
                    trailing: Text(
                      '${c.before.grade ?? '–'}  →  ${c.after.grade ?? '–'}',
                    ),
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
              child: Text('apply'.tr()),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(examRepositoryProvider).updateScheme(snapshot.exam.id, next);
  }
}

class _SchemeDialog extends StatefulWidget {
  const _SchemeDialog({
    required this.current,
    required this.scale,
    required this.templates,
  });

  final GradeScheme current;
  final List<GradeScaleEntry> scale;
  final List<({String name, Map<String, double> thresholds})> templates;

  @override
  State<_SchemeDialog> createState() => _SchemeDialogState();
}

class _SchemeDialogState extends State<_SchemeDialog> {
  late final List<(String, TextEditingController)> _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    final byLabel = {
      for (final t in widget.current.thresholds) t.label: t.minPercent,
    };
    final ordered = defaultThresholdsFor(widget.scale);
    _rows = [
      for (final t in ordered)
        (
          t.label,
          TextEditingController(text: _fmt(byLabel[t.label] ?? t.minPercent)),
        ),
    ];
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void dispose() {
    for (final row in _rows) {
      row.$2.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('exam_tab_scheme'.tr()),
      content: SizedBox(
        width: 360,
        child: ListView(
          shrinkWrap: true,
          children: [
            if (widget.templates.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<Map<String, double>>(
                  onSelected: (thresholds) => setState(() {
                    for (final row in _rows) {
                      row.$2.text = _fmt(thresholds[row.$1] ?? 0);
                    }
                  }),
                  itemBuilder: (context) => [
                    for (final t in widget.templates)
                      PopupMenuItem(value: t.thresholds, child: Text(t.name)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.small,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.file_download_outlined),
                        const SizedBox(width: AppSpacing.small),
                        Text('exam_scheme_load_template'.tr()),
                      ],
                    ),
                  ),
                ),
              ),
            for (final row in _rows)
              Row(
                children: [
                  SizedBox(width: 80, child: Text(row.$1)),
                  Expanded(
                    child: TextField(
                      controller: row.$2,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '≥ ',
                        suffixText: '%',
                      ),
                    ),
                  ),
                ],
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.small),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(onPressed: _save, child: Text('save'.tr())),
      ],
    );
  }

  void _save() {
    final thresholds = <GradeThreshold>[];
    double? previous;
    for (final row in _rows) {
      final value = parsePoints(row.$2.text);
      if (value == null || value < 0 || value > 100) {
        setState(() => _error = 'exam_scheme_invalid'.tr());
        return;
      }
      if (previous != null && value > previous) {
        setState(() => _error = 'exam_scheme_order'.tr());
        return;
      }
      previous = value;
      thresholds.add(GradeThreshold(label: row.$1, minPercent: value));
    }
    Navigator.of(context).pop(GradeScheme(thresholds: thresholds));
  }
}
