import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../attendance/attendance_repository.dart';
import 'webuntis_api.dart';
import 'webuntis_attendance_mapping.dart';

/// Imports the absences WebUntis recorded for a class into Classi's
/// attendance log.
///
/// Returns what was written, or `null` when the teacher backed out.
Future<AttendanceImportResult?> showWebUntisAttendanceImportSheet({
  required BuildContext context,
  required int groupId,
  required int klasseId,
}) {
  return showModalBottomSheet<AttendanceImportResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _WebUntisAttendanceImportSheet(groupId: groupId, klasseId: klasseId),
  );
}

class _WebUntisAttendanceImportSheet extends ConsumerStatefulWidget {
  const _WebUntisAttendanceImportSheet({
    required this.groupId,
    required this.klasseId,
  });

  final int groupId;
  final int klasseId;

  @override
  ConsumerState<_WebUntisAttendanceImportSheet> createState() =>
      _WebUntisAttendanceImportSheetState();
}

class _WebUntisAttendanceImportSheetState
    extends ConsumerState<_WebUntisAttendanceImportSheet> {
  late DateTimeRange _range;

  bool _loading = false;
  bool _importing = false;
  bool _overwriteExisting = false;
  String? _error;

  List<({int studentId, DateTime date, bool excused})>? _entries;
  Set<int> _unmatched = const {};
  int _absenceCount = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 30)),
      end: DateTime(today.year, today.month, today.day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.locale.toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxLarge,
        right: AppSpacing.xxLarge,
        top: AppSpacing.xxLarge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxLarge,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'webuntis_import_attendance'.tr(),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'webuntis_import_attendance_hint'.tr(),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.large),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range),
                title: Text(
                  '${dateFormat.format(_range.start)} – '
                  '${dateFormat.format(_range.end)}',
                ),
                subtitle: Text('webuntis_date_range'.tr()),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _importing ? null : _pickRange,
              ),
              const SizedBox(height: AppSpacing.small),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _overwriteExisting,
                title: Text('webuntis_overwrite_existing'.tr()),
                subtitle: Text('webuntis_overwrite_existing_hint'.tr()),
                onChanged: _importing
                    ? null
                    : (value) => setState(() => _overwriteExisting = value),
              ),
              const SizedBox(height: AppSpacing.large),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error case final message?)
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                )
              else if (_entries case final entries?)
                _Preview(
                  days: entries.length,
                  absences: _absenceCount,
                  unmatched: _unmatched.length,
                ),
              const SizedBox(height: AppSpacing.large),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _importing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  if (_entries == null)
                    FilledButton.icon(
                      onPressed: _loading ? null : _preview,
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: Text('webuntis_fetch_absences'.tr()),
                    )
                  else
                    FilledButton(
                      onPressed: _entries!.isEmpty || _importing
                          ? null
                          : _import,
                      child: _importing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('webuntis_apply_import'.tr()),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _range = picked;
      // The range changed, so the fetched preview no longer describes it.
      _entries = null;
      _unmatched = const {};
      _absenceCount = 0;
      _error = null;
    });
  }

  Future<void> _preview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final absences = await ref
          .read(webUntisServiceProvider)
          .loadAbsences(
            from: _range.start,
            to: _range.end,
            klasseId: widget.klasseId,
          );

      final studentIds = await ref
          .read(studentRepositoryProvider)
          .webUntisStudentIds(widget.groupId);

      final days = expandAbsenceDays(
        absences,
        from: _range.start,
        to: _range.end,
      );
      final resolved = resolveAbsenceDays(days, studentIds);

      if (!mounted) {
        return;
      }
      setState(() {
        _absenceCount = absences.length;
        _entries = resolved.entries;
        _unmatched = resolved.unmatchedStudentIds;
        _loading = false;
      });
    } on WebUntisException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.translationKey.tr();
          _loading = false;
        });
      }
    }
  }

  Future<void> _import() async {
    final entries = _entries;
    if (entries == null || entries.isEmpty) {
      return;
    }

    setState(() => _importing = true);

    try {
      final result = await ref
          .read(attendanceRepositoryProvider)
          .importAbsences(
            absences: entries,
            overwriteExisting: _overwriteExisting,
          );
      await ref.read(webUntisServiceProvider).markSynced();

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.days,
    required this.absences,
    required this.unmatched,
  });

  final int days;
  final int absences;
  final int unmatched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'webuntis_preview_summary'.tr(
            namedArgs: {
              'days': days.toString(),
              'absences': absences.toString(),
            },
          ),
          style: theme.textTheme.bodyMedium,
        ),
        if (unmatched > 0) ...[
          const SizedBox(height: AppSpacing.small),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'webuntis_preview_unmatched'.tr(
                    namedArgs: {'count': unmatched.toString()},
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
