import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/content_constraints.dart';
import '../../shared/widgets/empty_state.dart';
import '../lessons/lesson_support.dart';
import 'today_repository.dart';

/// Landing screen after unlock: every active group's status for today in one
/// place, with a single tap into that group's lesson for today. Replaces
/// having to open each group individually to see whether today's lesson has
/// already been logged.
class TodayDashboardScreen extends ConsumerWidget {
  const TodayDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = normalizeLessonDate(DateTime.now());
    final overviewValue = ref.watch(todayOverviewProvider(today));

    return Scaffold(
      appBar: AppBar(title: Text('today'.tr())),
      body: ContentConstraints(
        child: overviewValue.when(
          data: (overviews) {
            if (overviews.isEmpty) {
              return EmptyState(
                icon: Icons.groups_outlined,
                title: 'empty_groups'.tr(),
              );
            }

            return ListView(
              padding: appScreenPadding,
              children: [
                Text(
                  MaterialLocalizations.of(context).formatFullDate(today),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                for (final overview in overviews) ...[
                  _TodayGroupCard(
                    overview: overview,
                    onOpenLesson: () =>
                        _openLesson(context, overview.group.id, today),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
              ],
            );
          },
          error: (error, _) => const AppErrorState(),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _openLesson(BuildContext context, int groupId, DateTime date) {
    context.push(
      Uri(
        path: '/groups/$groupId/lesson',
        queryParameters: {'date': encodeLessonDate(date)},
      ).toString(),
    );
  }
}

class _TodayGroupCard extends StatelessWidget {
  const _TodayGroupCard({required this.overview, required this.onOpenLesson});

  final TodayGroupOverview overview;
  final VoidCallback onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final group = overview.group;
    final groupColor = colorFromHex(group.colorHex);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenLesson,
        child: Padding(
          padding: appCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: groupColor.withValues(alpha: 0.18),
                    child: CircleAvatar(radius: 5, backgroundColor: groupColor),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              if (overview.hasActivity)
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    _TodayStatChip(
                      icon: Icons.person_off_outlined,
                      label:
                          '${'absent'.tr()}: ${overview.absentCount}/${overview.totalStudents}',
                      emphasize: overview.absentCount > 0,
                    ),
                    _TodayStatChip(
                      icon: Icons.edit_note_outlined,
                      label:
                          '${'grades'.tr()}: ${overview.gradeCount}/${overview.totalStudents}',
                    ),
                    _TodayStatChip(
                      icon: Icons.fact_check_outlined,
                      label:
                          '${'homework'.tr()}: ${overview.homeworkCount}/${overview.totalStudents}',
                    ),
                    _TodayStatChip(
                      icon: Icons.backpack_outlined,
                      label:
                          '${'material'.tr()}: ${overview.materialCount}/${overview.totalStudents}',
                    ),
                  ],
                )
              else
                Text(
                  'lesson_not_started'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.medium),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onOpenLesson,
                  icon: Icon(
                    overview.hasActivity
                        ? Icons.arrow_forward
                        : Icons.play_arrow_outlined,
                  ),
                  label: Text(
                    (overview.hasActivity ? 'continue_lesson' : 'start_lesson')
                        .tr(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStatChip extends StatelessWidget {
  const _TodayStatChip({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = emphasize ? colorScheme.error : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasize
            ? colorScheme.errorContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.small),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
