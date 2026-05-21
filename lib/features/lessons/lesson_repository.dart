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
          SELECT date, category_id
          FROM sessions_table
          WHERE group_id = ?
          ORDER BY date DESC
          ''',
          variables: [Variable.withInt(groupId)],
          readsFrom: {_database.sessionsTable},
        )
        .watch()
        .map((rows) {
          final categoriesByDate = <DateTime, Set<String>>{};
          for (final row in rows) {
            final categoryId = row.read<String>('category_id').trim();
            if (categoryId.isEmpty) {
              continue;
            }
            final date = normalizeLessonDate(row.read<DateTime>('date'));
            categoriesByDate
                .putIfAbsent(date, () => <String>{})
                .add(categoryId);
          }
          return categoriesByDate;
        });
  }
}
