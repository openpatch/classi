import '../../core/database/app_database.dart';

/// What a school year's timeframes do and don't cover.
///
/// Surfaced as a warning rather than enforced as a rule: irregular term
/// structures are normal (trimesters, a year that starts mid-September, a
/// deliberately unassessed block), so the app points out the gap and leaves the
/// judgement to the teacher.
class TimeframeCoverage {
  const TimeframeCoverage({
    required this.hasGap,
    required this.reachesOutsideYear,
  });

  /// Part of the school year is not covered by any timeframe.
  final bool hasGap;

  /// At least one timeframe starts before or ends after the school year.
  final bool reachesOutsideYear;

  bool get isComplete => !hasGap && !reachesOutsideYear;

  /// Analyses [timeframes] against the bounds of [schoolYear].
  ///
  /// An empty list reports no gap: "you have not set up timeframes yet" is
  /// already said by the empty state, and repeating it as a warning would make
  /// every new school year look broken.
  factory TimeframeCoverage.of({
    required SchoolYear schoolYear,
    required List<Timeframe> timeframes,
  }) {
    if (timeframes.isEmpty) {
      return const TimeframeCoverage(hasGap: false, reachesOutsideYear: false);
    }

    final sorted = [...timeframes]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final yearStart = _dateOnly(schoolYear.startDate);
    final yearEnd = _dateOnly(schoolYear.endDate);

    final reachesOutside =
        _dateOnly(sorted.first.startDate).isBefore(yearStart) ||
        sorted.any((t) => _dateOnly(t.endDate).isAfter(yearEnd));

    var hasGap = _dateOnly(sorted.first.startDate).isAfter(yearStart);

    // A timeframe ending on the 31st and the next starting on the 1st is
    // contiguous, so only a difference of more than one day is a gap.
    var covered = _dateOnly(sorted.first.endDate);
    for (final timeframe in sorted.skip(1)) {
      final start = _dateOnly(timeframe.startDate);
      if (start.difference(covered).inDays > 1) {
        hasGap = true;
      }
      final end = _dateOnly(timeframe.endDate);
      if (end.isAfter(covered)) {
        covered = end;
      }
    }

    if (covered.isBefore(yearEnd)) {
      hasGap = true;
    }

    return TimeframeCoverage(
      hasGap: hasGap,
      reachesOutsideYear: reachesOutside,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
