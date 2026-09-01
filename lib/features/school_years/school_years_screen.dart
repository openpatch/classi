import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/content_constraints.dart';
import 'school_year_editor_sheet.dart';
import 'school_year_repository.dart';

/// Lists the school years timeframes are defined in. Every group is assigned
/// to one year and shares that year's timeframes with the other groups in it.
class SchoolYearsScreen extends ConsumerWidget {
  const SchoolYearsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsValue = ref.watch(schoolYearsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('school_years'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSchoolYear(context, ref),
        icon: const Icon(Icons.add),
        label: Text('add_school_year'.tr()),
      ),
      body: yearsValue.when(
        data: (years) {
          if (years.isEmpty) {
            return Center(
              child: Padding(
                padding: appCardPadding,
                child: Text(
                  'no_school_years'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          final active = years.where((y) => y.archivedAt == null).toList();
          final archived = years.where((y) => y.archivedAt != null).toList();

          return ContentConstraints(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                AppSpacing.large,
                AppSpacing.large,
                96,
              ),
              children: [
                // The app's card theme has no margin, so lists space their
                // own cards. Separators rather than trailing gaps, to keep the
                // spacing even where the archived section starts.
                for (final (index, year) in active.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.medium),
                  _SchoolYearCard(schoolYear: year),
                ],
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    'archived'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  for (final (index, year) in archived.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.medium),
                    _SchoolYearCard(schoolYear: year),
                  ],
                ],
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

  Future<void> _addSchoolYear(BuildContext context, WidgetRef ref) async {
    final startYear = schoolYearStartFor(DateTime.now());
    final existing = await ref
        .read(schoolYearRepositoryProvider)
        .allSchoolYears();
    // Suggest the year after the latest one, so adding years in a row walks
    // forward instead of proposing the same one again.
    final suggested = existing.isEmpty
        ? startYear
        : schoolYearStartFor(existing.first.startDate) + 1;
    if (!context.mounted) return;

    final result = await showSchoolYearEditorSheet(
      context: context,
      initialLabel: defaultSchoolYearLabel(suggested),
      initialStartDate: defaultSchoolYearStart(suggested),
      initialEndDate: defaultSchoolYearEnd(suggested),
    );
    if (result == null) return;

    await ref
        .read(schoolYearRepositoryProvider)
        .createSchoolYear(
          label: result.label,
          startDate: result.startDate,
          endDate: result.endDate,
        );
  }
}

class _SchoolYearCard extends ConsumerWidget {
  const _SchoolYearCard({required this.schoolYear});

  final SchoolYear schoolYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = schoolYear.archivedAt != null;
    final timeframes =
        ref.watch(schoolYearTimeframesProvider(schoolYear.id)).asData?.value ??
        const [];
    final groups =
        ref.watch(schoolYearGroupsProvider(schoolYear.id)).asData?.value ??
        const [];

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.small,
        ),
        title: Text(schoolYear.label),
        subtitle: Text(
          [
            '${formatShortDate(schoolYear.startDate)} – '
                '${formatShortDate(schoolYear.endDate)}',
            'n_timeframes'.tr(
              namedArgs: {'count': timeframes.length.toString()},
            ),
            'n_groups'.tr(namedArgs: {'count': groups.length.toString()}),
          ].join(' · '),
        ),
        leading: Icon(
          archived ? Icons.archive_outlined : Icons.calendar_month_outlined,
        ),
        trailing: PopupMenuButton<_SchoolYearAction>(
          onSelected: (action) => _onAction(context, ref, action),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _SchoolYearAction.edit,
              child: Text('edit'.tr()),
            ),
            PopupMenuItem(
              value: archived
                  ? _SchoolYearAction.unarchive
                  : _SchoolYearAction.archive,
              child: Text(
                archived
                    ? 'unarchive_school_year'.tr()
                    : 'archive_school_year'.tr(),
              ),
            ),
            PopupMenuItem(
              value: _SchoolYearAction.delete,
              child: Text('delete'.tr()),
            ),
          ],
        ),
        onTap: () => context.push('/years/${schoolYear.id}'),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _SchoolYearAction action,
  ) async {
    final repository = ref.read(schoolYearRepositoryProvider);

    switch (action) {
      case _SchoolYearAction.edit:
        final result = await showSchoolYearEditorSheet(
          context: context,
          initialLabel: schoolYear.label,
          initialStartDate: schoolYear.startDate,
          initialEndDate: schoolYear.endDate,
          isEdit: true,
        );
        if (result == null) return;
        await repository.updateSchoolYear(
          id: schoolYear.id,
          label: result.label,
          startDate: result.startDate,
          endDate: result.endDate,
        );
      case _SchoolYearAction.archive:
        final groupCount = await repository.countGroups(schoolYear.id);
        if (!context.mounted) return;
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'archive_school_year'.tr(),
          body: 'archive_school_year_confirmation'.tr(
            namedArgs: {
              'year': schoolYear.label,
              'count': groupCount.toString(),
            },
          ),
          confirmKey: 'archive',
        );
        if (confirmed) await repository.archiveSchoolYear(schoolYear.id);
      case _SchoolYearAction.unarchive:
        await repository.unarchiveSchoolYear(schoolYear.id);
      case _SchoolYearAction.delete:
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'delete_school_year'.tr(),
          body: 'delete_school_year_confirmation'.tr(
            namedArgs: {'year': schoolYear.label},
          ),
        );
        if (confirmed) await repository.deleteSchoolYear(schoolYear.id);
    }
  }
}

enum _SchoolYearAction { edit, archive, unarchive, delete }
