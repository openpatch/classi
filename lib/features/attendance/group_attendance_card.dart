import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_error_state.dart';
import 'attendance_statistics.dart';

final groupAttendanceProvider = StreamProvider.autoDispose
    .family<List<AttendanceLog>, int>(
      (ref, groupId) => ref
          .watch(attendanceRepositoryProvider)
          .watchAttendanceForGroup(groupId),
    );

/// Attendance of the whole class: how many lessons were held, the class's
/// attendance rate, and who missed the most, for the whole year or one term.
class GroupAttendanceCard extends ConsumerStatefulWidget {
  const GroupAttendanceCard({
    required this.groupId,
    required this.students,
    super.key,
  });

  final int groupId;
  final List<Student> students;

  @override
  ConsumerState<GroupAttendanceCard> createState() =>
      _GroupAttendanceCardState();
}

class _GroupAttendanceCardState extends ConsumerState<GroupAttendanceCard> {
  static const _collapsedCount = 5;

  int? _timeframeId;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final logsValue = ref.watch(groupAttendanceProvider(widget.groupId));
    final timeframes =
        ref.watch(groupTimeframesProvider(widget.groupId)).value ??
        const <Timeframe>[];
    Timeframe? timeframe;
    for (final candidate in timeframes) {
      if (candidate.id == _timeframeId) timeframe = candidate;
    }

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'class_attendance'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (timeframes.isNotEmpty)
                  DropdownButton<int?>(
                    value: timeframe?.id,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('class_attendance_all'.tr()),
                      ),
                      for (final candidate in timeframes)
                        DropdownMenuItem<int?>(
                          value: candidate.id,
                          child: Text(candidate.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _timeframeId = value),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            logsValue.when(
              data: (logs) => _buildStats(
                context,
                computeGroupAttendanceStats(
                  studentIds: [for (final s in widget.students) s.id],
                  logs: timeframe == null
                      ? logs
                      : logs.where((log) => _within(log.date, timeframe!)),
                ),
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

  static bool _within(DateTime date, Timeframe timeframe) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      timeframe.startDate.year,
      timeframe.startDate.month,
      timeframe.startDate.day,
    );
    final end = DateTime(
      timeframe.endDate.year,
      timeframe.endDate.month,
      timeframe.endDate.day,
    );
    return !day.isBefore(start) && !day.isAfter(end);
  }

  Widget _buildStats(BuildContext context, GroupAttendanceStats stats) {
    final theme = Theme.of(context);
    if (stats.lessons == 0) {
      return Text(
        'class_attendance_empty'.tr(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final sortField = ref.watch(studentSortFieldProvider);
    final studentsById = {for (final s in widget.students) s.id: s};
    final rate = stats.attendanceRate;
    final rows = _showAll
        ? stats.students
        : stats.students.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            Chip(
              avatar: const Icon(Icons.event_available_outlined, size: 18),
              label: Text(
                'class_attendance_lessons'.tr(
                  namedArgs: {'count': '${stats.lessons}'},
                ),
              ),
            ),
            if (rate != null)
              Chip(
                avatar: const Icon(Icons.percent, size: 18),
                label: Text(
                  'class_attendance_rate'.tr(
                    namedArgs: {'rate': _percent(rate)},
                  ),
                ),
              ),
            Chip(
              avatar: const Icon(Icons.person_off_outlined, size: 18),
              label: Text(
                'class_attendance_absences'.tr(
                  namedArgs: {
                    'count': '${stats.absent}',
                    'excused': '${stats.excused}',
                  },
                ),
              ),
            ),
            Chip(
              avatar: const Icon(Icons.schedule_outlined, size: 18),
              label: Text(
                'class_attendance_late'.tr(
                  namedArgs: {'count': '${stats.late}'},
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _AttendanceRow(
          name: Text(
            'name'.tr(),
            style: theme.textTheme.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          absent: 'absent'.tr(),
          excused: 'excused'.tr(),
          late: 'late'.tr(),
          rate: '%',
          header: true,
        ),
        const Divider(height: 1),
        for (final student in rows)
          if (studentsById[student.studentId] case final record?)
            InkWell(
              onTap: () => context.push('/students/${record.id}'),
              child: _AttendanceRow(
                name: Text(
                  studentDisplayName(
                    firstName: record.firstName,
                    lastName: record.lastName,
                    callName: record.callName,
                    sortField: sortField,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                absent: '${student.absent}',
                excused: '${student.excused}',
                late: '${student.late}',
                rate: switch (student.attendanceRate) {
                  final rate? => _percent(rate),
                  null => '–',
                },
                highlight: student.unexcused > 0,
              ),
            ),
        if (stats.students.length > _collapsedCount)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll
                    ? 'show_less'.tr()
                    : 'show_all_count'.tr(
                        namedArgs: {'count': '${stats.students.length}'},
                      ),
              ),
            ),
          ),
      ],
    );
  }

  static String _percent(double rate) => '${(rate * 100).toStringAsFixed(0)} %';
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.name,
    required this.absent,
    required this.excused,
    required this.late,
    required this.rate,
    this.header = false,
    this.highlight = false,
  });

  final Widget name;
  final String absent;
  final String excused;
  final String late;
  final String rate;
  final bool header;

  /// The student has unexcused absences.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = header
        ? theme.textTheme.labelLarge
        : theme.textTheme.bodyMedium;
    Widget cell(String text, {TextStyle? textStyle}) => Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textStyle ?? style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Expanded(flex: 3, child: name),
          cell(
            absent,
            textStyle: highlight
                ? style?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  )
                : null,
          ),
          cell(excused),
          cell(late),
          cell(rate),
        ],
      ),
    );
  }
}
