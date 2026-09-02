import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/seating_plan/seating_suggestion.dart';
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

/// Four seats in a row, one behind the other, as a small classroom.
Map<int, ({int col, int row})> _row(List<int> studentIds) {
  return {
    for (var index = 0; index < studentIds.length; index++)
      studentIds[index]: (col: index, row: 0),
  };
}

double _distance(
  Map<int, ({int col, int row})> positions,
  int first,
  int second,
) {
  final a = positions[first]!;
  final b = positions[second]!;
  return ((a.col - b.col).abs() + (a.row - b.row).abs()).toDouble();
}

void main() {
  test('students that belong together are seated next to each other', () {
    final positions = _row([1, 2, 3, 4]);

    final suggestion = suggestSeating(
      relations: [_relation(studentAId: 1, studentBId: 4, isPositive: true)],
      positions: positions,
    );

    expect(_distance(suggestion, 1, 4), 1);
  });

  test('students to keep apart are pulled out of range of each other', () {
    final positions = {
      1: (col: 0, row: 0),
      2: (col: 1, row: 0),
      3: (col: 5, row: 0),
      4: (col: 6, row: 0),
    };

    final suggestion = suggestSeating(
      relations: [_relation(studentAId: 1, studentBId: 2, isPositive: false)],
      positions: positions,
    );

    expect(_distance(suggestion, 1, 2), greaterThan(3));
  });

  test('a suggestion only ever swaps students between the same seats', () {
    final positions = {
      1: (col: 0, row: 0),
      2: (col: 3, row: 1),
      3: (col: 1, row: 2),
      4: (col: 2, row: 0),
    };

    final suggestion = suggestSeating(
      relations: [
        _relation(studentAId: 1, studentBId: 2, isPositive: true),
        _relation(studentAId: 3, studentBId: 4, isPositive: false),
      ],
      positions: positions,
    );

    expect(suggestion.keys.toSet(), positions.keys.toSet());
    expect(suggestion.values.toSet(), positions.values.toSet());
  });

  test('a seating that already fits is left alone', () {
    final positions = _row([1, 2, 3, 4]);

    final suggestion = suggestSeating(
      relations: [_relation(studentAId: 1, studentBId: 2, isPositive: true)],
      positions: positions,
    );

    expect(suggestion, positions);
  });

  test('a plan without rules is left alone', () {
    final positions = _row([1, 2, 3, 4]);

    expect(
      suggestSeating(relations: const [], positions: positions),
      same(positions),
    );
  });

  test('rules naming a student who is not seated are ignored', () {
    final positions = _row([1, 2]);

    expect(
      suggestSeating(
        relations: [_relation(studentAId: 1, studentBId: 9, isPositive: false)],
        positions: positions,
      ),
      same(positions),
    );
  });

  test('students no rule mentions keep their seat where they can', () {
    final positions = _row([1, 2, 3, 4]);

    final suggestion = suggestSeating(
      relations: [_relation(studentAId: 1, studentBId: 3, isPositive: true)],
      positions: positions,
    );

    // Seating 1 and 3 together only needs the two of them to trade places
    // with a neighbour; the rest of the class should not be reshuffled.
    final moved = positions.keys
        .where((student) => suggestion[student] != positions[student])
        .toSet();
    expect(moved.length, lessThanOrEqualTo(2));
  });

  test('the same plan always yields the same suggestion', () {
    final positions = {
      1: (col: 0, row: 0),
      2: (col: 1, row: 0),
      3: (col: 2, row: 0),
      4: (col: 0, row: 1),
      5: (col: 1, row: 1),
      6: (col: 2, row: 1),
    };
    final relations = [
      _relation(studentAId: 1, studentBId: 6, isPositive: true),
      _relation(studentAId: 2, studentBId: 5, isPositive: false),
      _relation(studentAId: 3, studentBId: 4, isPositive: true),
    ];

    expect(
      suggestSeating(relations: relations, positions: positions),
      suggestSeating(relations: relations, positions: positions),
    );
  });

  test('a suggestion scores better than the seating it replaces', () {
    final positions = {
      1: (col: 0, row: 0),
      2: (col: 1, row: 0),
      3: (col: 2, row: 0),
      4: (col: 0, row: 1),
      5: (col: 1, row: 1),
      6: (col: 2, row: 1),
    };
    final relations = [
      _relation(studentAId: 1, studentBId: 2, isPositive: false),
      _relation(studentAId: 1, studentBId: 6, isPositive: true),
      _relation(studentAId: 3, studentBId: 5, isPositive: true),
    ];

    final suggestion = suggestSeating(
      relations: relations,
      positions: positions,
    );

    expect(
      seatingPlanScore(relations: relations, positions: suggestion),
      greaterThan(
        seatingPlanScore(relations: relations, positions: positions),
      ),
    );
  });

  test('the score counts a rule by how close its pair sits', () {
    final relations = [
      _relation(studentAId: 1, studentBId: 2, isPositive: false),
    ];

    expect(
      seatingPlanScore(
        relations: relations,
        positions: {1: (col: 0, row: 0), 2: (col: 1, row: 0)},
      ),
      -1,
    );
    expect(
      seatingPlanScore(
        relations: relations,
        positions: {1: (col: 0, row: 0), 2: (col: 9, row: 0)},
      ),
      0,
    );
  });
}
