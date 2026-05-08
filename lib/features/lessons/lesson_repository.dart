import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import 'lesson_support.dart';

class LessonRepository {
  LessonRepository(this._database);

  final AppDatabase _database;

  Stream<Map<DateTime, Set<String>>> watchGroupEntryCategories(int groupId) {
    return _database
        .customSelect(
          '''
          SELECT DISTINCT g.date AS entry_date, g.category_id AS category_id
          FROM grade_entries_table g
          JOIN students_table s ON s.id = g.student_id
          WHERE s.group_id = ?
          ORDER BY g.date DESC, g.category_id ASC
          ''',
          variables: [Variable.withInt(groupId)],
          readsFrom: {_database.gradeEntriesTable, _database.studentsTable},
        )
        .watch()
        .map((rows) {
          final categoriesByDate = <DateTime, Set<String>>{};
          for (final row in rows) {
            final categoryId = row.read<String>('category_id').trim();
            if (categoryId.isEmpty) {
              continue;
            }
            final date = normalizeLessonDate(row.read<DateTime>('entry_date'));
            categoriesByDate
                .putIfAbsent(date, () => <String>{})
                .add(categoryId);
          }
          return categoriesByDate;
        });
  }
}
