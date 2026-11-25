import 'dart:developer' as developer;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/empty_state.dart';
import '../schedule/lesson_schedule.dart';
import '../schedule/weekly_timetable.dart';
import 'webuntis_api.dart';
import 'webuntis_lesson_sync.dart';

Future<void> showWebUntisLessonSyncSheet({
  required BuildContext context,
  int? groupId,
  DateTime? weekStart,
  int? schoolYearId,
}) async {
  final result = await showModalBottomSheet<WebUntisLessonSyncResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _WebUntisLessonSyncSheet(
      groupId: groupId,
      weekStart: mondayOf(weekStart ?? DateTime.now()),
      schoolYearId: schoolYearId,
    ),
  );
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'webuntis_lessons_synced'.tr(
            namedArgs: {
              'added': '${result.added}',
              'updated': '${result.updated}',
              'skipped': '${result.skipped}',
            },
          ),
        ),
      ),
    );
  }
}

class _WebUntisLessonSyncSheet extends ConsumerStatefulWidget {
  const _WebUntisLessonSyncSheet({
    required this.weekStart,
    this.groupId,
    this.schoolYearId,
  });

  final DateTime weekStart;
  final int? groupId;

  /// The school year the quick "whole school year" range uses; the active
  /// one when `null`.
  final int? schoolYearId;

  @override
  ConsumerState<_WebUntisLessonSyncSheet> createState() =>
      _WebUntisLessonSyncSheetState();
}

class _WebUntisLessonSyncSheetState
    extends ConsumerState<_WebUntisLessonSyncSheet> {
  late DateTimeRange _range = DateTimeRange(
    start: widget.weekStart,
    end: addDays(widget.weekStart, 6),
  );
  final _selected = <int>{};
  WebUntisLessonPreview? _preview;
  bool _loading = true;
  bool _importing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
      _selected.clear();
    });
    try {
      final preview = await ref
          .read(webUntisLessonSyncProvider)
          .load(
            start: _range.start,
            end: _range.end,
            groupId: widget.groupId,
            schoolYearId:
                widget.schoolYearId ?? ref.read(activeSchoolYearIdProvider),
          );
      if (!mounted) return;
      ref.invalidate(bellTimesProvider);
      setState(() {
        _preview = preview;
        // Existing lessons are selected too: updating one only takes over
        // what its WebUntis register says, and does nothing when it is empty.
        _selected.addAll([
          for (var index = 0; index < preview.lessons.length; index++) index,
        ]);
      });
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error, StackTrace stackTrace) {
    developer.log(
      'Failed to sync lessons from WebUntis',
      name: 'classi.webuntis',
      error: error,
      stackTrace: stackTrace,
    );
    if (mounted) {
      setState(
        () => _error = error is WebUntisException
            ? error.translationKey.tr()
            : 'generic_error'.tr(),
      );
    }
  }

  Future<void> _chooseRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (range == null || !mounted) return;
    setState(() => _range = range);
    await _load();
  }

  /// Sets the range to the school year so far: from its first day up to
  /// today, or its last day once it is over. Lessons still to come are left
  /// out, since WebUntis has no topic or attendance for them yet.
  Future<void> _chooseSchoolYear(SchoolYear year) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateUtils.dateOnly(year.startDate);
    final yearEnd = DateUtils.dateOnly(year.endDate);
    final end = today.isBefore(yearEnd) ? today : yearEnd;
    setState(
      () => _range = DateTimeRange(
        start: start,
        end: end.isBefore(start) ? start : end,
      ),
    );
    await _load();
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await ref.read(webUntisLessonSyncProvider).importLessons([
        for (final index in _selected) _preview!.lessons[index],
      ]);
      if (!mounted) return;
      ref.invalidate(webUntisConnectionProvider);
      Navigator.of(context).pop(result);
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final schoolYearId =
        widget.schoolYearId ?? ref.watch(activeSchoolYearIdProvider);
    final schoolYear = schoolYearId == null
        ? null
        : ref.watch(schoolYearProvider(schoolYearId)).value;
    return PopScope(
      canPop: !_importing,
      child: Padding(
        padding: appCardPadding,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'webuntis_sync_lessons'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.small),
              Text('webuntis_sync_lessons_hint'.tr()),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading || _importing ? null : _chooseRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      '${material.formatMediumDate(_range.start)}'
                      ' – ${material.formatMediumDate(_range.end)}',
                    ),
                  ),
                  if (schoolYear != null)
                    Tooltip(
                      message: 'webuntis_sync_school_year_hint'.tr(),
                      child: TextButton.icon(
                        onPressed: _loading || _importing
                            ? null
                            : () => _chooseSchoolYear(schoolYear),
                        icon: const Icon(Icons.school_outlined),
                        label: Text('webuntis_sync_school_year'.tr()),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              if (_preview case final preview?
                  when preview.unmapped > 0 && preview.lessons.isNotEmpty)
                Text(
                  'webuntis_lessons_unmapped'.tr(
                    namedArgs: {'count': '${preview.unmapped}'},
                  ),
                ),
              if (_error case final error?) ...[
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton.icon(
                  onPressed: _importing ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: Text('retry'.tr()),
                ),
              ],
              Expanded(child: _body()),
              const SizedBox(height: AppSpacing.medium),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: AppSpacing.small,
                overflowSpacing: AppSpacing.small,
                overflowAlignment: OverflowBarAlignment.end,
                children: [
                  TextButton(
                    onPressed: _importing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  FilledButton(
                    onPressed: _loading || _importing || _selected.isEmpty
                        ? null
                        : _import,
                    child: _importing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'webuntis_sync_selected_lessons'.tr(
                              namedArgs: {'count': '${_selected.length}'},
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final preview = _preview;
    if (preview == null) return const SizedBox.shrink();
    if (!preview.hasLinkedGroups || preview.lessons.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.event_busy_outlined,
          title:
              (preview.unmapped > 0
                      ? 'webuntis_lessons_unmapped_title'
                      : 'webuntis_roster_no_lessons')
                  .tr(),
          body: preview.unmapped > 0
              ? 'webuntis_lessons_unmapped'.tr(
                  namedArgs: {'count': '${preview.unmapped}'},
                )
              : (preview.hasLinkedGroups
                        ? 'webuntis_sync_lessons_empty'
                        : 'webuntis_sync_lessons_no_groups')
                    .tr(),
        ),
      );
    }
    return ListView.builder(
      itemCount: preview.lessons.length,
      itemBuilder: (context, index) {
        final item = preview.lessons[index];
        final periods = formatPeriodRange(
          item.lesson.periodStart,
          item.lesson.periodEnd,
        );
        return CheckboxListTile(
          value: _selected.contains(index),
          onChanged: _importing
              ? null
              : (selected) => setState(() {
                  if (selected == true) {
                    _selected.add(index);
                  } else {
                    _selected.remove(index);
                  }
                }),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.groupName),
              const SizedBox(height: AppSpacing.xSmall),
              Chip(
                avatar: Icon(
                  item.alreadyExists ? Icons.sync : Icons.add_circle_outline,
                  size: 18,
                ),
                label: Text(
                  (item.alreadyExists
                          ? 'webuntis_lesson_update'
                          : 'webuntis_lesson_create')
                      .tr(),
                ),
                visualDensity: VisualDensity.compact,
                backgroundColor: item.alreadyExists
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Theme.of(context).colorScheme.primaryContainer,
                side: BorderSide.none,
              ),
            ],
          ),
          subtitle: Text(
            [
              MaterialLocalizations.of(
                context,
              ).formatFullDate(item.lesson.date),
              'periods_short'.tr(namedArgs: {'periods': periods}),
              item.categoryName,
            ].join(' · '),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }
}
