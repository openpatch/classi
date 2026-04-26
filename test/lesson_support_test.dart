import 'package:clari/core/database/app_database.dart';
import 'package:clari/features/lessons/lesson_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lesson support', () {
    test('normalizes and encodes lesson dates', () {
      final date = DateTime(2025, 3, 14, 11, 30);

      expect(normalizeLessonDate(date), DateTime(2025, 3, 14));
      expect(encodeLessonDate(date), '2025-03-14');
      expect(parseLessonDateOrToday('2025-03-14'), DateTime(2025, 3, 14));
    });

    test('filters notes by lesson date and sorts newest first', () {
      final notes = [
        TeacherNote(
          id: 1,
          body: 'Earlier',
          groupId: 1,
          studentIdsJson: '[]',
          isTodo: false,
          todoDone: false,
          createdAt: DateTime(2025, 3, 14, 8),
          archivedAt: null,
        ),
        TeacherNote(
          id: 2,
          body: 'Other day',
          groupId: 1,
          studentIdsJson: '[]',
          isTodo: false,
          todoDone: false,
          createdAt: DateTime(2025, 3, 15, 9),
          archivedAt: null,
        ),
        TeacherNote(
          id: 3,
          body: 'Latest',
          groupId: 1,
          studentIdsJson: '[]',
          isTodo: true,
          todoDone: false,
          createdAt: DateTime(2025, 3, 14, 12),
          archivedAt: null,
        ),
      ];

      final filtered = notesForLessonDate(notes, DateTime(2025, 3, 14, 20));

      expect(filtered.map((note) => note.id), [3, 1]);
    });
  });
}
