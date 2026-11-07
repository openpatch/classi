import '../../../shared/utils/formatting.dart';

const _gradeWords = <String, int>{
  // Longer phrases first: "sehr gut" before "gut", "insufficient" before
  // "sufficient".
  'sehr gut': 1,
  'very good': 1,
  'ungenügend': 6,
  'ungenuegend': 6,
  'insufficient': 6,
  'befriedigend': 3,
  'satisfactory': 3,
  'ausreichend': 4,
  'sufficient': 4,
  'mangelhaft': 5,
  'poor': 5,
  'gut': 2,
  'good': 2,
};

/// Suggests which grade of the group's [scale] each Typst grade label means.
///
/// Tries, in order: a previous mapping, the exact label, a leading number
/// ("15 (sehr gut +)" → "15"), grade words with +/- ("sehr gut +" → "1+"),
/// and finally the position when both scales have the same length. Labels
/// without a suggestion map to `null` and must be chosen by the teacher.
Map<String, String?> suggestGradeLabelMapping(
  List<String> typstLabels,
  List<GradeScaleEntry> scale, {
  Map<String, String> previous = const {},
}) {
  final labels = [for (final e in scale) e.label];
  final byLower = {for (final l in labels) l.toLowerCase(): l};
  final bestFirst = [...scale]
    ..sort(
      (a, b) => gradeScaleLowerValuesAreBetter(scale)
          ? a.numericValue.compareTo(b.numericValue)
          : b.numericValue.compareTo(a.numericValue),
    );

  // In a scale with "1+", "1", "1-", … a leading number in the Typst label
  // ("5 (ausreichend)") counts points, not grades; the grade word decides.
  // In a points scale (15–0) the number is the grade.
  final modifierScale = labels.any((l) => RegExp(r'^\d[+-]$').hasMatch(l));

  String? fromWords(String typst) {
    final lower = typst.toLowerCase();
    for (final word in _gradeWords.entries) {
      final at = lower.indexOf(word.key);
      if (at < 0) continue;
      final rest = lower.substring(at + word.key.length).trimLeft();
      final modifier = rest.startsWith('+')
          ? '+'
          : (rest.startsWith('-') || rest.startsWith('–') ? '-' : '');
      final base = '${word.value}';
      if (modifier.isNotEmpty && labels.contains('$base$modifier')) {
        return '$base$modifier';
      }
      return labels.contains(base) ? base : null;
    }
    return null;
  }

  String? fromNumber(String typst) {
    final number = RegExp(r'^\s*(\d+)').firstMatch(typst)?.group(1);
    return number != null && labels.contains(number) ? number : null;
  }

  String? suggest(String typst, int index) {
    final prior = previous[typst];
    if (prior != null && labels.contains(prior)) return prior;

    final exact = byLower[typst.trim().toLowerCase()];
    if (exact != null) return exact;

    final guess = modifierScale
        ? (fromWords(typst) ?? fromNumber(typst))
        : (fromNumber(typst) ?? fromWords(typst));
    if (guess != null) return guess;

    if (typstLabels.length == bestFirst.length) return bestFirst[index].label;
    return null;
  }

  return {
    for (final (index, typst) in typstLabels.indexed)
      typst: suggest(typst, index),
  };
}
