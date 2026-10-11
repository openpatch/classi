import 'package:classi/features/settings/grade_system_controller.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GradeSystemDefinition gradesPerRow', () {
    const entries = [GradeScaleEntry(label: '15', numericValue: 15)];

    test('round-trips a set value through JSON', () {
      const definition = GradeSystemDefinition(
        id: 'points',
        name: '15-0',
        entries: entries,
        gradesPerRow: 3,
      );

      final restored = GradeSystemDefinition.fromJson(definition.toJson());

      expect(restored, isNotNull);
      expect(restored!.gradesPerRow, equals(3));
    });

    test('keeps gradesPerRow unset when absent from JSON', () {
      const definition = GradeSystemDefinition(
        id: 'points',
        name: '15-0',
        entries: entries,
      );

      final restored = GradeSystemDefinition.fromJson(definition.toJson());

      expect(restored, isNotNull);
      expect(restored!.gradesPerRow, isNull);
      expect(restored.toJson().containsKey('gradesPerRow'), isFalse);
    });

    test('ignores non-positive values', () {
      final restored = GradeSystemDefinition.fromJson(const {
        'id': 'points',
        'name': '15-0',
        'entries': [
          {'label': '15', 'numericValue': 15},
        ],
        'gradesPerRow': 0,
      });

      expect(restored, isNotNull);
      expect(restored!.gradesPerRow, isNull);
    });

    test('parses a numeric string value', () {
      final restored = GradeSystemDefinition.fromJson(const {
        'id': 'points',
        'name': '15-0',
        'entries': [
          {'label': '15', 'numericValue': 15},
        ],
        'gradesPerRow': '4',
      });

      expect(restored, isNotNull);
      expect(restored!.gradesPerRow, equals(4));
    });
  });
}
