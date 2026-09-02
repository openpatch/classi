import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/seating_plan/seating_fit.dart';
import 'package:flutter_test/flutter_test.dart';

StudentRelation _relation({
  required int studentAId,
  required int studentBId,
  required bool isPositive,
}) {
  return StudentRelation(
    id: studentAId * 100 + studentBId,
    studentAId: studentAId,
    studentBId: studentBId,
    isPositive: isPositive,
    createdAt: DateTime(2026),
  );
}

void main() {
  test('an adjacent conflict scores the worst possible fit', () {
    final fits = calculateSeatingFit(
      relations: [_relation(studentAId: 1, studentBId: 2, isPositive: false)],
      positions: {1: (col: 0, row: 0), 2: (col: 1, row: 0)},
    );

    expect(fits[1]!.score, -1);
    expect(fits[2]!.score, -1);
    expect(fits[1]!.conflictingStudentIds, [2]);
    expect(fits[1]!.supportingStudentIds, isEmpty);
  });

  test('an adjacent match scores the best possible fit', () {
    final fits = calculateSeatingFit(
      relations: [_relation(studentAId: 1, studentBId: 2, isPositive: true)],
      positions: {1: (col: 0, row: 0), 2: (col: 0, row: 1)},
    );

    expect(fits[1]!.score, 1);
    expect(fits[1]!.supportingStudentIds, [2]);
  });

  test('a diagonal neighbour counts half of an adjacent one', () {
    final fits = calculateSeatingFit(
      relations: [_relation(studentAId: 1, studentBId: 2, isPositive: false)],
      positions: {1: (col: 0, row: 0), 2: (col: 1, row: 1)},
    );

    expect(fits[1]!.score, closeTo(-0.5, 1e-9));
  });

  test('the weight falls off with distance and stops past the radius', () {
    expect(seatingFitWeight(1), 1);
    expect(seatingFitWeight(2), 0.25);
    expect(seatingFitWeight(kSeatingFitRadius), closeTo(1 / 9, 1e-9));
    expect(seatingFitWeight(kSeatingFitRadius + 0.01), 0);
  });

  test('students seated further apart than the radius do not score', () {
    final fits = calculateSeatingFit(
      relations: [_relation(studentAId: 1, studentBId: 2, isPositive: false)],
      positions: {1: (col: 0, row: 0), 2: (col: 4, row: 0)},
    );

    expect(fits, isEmpty);
  });

  test('a rule with an unplaced student is ignored', () {
    final fits = calculateSeatingFit(
      relations: [_relation(studentAId: 1, studentBId: 2, isPositive: true)],
      positions: {1: (col: 0, row: 0)},
    );

    expect(fits, isEmpty);
  });

  test('a good and a bad neighbour at the same distance cancel out', () {
    final fits = calculateSeatingFit(
      relations: [
        _relation(studentAId: 1, studentBId: 2, isPositive: true),
        _relation(studentAId: 1, studentBId: 3, isPositive: false),
      ],
      positions: {
        1: (col: 1, row: 0),
        2: (col: 0, row: 0),
        3: (col: 2, row: 0),
      },
    );

    expect(fits[1]!.score, 0);
    expect(fits[1]!.supportingStudentIds, [2]);
    expect(fits[1]!.conflictingStudentIds, [3]);
    expect(fits[2]!.score, 1);
    expect(fits[3]!.score, -1);
  });

  test('several conflicts at range stay within the score bounds', () {
    final fits = calculateSeatingFit(
      relations: [
        _relation(studentAId: 1, studentBId: 2, isPositive: false),
        _relation(studentAId: 1, studentBId: 3, isPositive: false),
      ],
      positions: {
        1: (col: 1, row: 1),
        2: (col: 0, row: 1),
        3: (col: 2, row: 1),
      },
    );

    expect(fits[1]!.score, -1);
  });
}
