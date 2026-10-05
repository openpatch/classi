import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../lessons/lesson_periods.dart';
import 'webuntis_api.dart';
import 'webuntis_link.dart';
import 'webuntis_models.dart';

/// What WebUntis has for one class on one day, pulled live.
///
/// Keyed by the group's link, the calendar day and the lesson's periods, so
/// two lessons of one group on a day each see their own WebUntis lessons.
/// Nothing is stored and nothing is written back: the class
/// register is the source of truth for what WebUntis says, and the lesson
/// itself only changes when the teacher takes something over.
final webUntisLessonDayProvider = FutureProvider.autoDispose
    .family<WebUntisLessonDay, (WebUntisGroupLink, DateTime, LessonPeriods?)>(
      (ref, key) {
        final (link, date, periods) = key;
        return ref
            .watch(webUntisServiceProvider)
            .loadLessonDay(link: link, date: date, periods: periods);
      },
      // Riverpod retries a failed provider up to ten times by default and
      // reports loading meanwhile: the box spun for most of a minute and
      // asked WebUntis ten times before it showed why. A WebUntis error does
      // not go away within seconds; the refresh button is the retry.
      retry: (_, _) => null,
    );

/// Longest topic a lesson can hold, matching `sessions_table.label`.
const int _maxTopicLength = 120;

/// Turns WebUntis topics into a single-line lesson topic.
///
/// A register topic is free text that often runs over several lines, while a
/// lesson topic is one short line, so line breaks collapse to spaces, several
/// topics are joined, and the result is cut to what the lesson can store.
String webUntisTopicAsLessonTopic(List<String> topics) {
  final joined = topics
      .map((topic) => topic.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((topic) => topic.isNotEmpty)
      .join(' / ');
  if (joined.length <= _maxTopicLength) {
    return joined;
  }
  return '${joined.substring(0, _maxTopicLength - 1).trimRight()}…';
}

/// WebUntis attendance translated onto a group's students.
typedef WebUntisGroupAttendance = ({
  /// The students WebUntis can speak for: those with a WebUntis id.
  Set<int> linkedStudentIds,

  /// Absent students by Classi id, mapped to whether the day is excused.
  Map<int, bool> absences,

  /// Students who came late, by Classi id.
  Set<int> late,

  /// Absent students away at a school activity, by Classi id.
  Set<int> activity,

  /// Those of [activity] who were writing an exam elsewhere.
  Set<int> exam,

  /// Absent students WebUntis names that are not in the group.
  int unmatchedAbsences,
});

/// Maps [day]'s absences onto [students] by WebUntis id.
WebUntisGroupAttendance webUntisAttendanceForGroup(
  WebUntisLessonDay day,
  List<Student> students,
) {
  final byWebUntisId = {
    for (final student in students) ?student.webuntisStudentId: student.id,
  };

  final absences = <int, bool>{};
  final late = <int>{};
  var unmatched = 0;
  for (final MapEntry(key: webUntisId, value: excused)
      in day.absences.entries) {
    final studentId = byWebUntisId[webUntisId];
    if (studentId == null) {
      unmatched++;
    } else {
      absences[studentId] = excused;
    }
  }

  for (final webUntisId in day.late) {
    final studentId = byWebUntisId[webUntisId];
    if (studentId == null) {
      unmatched++;
    } else {
      late.add(studentId);
    }
  }

  return (
    linkedStudentIds: byWebUntisId.values.toSet(),
    absences: absences,
    late: late,
    activity: {
      for (final webUntisId in day.activity) ?byWebUntisId[webUntisId],
    },
    exam: {for (final webUntisId in day.exam) ?byWebUntisId[webUntisId]},
    unmatchedAbsences: unmatched,
  );
}

/// Whether the lesson's attendance already says what WebUntis says, looking
/// only at the students WebUntis knows.
bool webUntisAttendanceMatches(
  WebUntisGroupAttendance attendance, {
  required Set<int> absentStudents,
  required Set<int> excusedStudents,
  Set<int> lateStudents = const {},
  Set<int> activityStudents = const {},
  Set<int> examStudents = const {},
}) {
  for (final studentId in attendance.linkedStudentIds) {
    if (attendance.late.contains(studentId) !=
        lateStudents.contains(studentId)) {
      return false;
    }
    if (attendance.activity.contains(studentId) !=
        activityStudents.contains(studentId)) {
      return false;
    }
    if (attendance.exam.contains(studentId) !=
        examStudents.contains(studentId)) {
      return false;
    }
    final excused = attendance.absences[studentId];
    if ((excused != null) != absentStudents.contains(studentId)) {
      return false;
    }
    if (excused != null && excused != excusedStudents.contains(studentId)) {
      return false;
    }
  }
  return true;
}

/// Shows what WebUntis has for a lesson day, the topic and the attendance,
/// each with a button to take it over.
///
/// Renders nothing when the library has no WebUntis connection. Nothing in
/// the lesson changes unless the teacher presses one of the buttons.
class WebUntisLessonPanel extends ConsumerWidget {
  const WebUntisLessonPanel({
    required this.link,
    required this.date,
    this.periods,
    required this.localTopic,
    required this.onApplyTopic,
    required this.students,
    required this.absentStudents,
    required this.excusedStudents,
    this.lateStudents = const {},
    this.activityStudents = const {},
    this.examStudents = const {},
    super.key,
  });

  final WebUntisGroupLink link;
  final DateTime date;

  /// The lesson's periods; `null` for a whole-day entry, which sees every
  /// lesson of the day.
  final LessonPeriods? periods;
  final String localTopic;
  final ValueChanged<String> onApplyTopic;
  final List<Student> students;
  final Set<int> absentStudents;
  final Set<int> excusedStudents;
  final Set<int> lateStudents;
  final Set<int> activityStudents;
  final Set<int> examStudents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(webUntisConnectionProvider).value;
    if (connection == null) {
      return const SizedBox.shrink();
    }

    final day = DateTime(date.year, date.month, date.day);
    final key = (link, day, periods);
    final dayValue = ref.watch(webUntisLessonDayProvider(key));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final Widget body = dayValue.when(
      loading: () => Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.medium),
          Text('webuntis_lesson_loading'.tr(), style: muted),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error is WebUntisException
                ? error.translationKey.tr()
                : 'webuntis_error_generic'.tr(),
            style: muted?.copyWith(color: theme.colorScheme.error),
          ),
          // The technical reason, so a teacher can pass it on when WebUntis
          // does something Classi did not expect.
          SelectableText('$error', style: muted),
        ],
      ),
      data: (lessonDay) {
        if (lessonDay.lessonCount == 0) {
          return Text('webuntis_lesson_none'.tr(), style: muted);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'webuntis_matched_lessons'.tr(
                namedArgs: {
                  'times': lessonDay.lessons
                      .map(
                        (lesson) =>
                            '${_clock(lesson.startDateTime)}–${_clock(lesson.endDateTime)}',
                      )
                      .join(', '),
                },
              ),
              style: muted,
            ),
            const SizedBox(height: AppSpacing.medium),
            _TopicSection(
              topics: lessonDay.topics,
              localTopic: localTopic,
              onApply: onApplyTopic,
            ),
            const SizedBox(height: AppSpacing.large),
            _AttendanceSection(
              periods: periods,
              lessonDay: lessonDay,
              date: day,
              students: students,
              absentStudents: absentStudents,
              excusedStudents: excusedStudents,
              lateStudents: lateStudents,
              activityStudents: activityStudents,
              examStudents: examStudents,
            ),
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('webuntis'.tr(), style: theme.textTheme.titleSmall),
            ),
            IconButton(
              onPressed: dayValue.isLoading
                  ? null
                  : () => ref.invalidate(webUntisLessonDayProvider(key)),
              icon: const Icon(Icons.refresh),
              tooltip: 'webuntis_lesson_refresh'.tr(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        body,
      ],
    );
  }
}

String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

class _TopicSection extends StatelessWidget {
  const _TopicSection({
    required this.topics,
    required this.localTopic,
    required this.onApply,
  });

  final List<String> topics;
  final String localTopic;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final lessonTopic = webUntisTopicAsLessonTopic(topics);
    final local = localTopic.trim();
    final same = lessonTopic == local;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('webuntis_topic'.tr(), style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xSmall),
        if (topics.isEmpty)
          Text('webuntis_topic_none'.tr(), style: muted)
        else
          SelectableText(topics.join('\n'), style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.small),
        if (same && topics.isNotEmpty)
          Text('webuntis_topic_applied'.tr(), style: muted),
        if (topics.isNotEmpty && !same)
          FilledButton.tonalIcon(
            onPressed: () => onApply(lessonTopic),
            icon: const Icon(Icons.download_outlined),
            label: Text('webuntis_topic_apply'.tr()),
          ),
      ],
    );
  }
}

class _AttendanceSection extends ConsumerWidget {
  const _AttendanceSection({
    required this.periods,
    required this.lessonDay,
    required this.date,
    required this.students,
    required this.absentStudents,
    required this.excusedStudents,
    required this.lateStudents,
    required this.activityStudents,
    required this.examStudents,
  });

  final LessonPeriods? periods;
  final WebUntisLessonDay lessonDay;
  final DateTime date;
  final List<Student> students;
  final Set<int> absentStudents;
  final Set<int> excusedStudents;
  final Set<int> lateStudents;
  final Set<int> activityStudents;
  final Set<int> examStudents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final children = <Widget>[
      Text('webuntis_attendance'.tr(), style: theme.textTheme.labelLarge),
      const SizedBox(height: AppSpacing.xSmall),
    ];

    final attendance = webUntisAttendanceForGroup(lessonDay, students);
    if (attendance.linkedStudentIds.isEmpty) {
      children.add(Text('webuntis_attendance_not_linked'.tr(), style: muted));
      return _column(children);
    }

    final sortField = ref.watch(studentSortFieldProvider);
    String name(Student student) => studentDisplayName(
      firstName: student.firstName,
      lastName: student.lastName,
      callName: student.callName,
      sortField: sortField,
    );

    if (!lessonDay.attendanceTaken) {
      children.add(Text('webuntis_attendance_not_taken'.tr(), style: muted));
    } else {
      final absent = [
        for (final student in students)
          if (attendance.absences[student.id] case final excused?)
            attendance.exam.contains(student.id)
                ? '${name(student)} (${'exam_elsewhere'.tr()})'
                : attendance.activity.contains(student.id)
                ? '${name(student)} (${'activity'.tr()})'
                : excused
                ? '${name(student)} (${'excused'.tr()})'
                : name(student),
      ];
      final late = [
        for (final student in students)
          if (attendance.late.contains(student.id)) name(student),
      ];
      children.add(
        Text(
          absent.isEmpty
              ? 'webuntis_attendance_all_present'.tr()
              : 'webuntis_attendance_absent'.tr(
                  namedArgs: {'names': absent.join('; ')},
                ),
          style: theme.textTheme.bodyMedium,
        ),
      );
      if (late.isNotEmpty) {
        children.add(
          Text(
            'webuntis_attendance_late'.tr(
              namedArgs: {'names': late.join('; ')},
            ),
            style: theme.textTheme.bodyMedium,
          ),
        );
      }
      if (attendance.unmatchedAbsences > 0) {
        children.add(
          Text(
            'webuntis_attendance_unmatched'.tr(
              namedArgs: {'count': attendance.unmatchedAbsences.toString()},
            ),
            style: muted,
          ),
        );
      }
    }

    final matches = webUntisAttendanceMatches(
      attendance,
      absentStudents: absentStudents,
      excusedStudents: excusedStudents,
      lateStudents: lateStudents,
      activityStudents: activityStudents,
      examStudents: examStudents,
    );

    children.add(const SizedBox(height: AppSpacing.small));
    if (matches) {
      children.add(Text('webuntis_attendance_applied'.tr(), style: muted));
    } else if (lessonDay.attendanceTaken) {
      children.add(
        FilledButton.tonalIcon(
          onPressed: () => ref
              .read(attendanceRepositoryProvider)
              .applyAttendanceForDate(
                date: date,
                periodStart: periods?.start ?? 0,
                studentIds: attendance.linkedStudentIds,
                absences: attendance.absences,
                late: attendance.late,
                activity: attendance.activity,
                exam: attendance.exam,
              ),
          icon: const Icon(Icons.download_outlined),
          label: Text('webuntis_attendance_apply'.tr()),
        ),
      );
    }

    return _column(children);
  }

  Widget _column(List<Widget> children) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
}
