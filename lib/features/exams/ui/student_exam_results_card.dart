import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_ui.dart';
import '../data/exam_repository.dart';
import '../domain/exam_calculator.dart';
import '../exam_providers.dart';
import 'exam_actions.dart';
import 'exam_format.dart';
import 'exam_screen.dart';

/// One student's exams side by side: points, grade and the share of points
/// per task. Weak tasks stand out across exams.
class StudentExamResultsCard extends ConsumerWidget {
  const StudentExamResultsCard({
    required this.groupId,
    required this.studentId,
    super.key,
  });

  final int groupId;
  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(groupExamsProvider(groupId)).value ?? const [];
    final rows = <(ExamSnapshot, StudentExamResult)>[];
    for (final exam in exams) {
      final snapshot = ref.watch(examSnapshotProvider(exam.id)).value;
      if (snapshot == null) continue;
      if (snapshot.attendanceOf(studentId) != ExamAttendance.present) continue;
      final scores = snapshot.scoresOf(studentId);
      if (scores.isEmpty) continue;
      rows.add((snapshot, snapshot.calculator.compute(scores)));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(context.locale.toLanguageTag());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: Card(
        child: Padding(
          padding: appCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'exam_student_results'.tr(),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.small),
              for (final (snapshot, result) in rows)
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  onTap: () => context.push(
                    examStudentLocation(groupId, snapshot.exam.id, studentId),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.small,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${snapshot.exam.title} · ${dateFormat.format(snapshot.exam.date)}',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              '${formatPoints(context, result.total)} / ${formatPoints(context, result.maxPoints)} · '
                              '${formatPercent(context, result.percent)} %'
                              '${_grade(snapshot, result)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Wrap(
                          spacing: AppSpacing.xSmall,
                          runSpacing: AppSpacing.xSmall,
                          children: [
                            for (final task in result.tasks.values)
                              if (task.maxPoints > 0 && task.counted)
                                _TaskChip(
                                  label: taskKeyHeading(
                                    task.taskKey,
                                    snapshot.meta,
                                  ),
                                  percent: task.points / task.maxPoints * 100,
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () =>
                    context.push(examLocation(groupId, rows.first.$1.exam.id)),
                child: Text('exam_open_latest'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _grade(ExamSnapshot snapshot, StudentExamResult result) {
    final override = snapshot.participants[studentId]?.gradeOverride;
    final grade = override ?? (result.complete ? result.grade : null);
    return grade == null ? '' : ' · $grade';
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.label, required this.percent});

  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = percent < 45
        ? theme.colorScheme.error
        : percent < 70
        ? Colors.orange
        : Colors.green;
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          '${label.length > 18 ? '${label.substring(0, 18)}…' : label} ${percent.round()} %',
          style: theme.textTheme.labelSmall,
        ),
      ),
    );
  }
}
