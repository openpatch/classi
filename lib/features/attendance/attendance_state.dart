import '../../core/database/app_database.dart';

/// What a student is in a lesson, as far as attendance goes.
enum AttendanceState { present, absent, late }

extension AttendanceLogCounting on AttendanceLog {
  /// Whether the student missed the lesson. A student away at a school
  /// activity was not in the room either, but that lesson is not missed.
  bool get isMissed => isAbsent && !isActivity;

  /// Away at a school activity other than an exam.
  bool get isAwayAtActivity => isAbsent && isActivity && !isExam;

  /// Away writing an exam elsewhere.
  bool get isAwayAtExam => isAbsent && isActivity && isExam;
}
