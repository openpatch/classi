import 'dart:math';

import '../../core/database/app_database.dart';
import 'seating_fit.dart';

/// How much better a rearrangement has to score before it is worth proposing.
const double _minimumGain = 1e-9;

/// Nudges the search towards leaving students where they are: two seatings
/// that satisfy the same rules should differ from the current one as little
/// as possible.
const double _stayBonus = 1e-6;

/// How well [positions] satisfies [relations] as a whole.
///
/// Every rule contributes the weight of the distance between its pair —
/// positively when they belong together, negatively when they have to be kept
/// apart — so a higher score means a seating that breaks fewer rules. Rules
/// naming a student who is not seated contribute nothing.
double seatingPlanScore({
  required List<StudentRelation> relations,
  required Map<int, ({int col, int row})> positions,
}) {
  var total = 0.0;
  for (final relation in relations) {
    final a = positions[relation.studentAId];
    final b = positions[relation.studentBId];
    if (a == null || b == null) continue;
    final weight = seatingFitWeight(_distance(a, b));
    total += relation.isPositive ? weight : -weight;
  }
  return total;
}

/// Proposes a seating that satisfies more of [relations] than [positions].
///
/// The layout stays exactly as the teacher built it: students are only ever
/// swapped between the seats that are already in use, so no chair moves and
/// nobody ends up outside the arrangement. Students no rule mentions can still
/// be swapped — a seat in the middle of the room is sometimes the only way to
/// separate two others — but a seating that scores the same as another wins by
/// moving fewer people.
///
/// Seating is a quadratic assignment, which is too expensive to solve exactly
/// for a class, so this hill-climbs on pairwise swaps from the current seating
/// and from [restarts] shuffled ones and keeps the best result. [seed] makes
/// that search reproducible: the same plan always yields the same suggestion.
///
/// Returns [positions] unchanged when nothing better turns up.
Map<int, ({int col, int row})> suggestSeating({
  required List<StudentRelation> relations,
  required Map<int, ({int col, int row})> positions,
  int restarts = 12,
  int seed = 0,
}) {
  // Sorted, so the search does not depend on the order the positions arrived
  // in and the same plan always gets the same suggestion.
  final students = positions.keys.toList()..sort();
  final seats = [for (final student in students) positions[student]!];

  final pairs = [
    for (final relation in relations)
      if (positions.containsKey(relation.studentAId) &&
          positions.containsKey(relation.studentBId))
        (
          a: students.indexOf(relation.studentAId),
          b: students.indexOf(relation.studentBId),
          sign: relation.isPositive ? 1.0 : -1.0,
        ),
  ];
  if (pairs.isEmpty || students.length < 2) return positions;

  // Distances never change — only who sits where does.
  final distanceWeights = [
    for (final from in seats)
      [for (final to in seats) seatingFitWeight(_distance(from, to))],
  ];

  double score(List<int> seatOfStudent) {
    var total = 0.0;
    for (final pair in pairs) {
      total +=
          pair.sign * distanceWeights[seatOfStudent[pair.a]][seatOfStudent[pair.b]];
    }
    for (var student = 0; student < seatOfStudent.length; student++) {
      if (seatOfStudent[student] == student) total += _stayBonus;
    }
    return total;
  }

  /// Swaps students until no single swap makes the seating any better.
  double climb(List<int> seatOfStudent) {
    var best = score(seatOfStudent);
    for (var improved = true; improved;) {
      improved = false;
      for (var first = 0; first < seatOfStudent.length - 1; first++) {
        for (var second = first + 1; second < seatOfStudent.length; second++) {
          _swap(seatOfStudent, first, second);
          final candidate = score(seatOfStudent);
          if (candidate > best + _minimumGain) {
            best = candidate;
            improved = true;
          } else {
            _swap(seatOfStudent, first, second);
          }
        }
      }
    }
    return best;
  }

  final current = [for (var i = 0; i < students.length; i++) i];
  var bestSeating = List.of(current);
  var bestScore = climb(bestSeating);

  final random = Random(seed);
  for (var restart = 0; restart < restarts; restart++) {
    final attempt = List.of(current)..shuffle(random);
    final attemptScore = climb(attempt);
    if (attemptScore > bestScore + _minimumGain) {
      bestScore = attemptScore;
      bestSeating = attempt;
    }
  }

  if (bestScore <= score(current) + _minimumGain) return positions;

  return {
    for (var student = 0; student < students.length; student++)
      students[student]: seats[bestSeating[student]],
  };
}

double _distance(({int col, int row}) a, ({int col, int row}) b) {
  final dCol = (a.col - b.col).toDouble();
  final dRow = (a.row - b.row).toDouble();
  return sqrt(dCol * dCol + dRow * dRow);
}

void _swap(List<int> values, int first, int second) {
  final held = values[first];
  values[first] = values[second];
  values[second] = held;
}
