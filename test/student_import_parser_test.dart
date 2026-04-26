import 'package:classi/features/students/student_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseWebUntisStudentText imports tab-separated WebUntis exports', () {
    const source =
        'Langname\tVorname\tKlasse\tGeschlecht\tEintrittsdatum\tAustrittsdatum\tE-Mail Adresse\tMobiltelefon\tTelefonnummer\n'
        'Amarantidis\tLeandros\t06B\t\t\t\tleandros@example.com\t\t\n'
        'Dahmani\tRayane\t06B\t\t\t\trayane@example.com\t\t\n';

    final students = parseWebUntisStudentText(source);

    expect(students, hasLength(2));
    expect(students.first.firstName, 'Leandros');
    expect(students.first.lastName, 'Amarantidis');
    expect(students.last.firstName, 'Rayane');
    expect(students.last.lastName, 'Dahmani');
  });

  test('parseWebUntisStudentText rejects files without WebUntis columns', () {
    expect(
      () => parseWebUntisStudentText('First name,Last name\nAda,Lovelace\n'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'webuntis_missing_columns',
        ),
      ),
    );
  });

  test('parseStudentBatchText supports line based batch creation', () {
    final students = parseStudentBatchText(
      'Ada Lovelace\nTuring, Alan\nGrace\tHopper',
    );

    expect(students, hasLength(3));
    expect(students[0].firstName, 'Ada');
    expect(students[0].lastName, 'Lovelace');
    expect(students[1].firstName, 'Alan');
    expect(students[1].lastName, 'Turing');
    expect(students[2].firstName, 'Grace');
    expect(students[2].lastName, 'Hopper');
  });
}
