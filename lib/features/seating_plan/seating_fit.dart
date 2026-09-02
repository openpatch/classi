import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/theme/app_ui.dart';

/// How many cells away a classmate can sit and still affect a fit score.
const double kSeatingFitRadius = 3;

/// How heavily a classmate [distance] cells away weighs on a fit score.
///
/// The weight falls off with the square of the distance, so a directly
/// adjacent seat counts a full point, a diagonal one half of that, and a
/// classmate further away than [kSeatingFitRadius] not at all.
double seatingFitWeight(double distance) {
  if (distance <= 0 || distance > kSeatingFitRadius) return 0;
  return 1 / (distance * distance);
}

/// How well a student's seat matches the rules that mention them.
///
/// [score] runs from `-1` (sitting right next to someone they must be kept
/// apart from) to `1` (sitting right next to someone they belong with). The
/// two id lists name the classmates in range that produced it.
typedef SeatingFit = ({
  double score,
  List<int> supportingStudentIds,
  List<int> conflictingStudentIds,
});

/// Scores every seat in [positions] against [relations].
///
/// Only students that both sit on the plan and appear in at least one rule
/// within [kSeatingFitRadius] get an entry; everyone else has nothing to say
/// about their seat and is left out.
Map<int, SeatingFit> calculateSeatingFit({
  required List<StudentRelation> relations,
  required Map<int, ({int col, int row})> positions,
}) {
  final scores = <int, double>{};
  final supporting = <int, List<int>>{};
  final conflicting = <int, List<int>>{};

  for (final relation in relations) {
    final a = positions[relation.studentAId];
    final b = positions[relation.studentBId];
    if (a == null || b == null) continue;

    final dCol = (a.col - b.col).toDouble();
    final dRow = (a.row - b.row).toDouble();
    final weight = seatingFitWeight(sqrt(dCol * dCol + dRow * dRow));
    if (weight == 0) continue;

    final delta = relation.isPositive ? weight : -weight;
    final partners = {
      relation.studentAId: relation.studentBId,
      relation.studentBId: relation.studentAId,
    };
    for (final entry in partners.entries) {
      scores[entry.key] = (scores[entry.key] ?? 0) + delta;
      (relation.isPositive ? supporting : conflicting)
          .putIfAbsent(entry.key, () => [])
          .add(entry.value);
    }
  }

  return {
    for (final entry in scores.entries)
      entry.key: (
        score: entry.value.clamp(-1.0, 1.0),
        supportingStudentIds: supporting[entry.key] ?? const <int>[],
        conflictingStudentIds: conflicting[entry.key] ?? const <int>[],
      ),
  };
}

/// The background tint for a seat scored [score], or `null` when the seat is
/// neutral and should stay uncoloured.
///
/// Green means the neighbours fit, red means they clash; the further from
/// zero, the more saturated. The hues are picked per brightness so a tint
/// stays visible on a dark surface too.
Color? seatingFitColor(BuildContext context, double? score) {
  if (score == null || score == 0) return null;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final base = score > 0
      ? (isDark ? const Color(0xFF6ADF8E) : const Color(0xFF2E7D32))
      : (isDark ? const Color(0xFFFF8A80) : const Color(0xFFC62828));
  return base.withValues(alpha: 0.12 + 0.28 * score.abs());
}

/// Explains what the green and red seat tints mean.
class SeatingFitLegend extends StatelessWidget {
  const SeatingFitLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.large,
      runSpacing: AppSpacing.xSmall,
      children: [
        _LegendEntry(score: 1, label: 'seating_fit_good'.tr()),
        _LegendEntry(score: -1, label: 'seating_fit_bad'.tr()),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.score, required this.label});

  final double score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: seatingFitColor(context, score),
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
        ),
        const SizedBox(width: AppSpacing.xSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
