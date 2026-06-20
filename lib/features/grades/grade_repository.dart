import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';

class GradeRepository {
  GradeRepository(this._database);

  final AppDatabase _database;

  Stream<List<GradeEntry>> watchStudentGrades(int studentId) {
    return (_database.select(_database.gradeEntriesTable)
          ..where((table) => table.studentId.equals(studentId))
          ..orderBy([(table) => OrderingTerm.desc(table.date)]))
        .watch();
  }

  Stream<Map<int, double>> watchGroupAverages(int groupId) {
    return Stream.multi((controller) {
      var categories = defaultGradeCategories;
      var gradeScale = defaultGradeScaleEntries;
      var hasGroup = false;
      var hasRows = false;
      var rows = const <QueryRow>[];

      void emit() {
        if (!hasGroup) {
          controller.add(const <int, double>{});
          return;
        }
        if (!hasRows) {
          return;
        }

        controller.add(_weightedAveragesFromRows(rows, categories, gradeScale));
      }

      final groupSubscription =
          (_database.select(_database.groupsTable)
                ..where((table) => table.id.equals(groupId)))
              .watchSingleOrNull()
              .listen((group) {
                if (group == null) {
                  hasGroup = false;
                  emit();
                  return;
                }

                hasGroup = true;
                categories = parseGradeCategories(group.gradeCategoriesJson);
                gradeScale = parseGradeScaleEntries(group.gradeScaleJson);
                emit();
              }, onError: controller.addError);

      final rowsSubscription = _groupAverageRows(groupId).watch().listen((
        value,
      ) {
        hasRows = true;
        rows = value;
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await groupSubscription.cancel();
        await rowsSubscription.cancel();
      };
    });
  }

  Stream<Map<int, Map<String, double>>> watchGroupCategoryAverages(
    int groupId,
  ) {
    return Stream.multi((controller) {
      var gradeScale = defaultGradeScaleEntries;
      var hasGroup = false;
      var hasRows = false;
      var rows = const <QueryRow>[];

      void emit() {
        if (!hasGroup) {
          controller.add(const <int, Map<String, double>>{});
          return;
        }
        if (!hasRows) {
          return;
        }

        controller.add(_categoryAveragesFromRows(rows, gradeScale));
      }

      final groupSubscription =
          (_database.select(_database.groupsTable)
                ..where((table) => table.id.equals(groupId)))
              .watchSingleOrNull()
              .listen((group) {
                if (group == null) {
                  hasGroup = false;
                  emit();
                  return;
                }

                hasGroup = true;
                gradeScale = parseGradeScaleEntries(group.gradeScaleJson);
                emit();
              }, onError: controller.addError);

      final rowsSubscription = _groupCategoryAverageRows(groupId)
          .watch()
          .listen((value) {
            hasRows = true;
            rows = value;
            emit();
          }, onError: controller.addError);

      controller.onCancel = () async {
        await groupSubscription.cancel();
        await rowsSubscription.cancel();
      };
    });
  }

  Future<Map<int, double>> getGroupAverages(int groupId) async {
    final group = await (_database.select(
      _database.groupsTable,
    )..where((table) => table.id.equals(groupId))).getSingle();
    final categories = parseGradeCategories(group.gradeCategoriesJson);
    final gradeScale = parseGradeScaleEntries(group.gradeScaleJson);
    final rows = await _groupAverageRows(groupId).get();
    return _weightedAveragesFromRows(rows, categories, gradeScale);
  }

  Future<Map<int, Map<String, double>>> getGroupCategoryAverages(
    int groupId,
  ) async {
    final group = await (_database.select(
      _database.groupsTable,
    )..where((table) => table.id.equals(groupId))).getSingle();
    final gradeScale = parseGradeScaleEntries(group.gradeScaleJson);
    final rows = await _groupCategoryAverageRows(groupId).get();
    return _categoryAveragesFromRows(rows, gradeScale);
  }

  Future<Map<int, String>> getSessionSelections({
    required int groupId,
    required String sessionLabel,
    required DateTime date,
    required String categoryId,
  }) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT g.student_id, g.value
      FROM grade_entries_table g
      JOIN students_table s ON s.id = g.student_id
      WHERE s.group_id = ? AND g.session_label = ? AND g.date = ? AND g.category_id = ?
      ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withString(sessionLabel),
            Variable.withDateTime(DateTime(date.year, date.month, date.day)),
            Variable.withString(categoryId),
          ],
        )
        .get();

    return {
      for (final row in rows)
        row.read<int>('student_id'): row.read<String>('value'),
    };
  }

  Stream<Map<int, String>> watchSessionSelections({
    required int groupId,
    required String sessionLabel,
    required DateTime date,
    required String categoryId,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _database
        .customSelect(
          '''
      SELECT g.student_id, g.value
      FROM grade_entries_table g
      JOIN students_table s ON s.id = g.student_id
      WHERE s.group_id = ? AND g.session_label = ? AND g.date = ? AND g.category_id = ?
      ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withString(sessionLabel),
            Variable.withDateTime(normalizedDate),
            Variable.withString(categoryId),
          ],
          readsFrom: {_database.gradeEntriesTable, _database.studentsTable},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.read<int>('student_id'): row.read<String>('value'),
          },
        );
  }

  Future<String?> getPreferredSessionLabel({
    required int groupId,
    required DateTime date,
    required String categoryId,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedCategoryId = categoryId.trim();
    if (normalizedCategoryId.isEmpty) {
      return null;
    }

    final rows = await _database
        .customSelect(
          '''
          SELECT g.session_label, COUNT(*) AS entry_count
          FROM grade_entries_table g
          JOIN students_table s ON s.id = g.student_id
          WHERE s.group_id = ? AND g.date = ? AND g.category_id = ?
          GROUP BY g.session_label
          ORDER BY entry_count DESC, g.session_label ASC
          LIMIT 1
          ''',
          variables: [
            Variable.withInt(groupId),
            Variable.withDateTime(normalizedDate),
            Variable.withString(normalizedCategoryId),
          ],
        )
        .getSingleOrNull();

    if (rows == null) {
      return null;
    }

    final sessionLabel = rows.read<String>('session_label').trim();
    return sessionLabel.isEmpty ? null : sessionLabel;
  }

  Future<void> saveEntry({
    required int studentId,
    required DateTime date,
    required String sessionLabel,
    required String value,
    String categoryId = defaultGradeCategoryId,
    String categoryName = 'Sonstige Mitarbeit',
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedSessionLabel = sessionLabel.trim();
    final normalizedValue = value.trim();
    final normalizedCategoryId = categoryId.trim().isEmpty
        ? defaultGradeCategoryId
        : categoryId.trim();
    final normalizedCategoryName = categoryName.trim().isEmpty
        ? 'Sonstige Mitarbeit'
        : categoryName.trim();
    final existing =
        await (_database.select(_database.gradeEntriesTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where(
                (table) => table.sessionLabel.equals(normalizedSessionLabel),
              )
              ..where((table) => table.categoryId.equals(normalizedCategoryId))
              ..where((table) => table.date.equals(normalizedDate)))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.gradeEntriesTable)
          .insert(
            GradeEntriesTableCompanion.insert(
              studentId: studentId,
              date: normalizedDate,
              sessionLabel: normalizedSessionLabel,
              value: normalizedValue,
              categoryId: Value(normalizedCategoryId),
              categoryName: Value(normalizedCategoryName),
            ),
          );
      return;
    }

    await (_database.update(
      _database.gradeEntriesTable,
    )..where((table) => table.id.equals(existing.id))).write(
      GradeEntriesTableCompanion(
        value: Value(normalizedValue),
        categoryName: Value(normalizedCategoryName),
      ),
    );
  }

  Future<void> clearSessionSelection({
    required int studentId,
    required DateTime date,
    required String sessionLabel,
    String categoryId = defaultGradeCategoryId,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedSessionLabel = sessionLabel.trim();
    final normalizedCategoryId = categoryId.trim().isEmpty
        ? defaultGradeCategoryId
        : categoryId.trim();

    return (_database.delete(_database.gradeEntriesTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.equals(normalizedDate))
          ..where((table) => table.sessionLabel.equals(normalizedSessionLabel))
          ..where((table) => table.categoryId.equals(normalizedCategoryId)))
        .go();
  }

  Future<void> updateEntry({
    required int id,
    required int studentId,
    required DateTime date,
    required String sessionLabel,
    required String value,
    required String categoryId,
    required String categoryName,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedSessionLabel = sessionLabel.trim();
    final normalizedValue = value.trim();
    final normalizedCategoryId = categoryId.trim();
    final normalizedCategoryName = categoryName.trim();
    final matches =
        await (_database.select(_database.gradeEntriesTable)
              ..where((table) => table.studentId.equals(studentId))
              ..where(
                (table) => table.sessionLabel.equals(normalizedSessionLabel),
              )
              ..where((table) => table.categoryId.equals(normalizedCategoryId))
              ..where((table) => table.date.equals(normalizedDate)))
            .get();

    GradeEntry? duplicate;
    for (final match in matches) {
      if (match.id != id) {
        duplicate = match;
        break;
      }
    }

    await _database.transaction(() async {
      if (duplicate != null) {
        await (_database.update(
          _database.gradeEntriesTable,
        )..where((table) => table.id.equals(duplicate!.id))).write(
          GradeEntriesTableCompanion(
            value: Value(normalizedValue),
            categoryName: Value(normalizedCategoryName),
          ),
        );
        await deleteEntry(id);
        return;
      }

      await (_database.update(
        _database.gradeEntriesTable,
      )..where((table) => table.id.equals(id))).write(
        GradeEntriesTableCompanion(
          date: Value(normalizedDate),
          sessionLabel: Value(normalizedSessionLabel),
          value: Value(normalizedValue),
          categoryId: Value(normalizedCategoryId),
          categoryName: Value(normalizedCategoryName),
        ),
      );
    });
  }

  Future<void> deleteEntry(int id) {
    return (_database.delete(
      _database.gradeEntriesTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Selectable<QueryRow> _groupAverageRows(int groupId) {
    return _database.customSelect(
      '''
      SELECT g.student_id, g.value, g.category_id
      FROM grade_entries_table g
      JOIN students_table s ON s.id = g.student_id
      WHERE s.group_id = ?
      ORDER BY g.student_id
      ''',
      variables: [Variable.withInt(groupId)],
      readsFrom: {_database.gradeEntriesTable, _database.studentsTable},
    );
  }

  Selectable<QueryRow> _groupCategoryAverageRows(int groupId) {
    return _database.customSelect(
      '''
      SELECT g.student_id, g.category_id, g.value
      FROM grade_entries_table g
      JOIN students_table s ON s.id = g.student_id
      WHERE s.group_id = ?
      ORDER BY g.student_id, g.category_id
      ''',
      variables: [Variable.withInt(groupId)],
      readsFrom: {_database.gradeEntriesTable, _database.studentsTable},
    );
  }

  Map<int, double> _weightedAveragesFromRows(
    Iterable<QueryRow> rows,
    List<GradeCategory> categories,
    List<GradeScaleEntry> gradeScale,
  ) {
    final perStudent = <int, Map<String, List<double>>>{};
    for (final row in rows) {
      final numericValue = gradeValueToNumber(
        row.read<String>('value'),
        gradeScale,
      );
      if (numericValue == null) {
        continue;
      }

      final studentId = row.read<int>('student_id');
      final categoryId = row.read<String>('category_id');
      perStudent.putIfAbsent(studentId, () => {}).putIfAbsent(
        categoryId,
        () => [],
      ).add(numericValue);
    }

    final averages = <int, double>{};
    for (final studentEntry in perStudent.entries) {
      final categoryAverages = <({double value, String categoryId})>[];
      for (final categoryEntry in studentEntry.value.entries) {
        final values = categoryEntry.value;
        final categoryAvg = values.reduce((a, b) => a + b) / values.length;
        categoryAverages.add((
          value: categoryAvg,
          categoryId: categoryEntry.key,
        ));
      }
      final average = calculateWeightedAverage(categoryAverages, categories);
      if (average != null) {
        averages[studentEntry.key] = average;
      }
    }
    return averages;
  }

  Map<int, Map<String, double>> _categoryAveragesFromRows(
    Iterable<QueryRow> rows,
    List<GradeScaleEntry> gradeScale,
  ) {
    final result = <int, Map<String, double>>{};
    final counts = <int, Map<String, int>>{};
    for (final row in rows) {
      final numericValue = gradeValueToNumber(
        row.read<String>('value'),
        gradeScale,
      );
      if (numericValue == null) {
        continue;
      }

      final studentId = row.read<int>('student_id');
      final categoryId = row.read<String>('category_id');
      result.putIfAbsent(studentId, () => {});
      counts.putIfAbsent(studentId, () => {});
      result[studentId]![categoryId] =
          (result[studentId]![categoryId] ?? 0) + numericValue;
      counts[studentId]![categoryId] =
          (counts[studentId]![categoryId] ?? 0) + 1;
    }

    for (final studentEntry in result.entries) {
      final studentCounts = counts[studentEntry.key]!;
      for (final categoryEntry in studentEntry.value.entries.toList()) {
        studentEntry.value[categoryEntry.key] =
            categoryEntry.value / studentCounts[categoryEntry.key]!;
      }
    }
    return result;
  }

  Stream<List<GradeEntry>> watchGradesForStudentInDateRange(
    int studentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    return (_database.select(_database.gradeEntriesTable)
          ..where((table) => table.studentId.equals(studentId))
          ..where((table) => table.date.isBiggerOrEqualValue(normalizedStart) & 
                     table.date.isSmallerOrEqualValue(normalizedEnd))
          ..orderBy([(table) => OrderingTerm.asc(table.date)]))
        .watch();
  }

  /// Streams per-student, per-category grade averages for all students in
  /// [groupId], filtered to entries within [startDate]–[endDate] inclusive.
  ///
  /// Returns `Map<studentId, Map<categoryId, average>>`.
  Stream<Map<int, Map<String, double>>> watchGroupCategoryAveragesInDateRange({
    required int groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return Stream.multi((controller) {
      var gradeScale = defaultGradeScaleEntries;
      var hasGroup = false;
      var hasRows = false;
      var rows = const <QueryRow>[];

      void emit() {
        if (!hasGroup || !hasRows) {
          controller.add(const <int, Map<String, double>>{});
          return;
        }
        controller.add(_categoryAveragesFromRows(rows, gradeScale));
      }

      final groupSubscription =
          (_database.select(_database.groupsTable)
                ..where((t) => t.id.equals(groupId)))
              .watchSingleOrNull()
              .listen((group) {
                hasGroup = group != null;
                if (group != null) {
                  gradeScale = parseGradeScaleEntries(group.gradeScaleJson);
                }
                emit();
              }, onError: controller.addError);

      final rowsSubscription = _database.customSelect(
        '''
        SELECT g.student_id, g.category_id, g.value
        FROM grade_entries_table g
        JOIN students_table s ON s.id = g.student_id
        WHERE s.group_id = ? AND g.date >= ? AND g.date <= ?
        ORDER BY g.student_id, g.category_id
        ''',
        variables: [
          Variable.withInt(groupId),
          Variable.withDateTime(normalizedStart),
          Variable.withDateTime(normalizedEnd),
        ],
        readsFrom: {_database.gradeEntriesTable, _database.studentsTable},
      ).watch().listen((value) {
        hasRows = true;
        rows = value;
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await groupSubscription.cancel();
        await rowsSubscription.cancel();
      };
    });
  }
}
