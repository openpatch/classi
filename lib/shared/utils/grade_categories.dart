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
  });

  final String id;
  final String name;
  final double weight;
  final String colorHex;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'weight': weight,
    'color': colorHex,
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
      ),
    );
  }

  return categories.isEmpty ? defaultGradeCategories : categories;
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

double? calculateWeightedAverage(
  Iterable<({double value, String categoryId})> entries,
  List<GradeCategory> categories,
) {
  var totalWeight = 0.0;
  var weightedSum = 0.0;

  for (final entry in entries) {
    final weight = weightForCategory(entry.categoryId, categories);
    totalWeight += weight;
    weightedSum += entry.value * weight;
  }

  if (totalWeight == 0) {
    return null;
  }

  return weightedSum / totalWeight;
}

bool _isHex(String value) => RegExp(r'^[0-9A-F]+$').hasMatch(value);
