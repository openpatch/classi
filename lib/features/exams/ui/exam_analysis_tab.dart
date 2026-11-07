import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/widgets/content_constraints.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/exam_repository.dart';
import '../domain/exam_analysis.dart';
import 'exam_format.dart';

/// Diagnostics: which expectations and tasks the group found hard, how the
/// requirement levels (labels such as AFB I–III) went, and each student's
/// profile across tasks.
class ExamAnalysisTab extends StatelessWidget {
  const ExamAnalysisTab({
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
    final present = [
      for (final s in students)
        if (snapshot.attendanceOf(s.id) == ExamAttendance.present &&
            snapshot.scoresOf(s.id).isNotEmpty)
          s,
    ];
    if (present.isEmpty) {
      return EmptyState(
        icon: Icons.insights_outlined,
        title: 'exam_analysis_empty'.tr(),
      );
    }
    final analysis = ExamAnalysis.of(snapshot, [for (final s in present) s.id]);
    final theme = Theme.of(context);

    Widget bar(double? percent, {double width = 120}) {
      final value = (percent ?? 0) / 100;
      return SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            color: _colorFor(theme, percent),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      );
    }

    String pct(double? p) => p == null ? '–' : '${formatPercent(context, p)} %';

    Widget section(String title, String? hint, List<Widget> children) => Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.xSmall),
              Text(hint, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.medium),
            ...children,
          ],
        ),
      ),
    );

    final tasks = analysis.tasks;
    return ContentConstraints(
      child: ListView(
        padding: appScreenPadding,
        children: [
          section('exam_analysis_tasks'.tr(), 'exam_analysis_tasks_hint'.tr(), [
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xSmall,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(taskKeyHeading(task.key, snapshot.meta)),
                    ),
                    bar(task.percent),
                    SizedBox(
                      width: 56,
                      child: Text(pct(task.percent), textAlign: TextAlign.end),
                    ),
                  ],
                ),
              ),
          ]),
          if (analysis.labels.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            section(
              'exam_analysis_labels'.tr(),
              'exam_analysis_labels_hint'.tr(),
              [
                for (final label in analysis.labels)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xSmall,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(label.key)),
                        bar(label.percent),
                        SizedBox(
                          width: 56,
                          child: Text(
                            pct(label.percent),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          section('exam_analysis_items'.tr(), 'exam_analysis_items_hint'.tr(), [
            for (final item in analysis.items)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xSmall,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        shortTaskLabel(item.key),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.key.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    bar(item.percent, width: 80),
                    SizedBox(
                      width: 56,
                      child: Text(pct(item.percent), textAlign: TextAlign.end),
                    ),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: AppSpacing.large),
          section(
            'exam_analysis_students'.tr(),
            'exam_analysis_students_hint'.tr(),
            [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: AppSpacing.medium,
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 40,
                  columns: [
                    DataColumn(label: Text('students'.tr())),
                    for (final task in tasks)
                      DataColumn(
                        label: Tooltip(
                          message: taskKeyHeading(task.key, snapshot.meta),
                          child: Text(_shortTaskKey(task.key)),
                        ),
                      ),
                  ],
                  rows: [
                    for (final s in present)
                      DataRow(
                        cells: [
                          DataCell(Text(studentName(s))),
                          for (final task in tasks)
                            DataCell(
                              _heatCell(
                                theme,
                                analysis.studentTaskPercent(s.id, task.key),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortTaskKey(String key) {
    if (key == 'additional') return 'exam_additional_short'.tr();
    final task = key.substring(2);
    return key.startsWith('E:')
        ? 'exam_elective_short'.tr(namedArgs: {'task': task})
        : task;
  }

  Widget _heatCell(ThemeData theme, double? percent) {
    if (percent == null) return const Text('–');
    final color = _colorFor(theme, percent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Text('${percent.round()} %'),
    );
  }

  static Color _colorFor(ThemeData theme, double? percent) {
    final p = percent ?? 0;
    if (p < 45) return theme.colorScheme.error;
    if (p < 70) return Colors.orange;
    return Colors.green;
  }
}
