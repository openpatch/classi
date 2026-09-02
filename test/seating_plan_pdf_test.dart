import 'package:classi/features/seating_plan/seating_plan_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a seating plan renders the seats into a document', () async {
    final bytes = await buildSeatingPlanPdf(
      title: '8A',
      subtitle: 'Main plan',
      nameById: const {1: 'Ada Lovelace', 2: 'Grace Hopper'},
      positions: const {1: (col: 0, row: 0), 2: (col: 1, row: 0)},
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(bytes.skip(bytes.length - 6)), contains('EOF'));

    // The seats are what makes the document bigger than an empty plan; without
    // them there would be nothing to check but "it did not throw".
    final empty = await buildSeatingPlanPdf(
      title: '8A',
      nameById: const {},
      positions: const {},
    );
    expect(bytes.length, greaterThan(empty.length));
  });

  test('a plan nobody sits on still renders', () async {
    final bytes = await buildSeatingPlanPdf(
      title: '8A',
      nameById: const {1: 'Ada Lovelace'},
      positions: const {},
      unplacedLabel: 'Not seated',
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('a plan with gaps between the seats renders', () async {
    // Positions can start anywhere and leave holes — the plan is the room, not
    // a dense grid.
    final bytes = await buildSeatingPlanPdf(
      title: '8A',
      nameById: const {1: 'Ada Lovelace', 2: 'Grace Hopper'},
      positions: const {1: (col: 2, row: 1), 2: (col: 5, row: 3)},
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('students without a seat do not fall off the page', () async {
    final bytes = await buildSeatingPlanPdf(
      title: '8A',
      nameById: const {1: 'Ada Lovelace', 2: 'Grace Hopper'},
      positions: const {1: (col: 0, row: 0)},
      unplacedLabel: 'Not seated',
    );

    final seatedOnly = await buildSeatingPlanPdf(
      title: '8A',
      nameById: const {1: 'Ada Lovelace'},
      positions: const {1: (col: 0, row: 0)},
    );
    expect(bytes.length, greaterThan(seatedOnly.length));
  });
}
