import 'dart:convert';

import 'package:flutter/material.dart';

const defaultGradeCategoryId = 'sonstige-mitarbeit';
const gradeCategoryColorPalette = <String>[
  '#FF1E88E5',
  '#FF8E24AA',
  '#FF00897B',
  '#FFF4511E',
  '#FF3949AB',
  '#FF6D4C41',
  '#FF43A047',
  '#FFE53935',
];
const groupColorPalette = <String>[
  '#FF1E88E5',
  '#FF8E24AA',
  '#FF00897B',
  '#FFF4511E',
  '#FF3949AB',
  '#FF6D4C41',
  '#FF43A047',
  '#FFE53935',
];
const defaultGradeCategoriesJson =
    '[{"id":"sonstige-mitarbeit","name":"Sonstige Mitarbeit","weight":1.0,"color":"#FF1E88E5"},'
    '{"id":"klassenarbeit","name":"Klassenarbeit","weight":3.0,"color":"#FF8E24AA"},'
    '{"id":"praesentation","name":"Präsentation","weight":2.0,"color":"#FF00897B"}]';

class GradeCategory {
  const GradeCategory({
    required this.id,
    required this.name,
    required this.weight,
    required this.colorHex,
    this.parentId,
  });

  final String id;
  final String name;

  /// Weight relative to the category's siblings: to the other top-level
  /// categories, or to the other categories under the same parent.
  final double weight;
  final String colorHex;

  /// The top-level category this one belongs to, e.g. "Klassenarbeit" under
  /// "Schriftlich". `null` for a top-level category. Categories nest one
  /// level deep only.
  final String? parentId;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'weight': weight,
    'color': colorHex,
    'parentId': ?parentId,
  };
}

const defaultGradeCategories = <GradeCategory>[
  GradeCategory(
    id: 'sonstige-mitarbeit',
    name: 'Sonstige Mitarbeit',
    weight: 1,
    colorHex: '#FF1E88E5',
  ),
  GradeCategory(
    id: 'klassenarbeit',
    name: 'Klassenarbeit',
    weight: 3,
    colorHex: '#FF8E24AA',
  ),
  GradeCategory(
    id: 'praesentation',
    name: 'Präsentation',
    weight: 2,
    colorHex: '#FF00897B',
  ),
];

List<GradeCategory> parseGradeCategories(String? rawJson) {
  if (rawJson == null || rawJson.trim().isEmpty) {
    return defaultGradeCategories;
  }

  final decoded = jsonDecode(rawJson);
  if (decoded is! List) {
    return defaultGradeCategories;
  }

  final categories = <GradeCategory>[];
  for (var index = 0; index < decoded.length; index++) {
    final entry = decoded[index];
    if (entry is! Map) {
      continue;
    }

    final id = entry['id']?.toString().trim();
    final name = entry['name']?.toString().trim();
    final weightValue = entry['weight'];
    final weight = weightValue is num
        ? weightValue.toDouble()
        : double.tryParse(weightValue?.toString() ?? '');

    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      continue;
    }

    categories.add(
      GradeCategory(
        id: id,
        name: name,
        weight: weight == null || weight <= 0 ? 1 : weight,
        colorHex: normalizeColorHex(
          entry['color']?.toString(),
          fallback: fallbackCategoryColorHex(id, index),
        ),
        parentId: entry['parentId']?.toString().trim(),
      ),
    );
  }

  return categories.isEmpty
      ? defaultGradeCategories
      : _withValidParents(categories);
}

/// Drops parent links that cannot hold: to a missing category, to itself,
/// or to a category that has a parent of its own, since categories nest one
/// level deep only.
List<GradeCategory> _withValidParents(List<GradeCategory> categories) {
  final byId = {for (final category in categories) category.id: category};
  bool validParent(GradeCategory category) {
    final parentId = category.parentId;
    if (parentId == null || parentId.isEmpty || parentId == category.id) {
      return false;
    }
    final parent = byId[parentId];
    return parent != null &&
        (parent.parentId == null ||
            parent.parentId!.isEmpty ||
            byId[parent.parentId] == null ||
            parent.parentId == parent.id);
  }

  return [
    for (final category in categories)
      if (category.parentId == null || validParent(category))
        category
      else
        GradeCategory(
          id: category.id,
          name: category.name,
          weight: category.weight,
          colorHex: category.colorHex,
        ),
  ];
}

/// Whether some category in [categories] sits under [categoryId].
bool isParentCategory(String categoryId, List<GradeCategory> categories) =>
    categories.any((category) => category.parentId == categoryId);

/// The categories a grade can be given in: every category that no other
/// category sits under. A parent only gathers the grades of its children.
///
/// [keep] stays in the list even when it is a parent, so a grade or lesson
/// filed under it before it got children can still be edited.
List<GradeCategory> gradableCategories(
  List<GradeCategory> categories, {
  String? keep,
}) {
  final parentIds = {
    for (final category in categories)
      if (category.parentId != null) category.parentId!,
  };
  final gradable = [
    for (final category in categories)
      if (!parentIds.contains(category.id) || category.id == keep) category,
  ];
  return gradable.isEmpty ? categories : gradable;
}

/// The categories under [parentId], in their saved order.
List<GradeCategory> childCategories(
  String parentId,
  List<GradeCategory> categories,
) => [
  for (final category in categories)
    if (category.parentId == parentId) category,
];

/// The name to show for [category] where its parent is not visible
/// alongside it, such as "Schriftlich › Klassenarbeit".
String categoryPathName(
  GradeCategory category,
  List<GradeCategory> categories,
) {
  final parentId = category.parentId;
  if (parentId == null) {
    return category.name;
  }
  for (final parent in categories) {
    if (parent.id == parentId) {
      return '${parent.name} › ${category.name}';
    }
  }
  return category.name;
}

String encodeGradeCategories(List<GradeCategory> categories) =>
    jsonEncode([for (final category in categories) category.toJson()]);

double weightForCategory(String categoryId, List<GradeCategory> categories) {
  for (final category in categories) {
    if (category.id == categoryId) {
      return category.weight > 0 ? category.weight : 1;
    }
  }
  return 1;
}

String categoryNameFor({
  required String categoryId,
  required List<GradeCategory> categories,
  String? fallbackName,
}) {
  for (final category in categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }
  if (fallbackName != null && fallbackName.trim().isNotEmpty) {
    return fallbackName.trim();
  }
  return categoryId;
}

Color colorForCategory(GradeCategory category) =>
    colorFromHex(normalizeColorHex(category.colorHex, fallback: '#FF1E88E5'));

Color colorForCategoryId({
  required String categoryId,
  required List<GradeCategory> categories,
  String? fallbackColorHex,
}) {
  for (final category in categories) {
    if (category.id == categoryId) {
      return colorForCategory(category);
    }
  }
  return colorFromHex(
    normalizeColorHex(
      fallbackColorHex,
      fallback: fallbackCategoryColorHex(categoryId, 0),
    ),
  );
}

String fallbackCategoryColorHex(String categoryId, int index) {
  for (final category in defaultGradeCategories) {
    if (category.id == categoryId) {
      return category.colorHex;
    }
  }
  return gradeCategoryColorPalette[index % gradeCategoryColorPalette.length];
}

String normalizeColorHex(String? rawColor, {required String fallback}) {
  final normalizedFallback = fallback.toUpperCase();
  if (rawColor == null) {
    return normalizedFallback;
  }

  final hex = rawColor.trim().replaceAll('#', '').toUpperCase();
  if (hex.length == 6 && _isHex(hex)) {
    return '#FF$hex';
  }
  if (hex.length == 8 && _isHex(hex)) {
    return '#$hex';
  }
  return normalizedFallback;
}

Color colorFromHex(String hex) {
  final normalized = normalizeColorHex(hex, fallback: '#FF1E88E5');
  return Color(int.parse(normalized.substring(1), radix: 16));
}

Color onColorForBackground(Color color) {
  final brightness = ThemeData.estimateBrightnessForColor(color);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}

String colorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Weighs [entries] by their categories.
///
/// An entry in a child category is first weighed against its siblings into
/// one value for the parent, which then counts with the parent's weight among
/// the top-level categories. A category's weight therefore only matters
/// relative to its siblings. An entry filed directly under a parent (graded
/// before the parent got children) counts alongside the children with
/// weight 1.
double? calculateWeightedAverage(
  Iterable<({double value, String categoryId})> entries,
  List<GradeCategory> categories,
) {
  final byId = {for (final category in categories) category.id: category};
  final topLevel = <({double value, String categoryId})>[];
  final byParent = <String, List<({double value, double weight})>>{};

  for (final entry in entries) {
    final category = byId[entry.categoryId];
    final parentId = category?.parentId;
    if (parentId != null) {
      byParent.putIfAbsent(parentId, () => []).add((
        value: entry.value,
        weight: _positiveWeight(category!),
      ));
    } else if (isParentCategory(entry.categoryId, categories)) {
      byParent.putIfAbsent(entry.categoryId, () => []).add((
        value: entry.value,
        weight: 1,
      ));
    } else {
      topLevel.add(entry);
    }
  }

  for (final group in byParent.entries) {
    final value = _weightedMean(group.value);
    if (value != null) {
      topLevel.add((value: value, categoryId: group.key));
    }
  }

  return _weightedMean([
    for (final entry in topLevel)
      (
        value: entry.value,
        weight: weightForCategory(entry.categoryId, categories),
      ),
  ]);
}

/// The value of parent category [parentId] from per-category values in
/// [entries], weighed as [calculateWeightedAverage] weighs it. `null` when
/// none of its children (or itself) has a value.
double? parentCategoryAverage(
  String parentId,
  Iterable<({double value, String categoryId})> entries,
  List<GradeCategory> categories,
) {
  final values = <({double value, double weight})>[];
  for (final entry in entries) {
    if (entry.categoryId == parentId) {
      values.add((value: entry.value, weight: 1));
      continue;
    }
    for (final category in categories) {
      if (category.id == entry.categoryId && category.parentId == parentId) {
        values.add((value: entry.value, weight: _positiveWeight(category)));
        break;
      }
    }
  }
  return _weightedMean(values);
}

double _positiveWeight(GradeCategory category) =>
    category.weight > 0 ? category.weight : 1;

double? _weightedMean(Iterable<({double value, double weight})> values) {
  var totalWeight = 0.0;
  var weightedSum = 0.0;

  for (final entry in values) {
    totalWeight += entry.weight;
    weightedSum += entry.value * entry.weight;
  }

  if (totalWeight == 0) {
    return null;
  }

  return weightedSum / totalWeight;
}

bool _isHex(String value) => RegExp(r'^[0-9A-F]+$').hasMatch(value);
