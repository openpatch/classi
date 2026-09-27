import 'package:classi/features/grades/grade_distribution.dart';
import 'package:classi/features/grades/grade_round_screen.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts every grade of the scale, in scale order', () {
    final distribution = computeGradeDistribution([
      '2',
      '3',
      '2',
      '6',
      ' ',
      '2-',
    ], defaultGradeScaleEntries);

    expect(distribution.counts.map((e) => e.label), [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
    ]);
    expect(distribution.counts.map((e) => e.count), [0, 2, 1, 0, 0, 1]);
    expect(distribution.otherCount, 1);
    expect(distribution.total, 5);
    expect(distribution.maxCount, 2);
    expect(distribution.mean, closeTo((2 + 3 + 2 + 6) / 4, 1e-9));
  });

  test('has no mean when nothing was graded', () {
    final distribution = computeGradeDistribution(
      const [],
      defaultGradeScaleEntries,
    );

    expect(distribution.total, 0);
    expect(distribution.mean, isNull);
  });

  group('matchGradeInput', () {
    final points = [for (var p = 15; p >= 0; p--) '$p'];

    test('takes a grade no longer grade starts with', () {
      expect(matchGradeInput('7', points), (
        match: '7',
        complete: true,
        viable: true,
      ));
      expect(matchGradeInput('12', points).complete, isTrue);
    });

    test('waits when a longer grade could still follow', () {
      expect(matchGradeInput('1', points), (
        match: '1',
        complete: false,
        viable: true,
      ));
      expect(matchGradeInput('1', ['1', '1+', '1-', '2']).complete, isFalse);
    });

    test('rejects what no grade starts with', () {
      expect(matchGradeInput('9', ['1', '2', '3']).viable, isFalse);
      expect(matchGradeInput('17', points).viable, isFalse);
    });
  });
}
