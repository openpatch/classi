import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/surface_list_tile.dart';
import '../exam_providers.dart';
import 'exam_actions.dart';

/// Exams of a group on the group page.
class ExamsCard extends ConsumerWidget {
  const ExamsCard({required this.group, required this.archived, super.key});

  final Group group;
  final bool archived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exams = ref.watch(groupExamsProvider(group.id));
    final dateFormat = DateFormat.yMMMd(context.locale.toLanguageTag());
    final scale = parseGradeScaleEntries(group.gradeScaleJson);

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text('exams'.tr(), style: theme.textTheme.titleMedium),
                ),
                if (!archived)
                  FilledButton.tonalIcon(
                    onPressed: () => createExam(context, ref, group),
                    icon: const Icon(Icons.add),
                    label: Text('exam_add'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            exams.when(
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'exams_empty'.tr(),
                    style: theme.textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: [
                    for (final exam in list)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: _ExamTile(
                          exam: exam,
                          subtitle:
                              '${dateFormat.format(exam.date)} · ${exam.categoryName}',
                          scale: scale,
                        ),
                      ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('$error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamTile extends ConsumerWidget {
  const _ExamTile({
    required this.exam,
    required this.subtitle,
    required this.scale,
  });

  final Exam exam;
  final String subtitle;
  final List<GradeScaleEntry> scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(examSnapshotProvider(exam.id)).value;
    String? summary;
    if (snapshot != null) {
      final grades = <double>[];
      final calculator = snapshot.calculator;
      for (final studentId in snapshot.scores.keys) {
        final participant = snapshot.participants[studentId];
        if (participant != null && participant.status != 'present') continue;
        final override = participant?.gradeOverride;
        final result = calculator.compute(snapshot.scoresOf(studentId));
        final grade = override ?? (result.complete ? result.grade : null);
        final numeric = grade == null ? null : gradeValueToNumber(grade, scale);
        if (numeric != null) grades.add(numeric);
      }
      summary = grades.isEmpty
          ? null
          : 'exam_card_summary'.tr(
              namedArgs: {
                'count': '${grades.length}',
                'mean': formatNumber(
                  grades.reduce((a, b) => a + b) / grades.length,
                ),
              },
            );
    }
    return SurfaceListTile(
      leading: Icon(
        exam.source == 'typst'
            ? Icons.description_outlined
            : Icons.assignment_outlined,
      ),
      title: Text(exam.title),
      subtitle: Text(summary == null ? subtitle : '$subtitle · $summary'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(examLocation(exam.groupId, exam.id)),
    );
  }
}
