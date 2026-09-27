import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';

/// How often each grade of a scale was given, e.g. in one test.
class GradeDistribution {
  const GradeDistribution({
    required this.counts,
    required this.otherCount,
    required this.mean,
  });

  /// Count per grade, in the order of the grade scale. Grades nobody got are
  /// listed with 0, so the chart always shows the whole scale.
  final List<({String label, int count})> counts;

  /// Values that are not on the scale, e.g. from before the scale changed.
  final int otherCount;

  /// Mean of the numeric values, `null` when nothing counts.
  final double? mean;

  int get total => counts.fold(otherCount, (sum, entry) => sum + entry.count);

  int get maxCount => counts.fold(
    otherCount,
    (max, entry) => entry.count > max ? entry.count : max,
  );
}

GradeDistribution computeGradeDistribution(
  Iterable<String> values,
  List<GradeScaleEntry> gradeScale,
) {
  final counts = {for (final entry in gradeScale) entry.label: 0};
  var otherCount = 0;
  var sum = 0.0;
  var numericCount = 0;

  for (final raw in values) {
    final value = raw.trim();
    if (value.isEmpty) {
      continue;
    }
    if (counts.containsKey(value)) {
      counts[value] = counts[value]! + 1;
    } else {
      otherCount++;
    }
    final number = gradeValueToNumber(value, gradeScale);
    if (number != null) {
      sum += number;
      numericCount++;
    }
  }

  return GradeDistribution(
    counts: [
      for (final entry in gradeScale)
        (label: entry.label, count: counts[entry.label]!),
    ],
    otherCount: otherCount,
    mean: numericCount == 0 ? null : sum / numericCount,
  );
}

/// A bar per grade of the scale with how many students got it, and the mean
/// underneath: the "Notenspiegel" of a test.
class GradeDistributionChart extends StatelessWidget {
  const GradeDistributionChart({
    required this.distribution,
    required this.gradeScale,
    this.color,
    super.key,
  });

  final GradeDistribution distribution;
  final List<GradeScaleEntry> gradeScale;
  final Color? color;

  static const double _barAreaHeight = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = color ?? theme.colorScheme.primary;
    final maxCount = distribution.maxCount;
    final bars = [
      ...distribution.counts,
      if (distribution.otherCount > 0)
        (label: 'grade_other'.tr(), count: distribution.otherCount),
    ];
    final mean = distribution.mean;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _barAreaHeight + 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in bars)
                Expanded(
                  child: Semantics(
                    label: '${bar.label}: ${bar.count}',
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            bar.count == 0 ? '' : '${bar.count}',
                            style: theme.textTheme.labelSmall,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: maxCount == 0
                                ? 2
                                : 2 +
                                      (_barAreaHeight - 2) *
                                          bar.count /
                                          maxCount,
                            decoration: BoxDecoration(
                              color: bar.count == 0
                                  ? theme.colorScheme.outlineVariant
                                  : barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text(
                            bar.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          mean == null
              ? 'grade_distribution_count'.tr(
                  namedArgs: {'count': '${distribution.total}'},
                )
              : 'grade_distribution_count_mean'.tr(
                  namedArgs: {
                    'count': '${distribution.total}',
                    'mean': mean.toStringAsFixed(2),
                    'grade': gradeLabelForNumericValue(mean, gradeScale),
                  },
                ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// [GradeDistributionChart] in a card, titled with what was graded.
class GradeDistributionCard extends StatelessWidget {
  const GradeDistributionCard({
    required this.title,
    required this.values,
    required this.gradeScale,
    this.color,
    super.key,
  });

  final String title;
  final Iterable<String> values;
  final List<GradeScaleEntry> gradeScale;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.medium),
            GradeDistributionChart(
              distribution: computeGradeDistribution(values, gradeScale),
              gradeScale: gradeScale,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
