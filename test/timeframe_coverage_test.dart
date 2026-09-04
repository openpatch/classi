import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/school_years/timeframe_coverage.dart';
import 'package:flutter_test/flutter_test.dart';

SchoolYear _year() => SchoolYear(
  id: 1,
  label: '2025/26',
  startDate: DateTime(2025, 8, 1),
  endDate: DateTime(2026, 7, 31),
  createdAt: DateTime(2025, 8, 1),
  updatedAt: DateTime(2025, 8, 1),
);

Timeframe _timeframe(int id, DateTime start, DateTime end) => Timeframe(
  id: id,
  schoolYearId: 1,
  label: 'T$id',
  startDate: start,
  endDate: end,
  createdAt: DateTime(2025, 8, 1),
  updatedAt: DateTime(2025, 8, 1),
);

void main() {
  test('two halves that meet cover the year', () {
    final coverage = TimeframeCoverage.of(
      schoolYear: _year(),
      timeframes: [
        _timeframe(1, DateTime(2025, 8, 1), DateTime(2026, 1, 31)),
        _timeframe(2, DateTime(2026, 2, 1), DateTime(2026, 7, 31)),
      ],
    );

    expect(coverage.isComplete, isTrue);
  });

  test('a missing month between timeframes is a gap', () {
    final coverage = TimeframeCoverage.of(
      schoolYear: _year(),
      timeframes: [
        _timeframe(1, DateTime(2025, 8, 1), DateTime(2025, 12, 31)),
        _timeframe(2, DateTime(2026, 2, 1), DateTime(2026, 7, 31)),
      ],
    );

    expect(coverage.hasGap, isTrue);
    expect(coverage.reachesOutsideYear, isFalse);
  });

  test('starting after the school year starts is a gap', () {
    final coverage = TimeframeCoverage.of(
      schoolYear: _year(),
      timeframes: [
        _timeframe(1, DateTime(2025, 9, 1), DateTime(2026, 7, 31)),
      ],
    );

    expect(coverage.hasGap, isTrue);
  });

  test('ending before the school year ends is a gap', () {
    final coverage = TimeframeCoverage.of(
      schoolYear: _year(),
      timeframes: [
        _timeframe(1, DateTime(2025, 8, 1), DateTime(2026, 6, 30)),
      ],
    );

    expect(coverage.hasGap, isTrue);
  });

  test('a timeframe running past the year is reported separately', () {
    final coverage = TimeframeCoverage.of(
      schoolYear: _year(),
      timeframes: [
        _timeframe(1, DateTime(2025, 8, 1), DateTime(2026, 8, 15)),
      ],
    );

    expect(coverage.reachesOutsideYear, isTrue);
    expect(coverage.hasGap, isFalse);
  });

  test('overlapping timeframes still count as covered', () {
    final coverage = TimeframeCoverage.of(
      schoolYear: _year(),
      timeframes: [
        _timeframe(1, DateTime(2025, 8, 1), DateTime(2026, 3, 31)),
        _timeframe(2, DateTime(2026, 1, 1), DateTime(2026, 7, 31)),
      ],
    );

    expect(coverage.isComplete, isTrue);
  });

  test('no timeframes is not reported as a gap', () {
    final coverage = TimeframeCoverage.of(
      schoolYear: _year(),
      timeframes: const [],
    );

    expect(coverage.isComplete, isTrue);
  });
}
