import 'dart:convert';

import '../../../shared/utils/formatting.dart';

/// Lowest percentage of the maximum points that earns [label].
class GradeThreshold {
  const GradeThreshold({
    required this.label,
    required this.minPercent,
    this.sourceLabel,
  });

  /// Grade label of the group's grade scale.
  final String label;
  final double minPercent;

  /// Label in the Typst document, for Typst-linked exams.
  final String? sourceLabel;

  Map<String, Object?> toJson() => {
    'label': label,
    'minPercent': minPercent,
    'sourceLabel': ?sourceLabel,
  };

  GradeThreshold copyWith({String? label, double? minPercent}) =>
      GradeThreshold(
        label: label ?? this.label,
        minPercent: minPercent ?? this.minPercent,
        sourceLabel: sourceLabel,
      );

  @override
  bool operator ==(Object other) =>
      other is GradeThreshold &&
      other.label == label &&
      other.minPercent == minPercent &&
      other.sourceLabel == sourceLabel;

  @override
  int get hashCode => Object.hash(label, minPercent, sourceLabel);
}

/// The grading scheme of one exam: thresholds from percent to grade.
class GradeScheme {
  const GradeScheme({required this.thresholds});

  /// Ordered from the best grade down, as in assessio's grade table.
  final List<GradeThreshold> thresholds;

  bool get isEmpty => thresholds.isEmpty;

  /// Thresholds sorted by descending percentage; the order grades are
  /// checked in.
  List<GradeThreshold> get _sorted {
    final indexed = thresholds.indexed.toList()
      ..sort((a, b) {
        final byPercent = b.$2.minPercent.compareTo(a.$2.minPercent);
        return byPercent != 0 ? byPercent : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  /// Whole-point cutoff per threshold, exactly as assessio computes it:
  /// `round(max * min / 100)` with halves rounded up.
  List<({GradeThreshold threshold, int cutoff})> cutoffs(double maxPoints) => [
    for (final t in _sorted)
      (threshold: t, cutoff: assessioCutoff(maxPoints, t.minPercent)),
  ];

  /// The grade for [points] out of [maxPoints], or `null` without thresholds.
  String? gradeFor(double points, double maxPoints) {
    final list = cutoffs(maxPoints);
    if (list.isEmpty) return null;
    for (final entry in list) {
      if (points >= entry.cutoff - 1e-9) return entry.threshold.label;
    }
    return list.last.threshold.label;
  }

  Map<String, Object?> toJson() => {
    'thresholds': [for (final t in thresholds) t.toJson()],
  };

  String encode() => jsonEncode(toJson());

  static GradeScheme decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const GradeScheme(thresholds: []);
    }
    try {
      final json = jsonDecode(raw);
      final list = json is Map ? json['thresholds'] : json;
      if (list is! List) return const GradeScheme(thresholds: []);
      return GradeScheme(thresholds: parseThresholds(list));
    } on FormatException {
      return const GradeScheme(thresholds: []);
    }
  }

  static List<GradeThreshold> parseThresholds(List<Object?> list) => [
    for (final t in list)
      if (t is Map && t['label'] != null && t['minPercent'] is num)
        GradeThreshold(
          label: '${t['label']}',
          minPercent: (t['minPercent'] as num).toDouble(),
          sourceLabel: t['sourceLabel'] as String?,
        ),
  ];

  bool sameAs(GradeScheme other) {
    if (other.thresholds.length != thresholds.length) return false;
    for (var i = 0; i < thresholds.length; i++) {
      if (other.thresholds[i] != thresholds[i]) return false;
    }
    return true;
  }
}

/// assessio's point cutoff: nearest whole point, halves up. Uses the same
/// operation order as Typst (`max * min / 100`) so floating point agrees.
int assessioCutoff(double maxPoints, double minPercent) {
  final value = maxPoints * minPercent / 100;
  return value.round();
}

/// NRW thresholds for grades 1–6 (assessio's `german-grade-scale`).
const List<double> germanGradePercents = [87, 73, 59, 45, 18, 0];

/// NRW thresholds for 15–0 points (assessio's `german-grade-points-scale`).
const List<double> germanPointPercents = [
  95,
  90,
  85,
  80,
  75,
  70,
  65,
  60,
  55,
  50,
  45,
  40,
  33,
  27,
  20,
  0,
];

/// A sensible default scheme for a grade scale, used when no template with
/// thresholds matches: the NRW scales for 6 and 16 grades, evenly spaced
/// otherwise. Labels are ordered from best to worst.
List<GradeThreshold> defaultThresholdsFor(List<GradeScaleEntry> scale) {
  if (scale.isEmpty) return const [];
  final ordered = _bestFirst(scale);
  final percents = switch (ordered.length) {
    6 => germanGradePercents,
    16 => germanPointPercents,
    _ => [
      for (var i = 0; i < ordered.length; i++)
        i == ordered.length - 1
            ? 0.0
            : (100 * (ordered.length - 1 - i) / ordered.length).roundToDouble(),
    ],
  };
  return [
    for (var i = 0; i < ordered.length; i++)
      GradeThreshold(label: ordered[i].label, minPercent: percents[i]),
  ];
}

/// Grade scale entries from best to worst.
List<GradeScaleEntry> _bestFirst(List<GradeScaleEntry> scale) {
  final lowerIsBetter = gradeScaleLowerValuesAreBetter(scale);
  final sorted = [...scale]
    ..sort(
      (a, b) => lowerIsBetter
          ? a.numericValue.compareTo(b.numericValue)
          : b.numericValue.compareTo(a.numericValue),
    );
  return sorted;
}
