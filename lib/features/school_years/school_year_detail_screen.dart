import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/utils/grade_categories.dart' show colorFromHex;
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/content_constraints.dart';
import '../groups/timeframe_editor_sheet.dart';
import '../groups/timeframe_repository.dart';
import 'school_year_repository.dart';
import 'timeframe_coverage.dart';

/// The timeframes of a single school year, plus the groups that share them.
class SchoolYearDetailScreen extends ConsumerWidget {
  const SchoolYearDetailScreen({required this.schoolYearId, super.key});

  final int schoolYearId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearValue = ref.watch(schoolYearProvider(schoolYearId));
    final schoolYear = yearValue.asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text(schoolYear?.label ?? 'school_years'.tr())),
      floatingActionButton: schoolYear == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addTimeframe(context, ref, schoolYear),
              icon: const Icon(Icons.add),
              label: Text('add_timeframe'.tr()),
            ),
      body: yearValue.when(
        data: (year) {
          if (year == null) {
            return Center(child: Text('school_year_not_found'.tr()));
          }
          return ContentConstraints(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                AppSpacing.large,
                AppSpacing.large,
                96,
              ),
              children: [
                _TimeframesCard(schoolYear: year),
                const SizedBox(height: AppSpacing.large),
                _GroupsCard(schoolYearId: year.id),
              ],
            ),
          );
        },
        error: (error, stackTrace) => Center(
          child: AppErrorText(error: error, stackTrace: stackTrace),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _addTimeframe(
    BuildContext context,
    WidgetRef ref,
    SchoolYear schoolYear,
  ) async {
    final result = await showTimeframeEditorSheet(
      context: context,
      schoolYear: schoolYear,
      timeframeRepository: ref.read(timeframeRepositoryProvider),
    );
    if (result == null) return;

    await ref
        .read(timeframeRepositoryProvider)
        .saveTimeframe(
          schoolYearId: schoolYear.id,
          label: result.label,
          startDate: result.startDate,
          endDate: result.endDate,
        );
  }
}

class _TimeframesCard extends ConsumerWidget {
  const _TimeframesCard({required this.schoolYear});

  final SchoolYear schoolYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframesValue = ref.watch(
      schoolYearTimeframesProvider(schoolYear.id),
    );

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'timeframes'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'timeframes_shared_hint'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            timeframesValue.when(
              data: (timeframes) => timeframes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.large,
                      ),
                      child: Text(
                        'no_timeframes'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < timeframes.length; i++) ...[
                          _timeframeTile(context, ref, timeframes[i]),
                          if (i < timeframes.length - 1)
                            const Divider(height: 1),
                        ],
                        _CoverageNotice(
                          coverage: TimeframeCoverage.of(
                            schoolYear: schoolYear,
                            timeframes: timeframes,
                          ),
                        ),
                      ],
                    ),
              error: (error, stackTrace) =>
                  AppErrorText(error: error, stackTrace: stackTrace),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeframeTile(
    BuildContext context,
    WidgetRef ref,
    Timeframe timeframe,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(timeframe.label),
      subtitle: Text(
        '${formatShortDate(timeframe.startDate)} – '
        '${formatShortDate(timeframe.endDate)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _editTimeframe(context, ref, timeframe),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'edit'.tr(),
          ),
          IconButton(
            onPressed: () => _deleteTimeframe(context, ref, timeframe),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'delete'.tr(),
          ),
        ],
      ),
    );
  }

  Future<void> _editTimeframe(
    BuildContext context,
    WidgetRef ref,
    Timeframe timeframe,
  ) async {
    final result = await showTimeframeEditorSheet(
      context: context,
      schoolYear: schoolYear,
      timeframeRepository: ref.read(timeframeRepositoryProvider),
      initialLabel: timeframe.label,
      initialStartDate: timeframe.startDate,
      initialEndDate: timeframe.endDate,
      timeframeId: timeframe.id,
    );
    if (result == null) return;

    await ref
        .read(timeframeRepositoryProvider)
        .updateTimeframe(
          id: timeframe.id,
          label: result.label,
          startDate: result.startDate,
          endDate: result.endDate,
        );
  }

  Future<void> _deleteTimeframe(
    BuildContext context,
    WidgetRef ref,
    Timeframe timeframe,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'delete_timeframe'.tr(),
      body: 'delete_timeframe_confirmation'.tr(),
    );
    if (!confirmed) return;

    await ref
        .read(timeframeGradeRepositoryProvider)
        .deleteGradesForTimeframe(timeframe.id);
    await ref.read(timeframeRepositoryProvider).deleteTimeframe(timeframe.id);
  }
}

class _GroupsCard extends ConsumerWidget {
  const _GroupsCard({required this.schoolYearId});

  final int schoolYearId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsValue = ref.watch(schoolYearGroupsProvider(schoolYearId));

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('groups'.tr(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.medium),
            groupsValue.when(
              data: (groups) => groups.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.large,
                      ),
                      child: Text(
                        'no_groups_in_school_year'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final group in groups)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: colorFromHex(group.colorHex),
                              radius: 12,
                            ),
                            title: Text(group.name),
                            subtitle: group.archivedAt == null
                                ? null
                                : Text('archived'.tr()),
                            onTap: () => context.push('/groups/${group.id}'),
                          ),
                      ],
                    ),
              error: (error, stackTrace) =>
                  AppErrorText(error: error, stackTrace: stackTrace),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Points out that a year's timeframes leave a gap or spill past the year.
///
/// Deliberately an inline note rather than a blocking dialog: an unusual term
/// structure is the teacher's business, and the app should only make sure it
/// was not an accident.
class _CoverageNotice extends StatelessWidget {
  const _CoverageNotice({required this.coverage});

  final TimeframeCoverage coverage;

  @override
  Widget build(BuildContext context) {
    if (coverage.isComplete) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final messages = [
      if (coverage.hasGap) 'timeframe_coverage_gap'.tr(),
      if (coverage.reachesOutsideYear) 'timeframe_outside_school_year'.tr(),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              messages.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
