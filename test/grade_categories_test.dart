import 'package:classi/shared/utils/grade_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const written = GradeCategory(
    id: 'written',
    name: 'Written',
    weight: 1,
    colorHex: '#FF1E88E5',
  );
  const exam = GradeCategory(
    id: 'test',
    name: 'Test',
    weight: 3,
    colorHex: '#FF8E24AA',
    parentId: 'written',
  );
  const quiz = GradeCategory(
    id: 'quiz',
    name: 'Quiz',
    weight: 1,
    colorHex: '#FF00897B',
    parentId: 'written',
  );
  const oral = GradeCategory(
    id: 'oral',
    name: 'Oral',
    weight: 1,
    colorHex: '#FFF4511E',
  );
  const nested = [written, exam, quiz, oral];

  group('parseGradeCategories', () {
    test('keeps parent links through a round trip', () {
      final parsed = parseGradeCategories(encodeGradeCategories(nested));

      expect(parsed.map((c) => c.parentId), [null, 'written', 'written', null]);
    });

    test('leaves parentId out of the JSON of top-level categories', () {
      expect(written.toJson().containsKey('parentId'), isFalse);
      expect(exam.toJson()['parentId'], 'written');
    });

    test(
      'drops links to missing categories, to itself and two levels deep',
      () {
        final parsed = parseGradeCategories(
          '[{"id":"a","name":"A","weight":1},'
          '{"id":"b","name":"B","weight":1,"parentId":"a"},'
          '{"id":"c","name":"C","weight":1,"parentId":"b"},'
          '{"id":"d","name":"D","weight":1,"parentId":"missing"},'
          '{"id":"e","name":"E","weight":1,"parentId":"e"}]',
        );

        expect(parsed.map((c) => c.parentId), [null, 'a', null, null, null]);
      },
    );
  });

  test('only categories without children can be graded', () {
    expect(gradableCategories(nested).map((c) => c.id), [
      'test',
      'quiz',
      'oral',
    ]);
    expect(gradableCategories(nested, keep: 'written').map((c) => c.id), [
      'written',
      'test',
      'quiz',
      'oral',
    ]);
    expect(gradableCategories(defaultGradeCategories), defaultGradeCategories);
  });

  test('names a child together with its parent', () {
    expect(categoryPathName(exam, nested), 'Written › Test');
    expect(categoryPathName(oral, nested), 'Oral');
  });

  group('calculateWeightedAverage', () {
    test('weighs flat categories as before', () {
      final average = calculateWeightedAverage([
        (value: 1, categoryId: 'sonstige-mitarbeit'),
        (value: 3, categoryId: 'klassenarbeit'),
      ], defaultGradeCategories);

      expect(average, closeTo((1 * 1 + 3 * 3) / 4, 1e-9));
    });

    test('weighs children within their parent, then the parent', () {
      // Written = (2 × 3 + 4 × 1) / 4 = 2.5, then (2.5 + 1) / 2.
      final average = calculateWeightedAverage([
        (value: 2, categoryId: 'test'),
        (value: 4, categoryId: 'quiz'),
        (value: 1, categoryId: 'oral'),
      ], nested);

      expect(average, closeTo(1.75, 1e-9));
    });

    test('a parent with only one graded child takes its value', () {
      final average = calculateWeightedAverage([
        (value: 4, categoryId: 'quiz'),
        (value: 2, categoryId: 'oral'),
      ], nested);

      expect(average, closeTo(3, 1e-9));
    });

    test('grades filed under the parent itself count with weight 1', () {
      expect(
        parentCategoryAverage('written', [
          (value: 2, categoryId: 'test'),
          (value: 6, categoryId: 'written'),
        ], nested),
        closeTo((2 * 3 + 6) / 4, 1e-9),
      );
    });

    test('returns null without values', () {
      expect(calculateWeightedAverage(const [], nested), isNull);
      expect(parentCategoryAverage('written', const [], nested), isNull);
    });
  });
}
