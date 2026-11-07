import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/utils/formatting.dart';
import '../domain/exam_calculator.dart';
import '../domain/exam_structure.dart';

/// Points with up to two decimals in the app's locale: `1,5` in German.
String formatPoints(BuildContext context, double value) {
  return NumberFormat('#,##0.##', context.locale.toLanguageTag()).format(value);
}

String formatPercent(BuildContext context, double value) {
  return NumberFormat('#,##0', context.locale.toLanguageTag()).format(value);
}

/// Accepts `1,5` and `1.5`; empty means "no points entered".
double? parsePoints(String raw) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

/// Heading of the task an item belongs to: "Aufgabe 2: Titel",
/// "Wahlaufgabe 3", "Zusatz".
String taskHeading(ExamItem item, ExamStructureMeta meta) {
  switch (item.kind) {
    case ExpectationKind.additional:
      return 'exam_additional'.tr();
    case ExpectationKind.elective:
      final title = meta.electiveTaskTitles[item.task];
      final base = 'exam_elective_task'.tr(namedArgs: {'task': item.task});
      return title == null ? base : '$base: $title';
    case ExpectationKind.regular:
    case ExpectationKind.alternative:
      final title = meta.taskTitles[item.task];
      final base = 'exam_task'.tr(namedArgs: {'task': item.task});
      return title == null ? base : '$base: $title';
  }
}

/// Heading of a task key as used by [StudentExamResult.tasks].
String taskKeyHeading(String taskKey, ExamStructureMeta meta) {
  if (taskKey == 'additional') return 'exam_additional'.tr();
  final task = taskKey.substring(2);
  final elective = taskKey.startsWith('E:');
  final title = (elective ? meta.electiveTaskTitles : meta.taskTitles)[task];
  final base = elective
      ? 'exam_elective_task'.tr(namedArgs: {'task': task})
      : 'exam_task'.tr(namedArgs: {'task': task});
  return title == null ? base : '$base: $title';
}

/// Short task label for narrow columns: "2a", "W3", "Z".
String shortTaskLabel(ExamItem item) {
  final part = item.part ?? '';
  return switch (item.kind) {
    ExpectationKind.additional => 'exam_additional_short'.tr(),
    ExpectationKind.elective => 'exam_elective_short'.tr(
      namedArgs: {'task': '${item.task}$part'},
    ),
    _ => '${item.task}$part',
  };
}

/// Items grouped by task, in order.
List<({String taskKey, List<ExamItem> items})> groupByTask(
  List<ExamItem> items,
) {
  final result = <({String taskKey, List<ExamItem> items})>[];
  for (final item in items) {
    if (result.isNotEmpty && result.last.taskKey == item.taskKey) {
      result.last.items.add(item);
    } else {
      result.add((taskKey: item.taskKey, items: [item]));
    }
  }
  return result;
}

String studentName(Student student) => studentDisplayName(
  firstName: student.firstName,
  lastName: student.lastName,
  callName: student.callName,
);

enum ExamStudentStatus {
  complete,
  incomplete,
  notStarted,
  absent,
  excused,
  overridden,
}

ExamStudentStatus statusOf({
  required StudentExamResult result,
  required String attendance,
  required bool hasOverride,
  required bool hasScores,
}) {
  if (attendance == 'absent') return ExamStudentStatus.absent;
  if (attendance == 'excused') return ExamStudentStatus.excused;
  if (hasOverride) return ExamStudentStatus.overridden;
  if (result.complete) return ExamStudentStatus.complete;
  return hasScores
      ? ExamStudentStatus.incomplete
      : ExamStudentStatus.notStarted;
}

IconData iconForStatus(ExamStudentStatus status) => switch (status) {
  ExamStudentStatus.complete => Icons.check_circle_outline,
  ExamStudentStatus.incomplete => Icons.pending_outlined,
  ExamStudentStatus.notStarted => Icons.radio_button_unchecked,
  ExamStudentStatus.absent => Icons.person_off_outlined,
  ExamStudentStatus.excused => Icons.event_busy_outlined,
  ExamStudentStatus.overridden => Icons.gavel_outlined,
};

String labelForStatus(ExamStudentStatus status) => switch (status) {
  ExamStudentStatus.complete => 'exam_status_complete'.tr(),
  ExamStudentStatus.incomplete => 'exam_status_incomplete'.tr(),
  ExamStudentStatus.notStarted => 'exam_status_not_started'.tr(),
  ExamStudentStatus.absent => 'exam_status_absent'.tr(),
  ExamStudentStatus.excused => 'exam_status_excused'.tr(),
  ExamStudentStatus.overridden => 'exam_status_overridden'.tr(),
};
