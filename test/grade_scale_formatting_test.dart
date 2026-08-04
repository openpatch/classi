import 'package:classi/features/students/student_sorting.dart';
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

  test('student display name follows the selected sort field', () {
    expect(
      studentDisplayName(
        firstName: 'Max',
        lastName: 'Mustermann',
        sortField: StudentSortField.firstName,
      ),
      'Max Mustermann',
    );
    expect(
      studentDisplayName(
        firstName: 'Max',
        lastName: 'Mustermann',
        sortField: StudentSortField.lastName,
      ),
      'Mustermann, Max',
    );
  });

  test('call name replaces first name when set, surname always shown', () {
    expect(
      studentDisplayName(
        firstName: 'Alexander',
        lastName: 'Mustermann',
        callName: 'Alex',
        sortField: StudentSortField.firstName,
      ),
      'Alex Mustermann',
    );
    expect(
      studentDisplayName(
        firstName: 'Alexander',
        lastName: 'Mustermann',
        callName: 'Alex',
        sortField: StudentSortField.lastName,
      ),
      'Mustermann, Alex',
    );
  });

  test('a blank or unset call name falls back to the first name', () {
    expect(
      studentDisplayName(
        firstName: 'Alexander',
        lastName: 'Mustermann',
        callName: null,
      ),
      'Mustermann, Alexander',
    );
    expect(
      studentDisplayName(
        firstName: 'Alexander',
        lastName: 'Mustermann',
        callName: '   ',
      ),
      'Mustermann, Alexander',
    );
  });

  test('generated student names are recognized in both supported orders', () {
    expect(
      isGeneratedStudentDisplayName(
        value: 'Max Mustermann',
        firstName: 'Max',
        lastName: 'Mustermann',
      ),
      isTrue,
    );
    expect(
      isGeneratedStudentDisplayName(
        value: 'Mustermann, Max',
        firstName: 'Max',
        lastName: 'Mustermann',
      ),
      isTrue,
    );
    expect(
      isGeneratedStudentDisplayName(
        value: 'Presentation topic',
        firstName: 'Max',
        lastName: 'Mustermann',
      ),
      isFalse,
    );
  });

  test('generated name recognition uses the call name when set', () {
    expect(
      isGeneratedStudentDisplayName(
        value: 'Mustermann, Alex',
        firstName: 'Alexander',
        lastName: 'Mustermann',
        callName: 'Alex',
      ),
      isTrue,
    );
    expect(
      isGeneratedStudentDisplayName(
        value: 'Mustermann, Alexander',
        firstName: 'Alexander',
        lastName: 'Mustermann',
        callName: 'Alex',
      ),
      isFalse,
    );
  });
}
