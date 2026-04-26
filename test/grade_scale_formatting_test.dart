import 'package:classi/shared/utils/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nearest grade label is used for extended grade averages', () {
    expect(
      gradeLabelForNumericValue(1.15, defaultExtendedGradeScaleEntries),
      '1',
    );
    expect(
      gradeLabelForNumericValue(0.82, defaultExtendedGradeScaleEntries),
      '1+',
    );
    expect(
      gradeLabelForNumericValue(1.24, defaultExtendedGradeScaleEntries),
      '1-',
    );
  });
}
