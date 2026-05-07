import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../features/grades/grade_editor_sheet.dart';
import '../../features/groups/group_detail_screen.dart';
import '../../features/homework/homework_log_editor.dart';
import '../../features/material_tracking/material_log_editor.dart';
import '../../features/notes/note_editor.dart';
import '../../features/notes/note_links.dart';
import '../../features/students/student_form.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/app_bar_title.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../shared/widgets/swipe_action_background.dart';

final studentProvider = StreamProvider.autoDispose.family<Student?, int>(
  (ref, studentId) =>
      ref.watch(studentRepositoryProvider).watchStudent(studentId),
);

final studentGradesProvider = StreamProvider.autoDispose
    .family<List<GradeEntry>, int>(
      (ref, studentId) =>
          ref.watch(gradeRepositoryProvider).watchStudentGrades(studentId),
    );

final studentMaterialProvider = StreamProvider.autoDispose
    .family<List<MaterialLog>, int>(
      (ref, studentId) =>
          ref.watch(materialRepositoryProvider).watchStudentLogs(studentId),
    );

final studentHomeworkProvider = StreamProvider.autoDispose
    .family<List<HomeworkLog>, int>(
      (ref, studentId) =>
          ref.watch(homeworkRepositoryProvider).watchStudentLogs(studentId),
    );

final studentNotesProvider = StreamProvider.autoDispose
    .family<List<TeacherNote>, int>(
      (ref, studentId) =>
          ref.watch(noteRepositoryProvider).watchNotesForStudent(studentId),
    );

final studentListItemsProvider = StreamProvider.autoDispose
    .family<List<({Checklist list, ChecklistItem item})>, int>(
      (ref, studentId) =>
          ref.watch(listRepositoryProvider).watchItemsForStudent(studentId),
    );

final studentAttendanceProvider = StreamProvider.autoDispose
    .family<List<AttendanceLog>, int>(
      (ref, studentId) => ref
          .watch(attendanceRepositoryProvider)
          .watchStudentLogs(studentId),
    );

final availableGroupsProvider = FutureProvider.autoDispose<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).allActiveGroups(),
);

final availableStudentsProvider = StreamProvider.autoDispose<List<Student>>(
  (ref) => ref
      .watch(studentRepositoryProvider)
      .watchAllStudents(sortField: ref.watch(studentSortFieldProvider)),
);

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({required this.studentId, super.key});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    final studentValue = ref.watch(studentProvider(studentId));

    return studentValue.when(
      data: (student) {
        if (student == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final groupValue = ref.watch(groupProvider(student.groupId));
        final gradesValue = ref.watch(studentGradesProvider(studentId));
        final materialValue = ref.watch(studentMaterialProvider(studentId));
        final homeworkValue = ref.watch(studentHomeworkProvider(studentId));
        final notesValue = ref.watch(studentNotesProvider(studentId));
        final listItemsValue = ref.watch(studentListItemsProvider(studentId));
        final attendanceValue = ref.watch(
          studentAttendanceProvider(studentId),
        );
        final groupsValue = ref.watch(availableGroupsProvider);
        final allStudentsValue = ref.watch(availableStudentsProvider);
        final group = groupValue.value;
        final groupColor = group == null ? null : colorFromHex(group.colorHex);
        final groupForeground = groupColor == null
            ? null
            : onColorForBackground(groupColor);

        return DefaultTabController(
          length: 6,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: groupColor,
              foregroundColor: groupForeground,
              leading: BackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go('/groups/${student.groupId}');
                },
              ),
              title: Row(
                children: [
                  StudentAvatar(student: student, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppBarTitle(
                      title: studentDisplayNameWithOrigin(
                        firstName: student.firstName,
                        lastName: student.lastName,
                        originNote: student.originNote,
                        sortField: sortField,
                      ),
                      subtitle: group?.name,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => _editStudent(context, ref, student),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'edit'.tr(),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: 'attendance'.tr()),
                  Tab(text: 'grades'.tr()),
                  Tab(text: 'material'.tr()),
                  Tab(text: 'homework'.tr()),
                  Tab(text: 'notes'.tr()),
                  Tab(text: 'lists'.tr()),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _AttendanceTab(
                  studentId: student.id,
                  attendanceValue: attendanceValue,
                ),
                _GradesTab(
                  studentId: student.id,
                  gradesValue: gradesValue,
                  gradeScaleJson: groupValue.value?.gradeScaleJson,
                  gradeCategoriesJson: groupValue.value?.gradeCategoriesJson,
                ),
                _MaterialTab(
                  studentId: student.id,
                  materialValue: materialValue,
                ),
                _HomeworkTab(
                  studentId: student.id,
                  homeworkValue: homeworkValue,
                ),
                _StudentNotesTab(
                  studentId: student.id,
                  notesValue: notesValue,
                  groups: groupsValue.value ?? const [],
                  students: allStudentsValue.value ?? const [],
                ),
                _ListsTab(
                  studentId: student.id,
                  listItemsValue: listItemsValue,
                ),
              ],
            ),
          ),
        );
      },
      error: (error, _) => const AppErrorScaffold(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Future<void> _editStudent(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    var deleted = false;
    final result = await showStudentFormSheet(
      context: context,
      initialFirstName: student.firstName,
      initialLastName: student.lastName,
      initialOriginNote: student.originNote,
      initialAvatarJson: student.avatarJson,
      title: 'edit'.tr(),
      onDelete: () async {
        await ref.read(studentRepositoryProvider).deleteStudent(student.id);
        deleted = true;
      },
    );
    if (deleted) {
      if (!context.mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/groups/${student.groupId}');
      }
      return;
    }
    if (result == null) {
      return;
    }

    await ref
        .read(studentRepositoryProvider)
        .updateStudent(
          id: student.id,
          firstName: result.firstName,
          lastName: result.lastName,
          originNote: result.originNote,
          avatarJson: result.avatarJson,
        );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return SwipeActionBackground(
      alignment: Alignment.centerRight,
      icon: Icons.delete_outline,
      label: 'delete'.tr(),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
    );
  }
}

class _GradesTab extends ConsumerStatefulWidget {
  const _GradesTab({
    required this.studentId,
    required this.gradesValue,
    required this.gradeScaleJson,
    required this.gradeCategoriesJson,
  });

  final int studentId;
  final AsyncValue<List<GradeEntry>> gradesValue;
  final String? gradeScaleJson;
  final String? gradeCategoriesJson;

  @override
  ConsumerState<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends ConsumerState<_GradesTab> {
  final Set<String> _selectedCategoryIds = <String>{};
  Set<String> _knownCategoryIds = const <String>{};
  bool _initializedCategorySelection = false;

  @override
  Widget build(BuildContext context) {
    return widget.gradesValue.when(
      data: (grades) {
        final gradeScaleEntries = widget.gradeScaleJson == null
            ? defaultGradeScaleEntries
            : parseGradeScaleEntries(widget.gradeScaleJson!);
        final gradeScale = [for (final entry in gradeScaleEntries) entry.label];
        final gradeCategories = parseGradeCategories(
          widget.gradeCategoriesJson,
        );
        _syncCategorySelection(gradeCategories);

        final filteredGrades = [
          for (final grade in grades)
            if (_selectedCategoryIds.contains(grade.categoryId)) grade,
        ];
        final tableGrades = [...filteredGrades]
          ..sort((left, right) => right.date.compareTo(left.date));
        final chartGrades = [...filteredGrades]
          ..sort((left, right) => left.date.compareTo(right.date));
        final numericGrades = <({GradeEntry grade, double value})>[];
        for (final grade in chartGrades) {
          final parsed = gradeValueToNumber(grade.value, gradeScaleEntries);
          if (parsed != null) {
            numericGrades.add((grade: grade, value: parsed));
          }
        }
        final average = calculateWeightedAverage([
          for (final entry in numericGrades)
            (value: entry.value, categoryId: entry.grade.categoryId),
        ], gradeCategories);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () =>
                    _addGrade(context, gradeScale, gradeCategories),
                icon: const Icon(Icons.add),
                label: Text('add_grade'.tr()),
              ),
            ),
            const SizedBox(height: 12),
            if (gradeCategories.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in gradeCategories)
                    FilterChip(
                      selected: _selectedCategoryIds.contains(category.id),
                      onSelected: (_) => setState(() {
                        if (!_selectedCategoryIds.remove(category.id)) {
                          _selectedCategoryIds.add(category.id);
                        }
                      }),
                      avatar: CircleAvatar(
                        radius: 7,
                        backgroundColor: colorForCategory(category),
                      ),
                      label: Text(category.name),
                      selectedColor: colorForCategory(
                        category,
                      ).withValues(alpha: 0.18),
                    ),
                ],
              ),
            if (gradeCategories.isNotEmpty) const SizedBox(height: 12),
            if (numericGrades.isNotEmpty && average != null)
              _GradeChartCard(
                numericGrades: numericGrades,
                average: average,
                gradeScaleEntries: gradeScaleEntries,
                categories: gradeCategories,
              ),
            if (numericGrades.isNotEmpty && average != null)
              const SizedBox(height: 16),
            if (grades.isEmpty)
              EmptyState(icon: Icons.show_chart, title: 'empty_grades'.tr())
            else if (filteredGrades.isEmpty)
              EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'empty_filtered_grades'.tr(),
              )
            else
              _GradesTable(
                grades: tableGrades,
                categories: gradeCategories,
                onEdit: (grade) =>
                    _editGrade(context, grade, gradeScale, gradeCategories),
                onAction: (action, grade) => _handleGradeAction(
                  context,
                  action,
                  grade,
                  gradeScale,
                  gradeCategories,
                ),
              ),
          ],
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  void _syncCategorySelection(List<GradeCategory> categories) {
    final categoryIds = {for (final category in categories) category.id};
    if (!_initializedCategorySelection) {
      _selectedCategoryIds
        ..clear()
        ..addAll(categoryIds);
      _knownCategoryIds = categoryIds;
      _initializedCategorySelection = true;
      return;
    }

    _selectedCategoryIds.removeWhere((id) => !categoryIds.contains(id));
    final newIds = categoryIds.difference(_knownCategoryIds);
    _selectedCategoryIds.addAll(newIds);
    _knownCategoryIds = categoryIds;
  }

  Future<void> _editGrade(
    BuildContext context,
    GradeEntry grade,
    List<String> gradeScale,
    List<GradeCategory> gradeCategories,
  ) async {
    final result = await showGradeEditorSheet(
      context: context,
      gradeScale: gradeScale,
      gradeCategories: gradeCategories,
      initialDate: grade.date,
      initialSessionLabel: grade.sessionLabel,
      initialValue: grade.value,
      initialCategoryId: grade.categoryId,
      title: 'edit_grade'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(gradeRepositoryProvider)
        .updateEntry(
          id: grade.id,
          studentId: grade.studentId,
          date: result.date,
          sessionLabel: result.sessionLabel,
          value: result.value,
          categoryId: result.categoryId,
          categoryName: result.categoryName,
        );
  }

  Future<void> _addGrade(
    BuildContext context,
    List<String> gradeScale,
    List<GradeCategory> gradeCategories,
  ) async {
    final result = await showGradeEditorSheet(
      context: context,
      gradeScale: gradeScale,
      gradeCategories: gradeCategories,
      title: 'add_grade'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(gradeRepositoryProvider)
        .saveEntry(
          studentId: widget.studentId,
          date: result.date,
          sessionLabel: result.sessionLabel,
          value: result.value,
          categoryId: result.categoryId,
          categoryName: result.categoryName,
        );
  }

  Future<void> _handleGradeAction(
    BuildContext context,
    _GradeRowAction action,
    GradeEntry grade,
    List<String> gradeScale,
    List<GradeCategory> gradeCategories,
  ) async {
    switch (action) {
      case _GradeRowAction.edit:
        await _editGrade(context, grade, gradeScale, gradeCategories);
        return;
      case _GradeRowAction.delete:
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'confirm_delete'.tr(namedArgs: {'name': grade.value}),
          body: _gradeLabelText(grade.sessionLabel),
        );
        if (confirmed) {
          await ref.read(gradeRepositoryProvider).deleteEntry(grade.id);
        }
        return;
    }
  }
}

class _GradesTable extends StatelessWidget {
  const _GradesTable({
    required this.grades,
    required this.categories,
    required this.onEdit,
    required this.onAction,
  });

  final List<GradeEntry> grades;
  final List<GradeCategory> categories;
  final ValueChanged<GradeEntry> onEdit;
  final void Function(_GradeRowAction action, GradeEntry grade) onAction;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd(context.locale.toLanguageTag());

    return Card(
      child: Column(
        children: [
          const _GradeTableHeader(),
          const Divider(height: 1),
          for (var index = 0; index < grades.length; index++) ...[
            _GradeTableRow(
              grade: grades[index],
              categoryLabel: categoryNameFor(
                categoryId: grades[index].categoryId,
                categories: categories,
                fallbackName: grades[index].categoryName,
              ),
              categoryColor: colorForCategoryId(
                categoryId: grades[index].categoryId,
                categories: categories,
              ),
              dateLabel: dateFormat.format(grades[index].date),
              onTap: () => onEdit(grades[index]),
              onAction: (action) => onAction(action, grades[index]),
            ),
            if (index != grades.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _GradeTableHeader extends StatelessWidget {
  const _GradeTableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              'grades'.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: Text(
              'grade_category'.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'label'.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 152,
            child: Text(
              'date'.tr(),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeTableRow extends StatelessWidget {
  const _GradeTableRow({
    required this.grade,
    required this.categoryLabel,
    required this.categoryColor,
    required this.dateLabel,
    required this.onTap,
    required this.onAction,
  });

  final GradeEntry grade;
  final String categoryLabel;
  final Color categoryColor;
  final String dateLabel;
  final VoidCallback onTap;
  final ValueChanged<_GradeRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                grade.value,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: _GradeCategoryBadge(
                label: categoryLabel,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _gradeLabelText(grade.sessionLabel),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 152,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<_GradeRowAction>(
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _GradeRowAction.edit,
                        child: Text('edit'.tr()),
                      ),
                      PopupMenuItem(
                        value: _GradeRowAction.delete,
                        child: Text('delete'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeChartCard extends StatelessWidget {
  const _GradeChartCard({
    required this.numericGrades,
    required this.average,
    required this.gradeScaleEntries,
    required this.categories,
  });

  final List<({GradeEntry grade, double value})> numericGrades;
  final double average;
  final List<GradeScaleEntry> gradeScaleEntries;
  final List<GradeCategory> categories;

  @override
  Widget build(BuildContext context) {
    final rawValues = numericGrades
        .map((entry) => entry.value)
        .toList(growable: false);
    final minRaw = rawValues.reduce(math.min);
    final maxRaw = rawValues.reduce(math.max);
    final shouldInvert = gradeScaleLowerValuesAreBetter(gradeScaleEntries);
    final plottedValues = [
      for (final value in rawValues)
        shouldInvert ? _flipValue(minRaw, maxRaw, value) : value,
    ];
    final plottedAverage = shouldInvert
        ? _flipValue(minRaw, maxRaw, average)
        : average;
    final minPlot = plottedValues.reduce(math.min);
    final maxPlot = plottedValues.reduce(math.max);
    final series = <_GradeSeries>[];
    final seenCategoryIds = <String>{};
    for (var index = 0; index < numericGrades.length; index++) {
      final categoryId = numericGrades[index].grade.categoryId;
      if (!seenCategoryIds.add(categoryId)) {
        continue;
      }

      final spots = <FlSpot>[];
      for (var spotIndex = 0; spotIndex < numericGrades.length; spotIndex++) {
        final grade = numericGrades[spotIndex].grade;
        if (grade.categoryId != categoryId) {
          continue;
        }
        spots.add(FlSpot(spotIndex.toDouble(), plottedValues[spotIndex]));
      }
      series.add(
        _GradeSeries(
          categoryId: categoryId,
          label: categoryNameFor(
            categoryId: categoryId,
            categories: categories,
            fallbackName: numericGrades[index].grade.categoryName,
          ),
          weight: weightForCategory(categoryId, categories),
          color: colorForCategoryId(
            categoryId: categoryId,
            categories: categories,
          ),
          spots: spots,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('grades'.tr(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    '${'average'.tr()}: '
                    '${gradeLabelForNumericValue(average, gradeScaleEntries)}',
                  ),
                ),
                Chip(label: Text('${numericGrades.length} ${'sessions'.tr()}')),
                for (final item in series)
                  Chip(
                    avatar: CircleAvatar(
                      radius: 7,
                      backgroundColor: item.color,
                    ),
                    label: Text('${item.label} (${formatNumber(item.weight)})'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(1, numericGrades.length - 1).toDouble(),
                  minY: minPlot - 0.4,
                  maxY: maxPlot + 0.4,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    horizontalInterval: math.max(
                      1,
                      ((maxPlot - minPlot).abs() / 4).ceilToDouble(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final restored = shouldInvert
                              ? _flipValue(minRaw, maxRaw, value)
                              : value;
                          return Text(
                            gradeLabelForNumericValue(
                              restored,
                              gradeScaleEntries,
                            ),
                            style: Theme.of(context).textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= numericGrades.length) {
                            return const SizedBox.shrink();
                          }

                          final interval = math.max(
                            1,
                            (numericGrades.length / 4).ceil(),
                          );
                          final shouldShow =
                              index == 0 ||
                              index == numericGrades.length - 1 ||
                              index % interval == 0;
                          if (!shouldShow) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat.Md(
                                context.locale.toLanguageTag(),
                              ).format(numericGrades[index].grade.date),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: plottedAverage,
                        dashArray: const [8, 4],
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots
                            .map((spot) {
                              final grade = numericGrades[spot.x.round()].grade;
                              final category = series[spot.barIndex];
                              return LineTooltipItem(
                                '${category.label}: ${grade.value}\n'
                                '${_gradeLabelText(grade.sessionLabel)}\n'
                                '${DateFormat.yMMMd(context.locale.toLanguageTag()).format(grade.date)}',
                                TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onInverseSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            })
                            .toList(growable: false);
                      },
                    ),
                  ),
                  lineBarsData: [
                    for (final item in series)
                      LineChartBarData(
                        isCurved: true,
                        barWidth: 3,
                        color: item.color,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: item.color,
                                strokeWidth: 1.5,
                                strokeColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                              ),
                        ),
                        spots: item.spots,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _flipValue(double minValue, double maxValue, double input) {
    return maxValue + minValue - input;
  }
}

class _GradeSeries {
  const _GradeSeries({
    required this.categoryId,
    required this.label,
    required this.weight,
    required this.color,
    required this.spots,
  });

  final String categoryId;
  final String label;
  final double weight;
  final Color color;
  final List<FlSpot> spots;
}

String _gradeLabelText(String sessionLabel) {
  final trimmed = sessionLabel.trim();
  return trimmed.isEmpty ? '—' : trimmed;
}

enum _GradeRowAction { edit, delete }

class _GradeCategoryBadge extends StatelessWidget {
  const _GradeCategoryBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialTab extends ConsumerWidget {
  const _MaterialTab({required this.studentId, required this.materialValue});

  final int studentId;
  final AsyncValue<List<MaterialLog>> materialValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return materialValue.when(
      data: (logs) {
        final hadMaterialCount = logs.where((log) => log.hadMaterial).length;
        final percentage = logs.isEmpty
            ? 0
            : ((hadMaterialCount / logs.length) * 100).round();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'material_summary'.tr(
                        namedArgs: {
                          'count': hadMaterialCount.toString(),
                          'total': logs.length.toString(),
                          'percent': percentage.toString(),
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => ref
                              .read(materialRepositoryProvider)
                              .saveLog(
                                studentId: studentId,
                                date: DateUtils.dateOnly(DateTime.now()),
                                hadMaterial: true,
                              ),
                          child: Text('today'.tr()),
                        ),
                        FilledButton.icon(
                          onPressed: () => _addMaterialLog(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text('add'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'empty_material'.tr(),
              )
            else
              for (final log in logs)
                Dismissible(
                  key: ValueKey('material-${log.id}'),
                  direction: DismissDirection.endToStart,
                  background: const _DeleteBackground(),
                  confirmDismiss: (_) => showConfirmDialog(
                    context: context,
                    title: 'confirm_delete'.tr(
                      namedArgs: {
                        'name': DateFormat.yMMMd(
                          context.locale.toLanguageTag(),
                        ).format(log.date),
                      },
                    ),
                    body: log.hadMaterial
                        ? 'had_material'.tr()
                        : 'missing_material'.tr(),
                  ),
                  onDismissed: (_) =>
                      ref.read(materialRepositoryProvider).deleteLog(log.id),
                  child: Card(
                    child: ListTile(
                      onTap: () => _editMaterialLog(context, ref, log),
                      title: Text(
                        DateFormat.yMMMd(
                          context.locale.toLanguageTag(),
                        ).format(log.date),
                      ),
                      subtitle: Text(
                        log.hadMaterial
                            ? 'had_material'.tr()
                            : 'missing_material'.tr(),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _editMaterialLog(context, ref, log),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'edit'.tr(),
                          ),
                          Switch(
                            value: log.hadMaterial,
                            onChanged: (value) => ref
                                .read(materialRepositoryProvider)
                                .saveLog(
                                  studentId: studentId,
                                  date: log.date,
                                  hadMaterial: value,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _addMaterialLog(BuildContext context, WidgetRef ref) async {
    final result = await showMaterialLogEditorSheet(
      context: context,
      initialDate: DateTime.now(),
      initialHadMaterial: true,
      title: 'material'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(materialRepositoryProvider)
        .saveLog(
          studentId: studentId,
          date: result.date,
          hadMaterial: result.hadMaterial,
        );
  }

  Future<void> _editMaterialLog(
    BuildContext context,
    WidgetRef ref,
    MaterialLog log,
  ) async {
    final result = await showMaterialLogEditorSheet(
      context: context,
      initialDate: log.date,
      initialHadMaterial: log.hadMaterial,
      title: 'edit_material'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(materialRepositoryProvider)
        .updateLog(
          id: log.id,
          studentId: log.studentId,
          date: result.date,
          hadMaterial: result.hadMaterial,
        );
  }
}

class _HomeworkTab extends ConsumerWidget {
  const _HomeworkTab({required this.studentId, required this.homeworkValue});

  final int studentId;
  final AsyncValue<List<HomeworkLog>> homeworkValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return homeworkValue.when(
      data: (logs) {
        final hadHomeworkCount = logs.where((log) => log.hadHomework).length;
        final percentage = logs.isEmpty
            ? 0
            : ((hadHomeworkCount / logs.length) * 100).round();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'homework_summary'.tr(
                        namedArgs: {
                          'count': hadHomeworkCount.toString(),
                          'total': logs.length.toString(),
                          'percent': percentage.toString(),
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => ref
                              .read(homeworkRepositoryProvider)
                              .saveLog(
                                studentId: studentId,
                                date: DateUtils.dateOnly(DateTime.now()),
                                hadHomework: true,
                              ),
                          child: Text('today'.tr()),
                        ),
                        FilledButton.icon(
                          onPressed: () => _addHomeworkLog(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text('add'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              EmptyState(
                icon: Icons.assignment_turned_in_outlined,
                title: 'empty_homework'.tr(),
              )
            else
              for (final log in logs)
                Dismissible(
                  key: ValueKey('homework-${log.id}'),
                  direction: DismissDirection.endToStart,
                  background: const _DeleteBackground(),
                  confirmDismiss: (_) => showConfirmDialog(
                    context: context,
                    title: 'confirm_delete'.tr(
                      namedArgs: {
                        'name': DateFormat.yMMMd(
                          context.locale.toLanguageTag(),
                        ).format(log.date),
                      },
                    ),
                    body: log.hadHomework
                        ? 'had_homework'.tr()
                        : 'missing_homework'.tr(),
                  ),
                  onDismissed: (_) =>
                      ref.read(homeworkRepositoryProvider).deleteLog(log.id),
                  child: Card(
                    child: ListTile(
                      onTap: () => _editHomeworkLog(context, ref, log),
                      title: Text(
                        DateFormat.yMMMd(
                          context.locale.toLanguageTag(),
                        ).format(log.date),
                      ),
                      subtitle: Text(
                        log.hadHomework
                            ? 'had_homework'.tr()
                            : 'missing_homework'.tr(),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _editHomeworkLog(context, ref, log),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'edit'.tr(),
                          ),
                          Switch(
                            value: log.hadHomework,
                            onChanged: (value) => ref
                                .read(homeworkRepositoryProvider)
                                .saveLog(
                                  studentId: studentId,
                                  date: log.date,
                                  hadHomework: value,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _addHomeworkLog(BuildContext context, WidgetRef ref) async {
    final result = await showHomeworkLogEditorSheet(
      context: context,
      initialDate: DateTime.now(),
      initialHadHomework: true,
      title: 'homework'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(homeworkRepositoryProvider)
        .saveLog(
          studentId: studentId,
          date: result.date,
          hadHomework: result.hadHomework,
        );
  }

  Future<void> _editHomeworkLog(
    BuildContext context,
    WidgetRef ref,
    HomeworkLog log,
  ) async {
    final result = await showHomeworkLogEditorSheet(
      context: context,
      initialDate: log.date,
      initialHadHomework: log.hadHomework,
      title: 'edit_homework'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(homeworkRepositoryProvider)
        .updateLog(
          id: log.id,
          studentId: log.studentId,
          date: result.date,
          hadHomework: result.hadHomework,
        );
  }
}

class _StudentNotesTab extends ConsumerWidget {
  const _StudentNotesTab({
    required this.studentId,
    required this.notesValue,
    required this.groups,
    required this.students,
  });

  final int studentId;
  final AsyncValue<List<TeacherNote>> notesValue;
  final List<Group> groups;
  final List<Student> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    return notesValue.when(
      data: (notes) {
        final studentsById = {
          for (final student in students) student.id: student,
        };
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _addNote(context, ref),
                icon: const Icon(Icons.add),
                label: Text('add_note'.tr()),
              ),
            ),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              EmptyState(
                icon: Icons.sticky_note_2_outlined,
                title: 'empty_notes'.tr(),
              )
            else
              for (final note in notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: Dismissible(
                    key: ValueKey('note-${note.id}'),
                    direction: DismissDirection.horizontal,
                    background: SwipeActionBackground(
                      alignment: Alignment.centerLeft,
                      icon: Icons.archive_outlined,
                      label: 'archive'.tr(),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer,
                    ),
                    secondaryBackground: SwipeActionBackground(
                      alignment: Alignment.centerRight,
                      icon: Icons.delete_outline,
                      label: 'delete'.tr(),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                    ),
                    confirmDismiss: (direction) async {
                      switch (direction) {
                        case DismissDirection.startToEnd:
                          return true;
                        case DismissDirection.endToStart:
                          return showConfirmDialog(
                            context: context,
                            title: 'confirm_delete'.tr(
                              namedArgs: {'name': 'note_body'.tr()},
                            ),
                            body: note.body,
                          );
                        case DismissDirection.none:
                        case DismissDirection.down:
                        case DismissDirection.up:
                        case DismissDirection.horizontal:
                        case DismissDirection.vertical:
                          return false;
                      }
                    },
                    onDismissed: (direction) {
                      switch (direction) {
                        case DismissDirection.startToEnd:
                          ref.read(noteRepositoryProvider).archiveNote(note.id);
                          return;
                        case DismissDirection.endToStart:
                          ref.read(noteRepositoryProvider).deleteNote(note.id);
                          return;
                        case DismissDirection.none:
                        case DismissDirection.down:
                        case DismissDirection.up:
                        case DismissDirection.horizontal:
                        case DismissDirection.vertical:
                          return;
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final relatedStudents = [
                          for (final linkedStudentId in noteStudentIds(note))
                            if (linkedStudentId != studentId &&
                                studentsById[linkedStudentId] != null)
                              studentsById[linkedStudentId]!,
                        ];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppRadii.xLarge,
                            ),
                            onTap: () => _editNote(context, ref, note),
                            child: Padding(
                              padding: appCardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (note.isTodo) ...[
                                        Checkbox(
                                          value: note.todoDone,
                                          onChanged: (value) => ref
                                              .read(noteRepositoryProvider)
                                              .toggleTodo(note, value ?? false),
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.xSmall,
                                        ),
                                      ],
                                      Expanded(
                                        child: Text(
                                          note.body,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.medium),
                                      IconButton(
                                        onPressed: () =>
                                            _editNote(context, ref, note),
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'edit'.tr(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  Wrap(
                                    spacing: AppSpacing.small,
                                    runSpacing: AppSpacing.small,
                                    children: [
                                      if (note.isTodo)
                                        Chip(
                                          label: Text(
                                            note.todoDone
                                                ? 'done'.tr()
                                                : 'todo'.tr(),
                                          ),
                                        ),
                                      for (final linkedStudent
                                          in relatedStudents)
                                        Chip(
                                          avatar: StudentAvatar(
                                            student: linkedStudent,
                                            size: 20,
                                          ),
                                          label: Text(
                                            studentDisplayName(
                                              firstName:
                                                  linkedStudent.firstName,
                                              lastName: linkedStudent.lastName,
                                              sortField: sortField,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  Text(
                                    DateFormat.yMMMd(
                                      context.locale.toLanguageTag(),
                                    ).format(note.createdAt),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          ],
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: groups,
      students: students,
      initialStudentIds: [studentId],
    );
    if (result == null) {
      return;
    }

    await ref
        .read(noteRepositoryProvider)
        .saveNote(
          body: result.body,
          groupId: result.groupId,
          studentIds: result.studentIds,
          isTodo: result.isTodo,
          createdAt: result.createdAt,
        );
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    TeacherNote note,
  ) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: groups,
      students: students,
      initialGroupId: note.groupId,
      initialStudentIds: noteStudentIds(note),
      initialBody: note.body,
      initialIsTodo: note.isTodo,
      initialCreatedAt: note.createdAt,
      title: 'edit_note'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(noteRepositoryProvider)
        .updateNote(
          note: note,
          body: result.body,
          groupId: result.groupId,
          studentIds: result.studentIds,
          isTodo: result.isTodo,
          createdAt: result.createdAt,
        );
  }
}

class _ListsTab extends ConsumerWidget {
  const _ListsTab({required this.studentId, required this.listItemsValue});

  final int studentId;
  final AsyncValue<List<({Checklist list, ChecklistItem item})>> listItemsValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return listItemsValue.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.checklist_outlined,
            title: 'empty_student_lists'.tr(),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: _ListItemTile(item: entry),
              ),
          ],
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ListItemTile extends ConsumerWidget {
  const _ListItemTile({required this.item});

  final ({Checklist list, ChecklistItem item}) item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedAt = item.item.checkedAt;
    final checked = checkedAt != null;

    void toggle(bool value) => ref
        .read(listRepositoryProvider)
        .toggleItem(itemId: item.item.id, checked: value);

    return Card(
      child: ListTile(
        onTap: () => toggle(!checked),
        title: Text(item.list.name),
        subtitle: checkedAt == null
            ? null
            : Text(
                MaterialLocalizations.of(context).formatMediumDate(checkedAt),
              ),
        trailing: Checkbox(
          value: checked,
          onChanged: (value) => toggle(value ?? false),
        ),
      ),
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({
    required this.studentId,
    required this.attendanceValue,
  });

  final int studentId;
  final AsyncValue<List<AttendanceLog>> attendanceValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return attendanceValue.when(
      data: (logs) {
        final dateFormat = DateFormat.yMMMd(context.locale.toLanguageTag());
        final absentLogs = logs.where((l) => l.isAbsent).toList();
        final presentLogs = logs.where((l) => !l.isAbsent).toList();
        final excusedCount = absentLogs.where((l) => l.isExcused).length;
        final unexcusedCount = absentLogs.length - excusedCount;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'attendance_summary'.tr(
                        namedArgs: {
                          'absent': absentLogs.length.toString(),
                          'excused': excusedCount.toString(),
                          'unexcused': unexcusedCount.toString(),
                          'present': presentLogs.length.toString(),
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => ref
                              .read(attendanceRepositoryProvider)
                              .markAbsent(
                                studentId: studentId,
                                date: DateUtils.dateOnly(DateTime.now()),
                              ),
                          child: Text('today'.tr()),
                        ),
                        FilledButton.icon(
                          onPressed: () => _addAbsence(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text('add'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              EmptyState(
                icon: Icons.event_available_outlined,
                title: 'empty_attendance'.tr(),
              )
            else ...[
              if (absentLogs.isNotEmpty) _AttendanceBarChart(logs: absentLogs),
              if (absentLogs.isNotEmpty) const SizedBox(height: 12),
              for (final log in logs)
                Dismissible(
                  key: ValueKey('attendance-${log.id}'),
                  direction: DismissDirection.endToStart,
                  background: const _DeleteBackground(),
                  confirmDismiss: (_) => showConfirmDialog(
                    context: context,
                    title: 'confirm_delete'.tr(
                      namedArgs: {
                        'name': dateFormat.format(log.date),
                      },
                    ),
                    body: log.isAbsent
                        ? (log.isExcused ? 'excused' : 'unexcused').tr()
                        : 'present'.tr(),
                  ),
                  onDismissed: (_) => ref
                      .read(attendanceRepositoryProvider)
                      .clearAbsence(
                        studentId: studentId,
                        date: log.date,
                      ),
                  child: _AttendanceLogTile(
                    log: log,
                    dateFormat: dateFormat,
                    onDelete: () => ref
                        .read(attendanceRepositoryProvider)
                        .clearAbsence(
                          studentId: studentId,
                          date: log.date,
                        ),
                    onToggleExcused: (excused) => ref
                        .read(attendanceRepositoryProvider)
                        .setExcused(
                          studentId: studentId,
                          date: log.date,
                          excused: excused,
                        ),
                  ),
                ),
            ],
          ],
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _addAbsence(BuildContext context, WidgetRef ref) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;

    await ref.read(attendanceRepositoryProvider).markAbsent(
          studentId: studentId,
          date: DateUtils.dateOnly(selected),
        );
  }
}

class _AttendanceLogTile extends StatelessWidget {
  const _AttendanceLogTile({
    required this.log,
    required this.dateFormat,
    required this.onDelete,
    required this.onToggleExcused,
  });

  final AttendanceLog log;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleExcused;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAbsent = log.isAbsent;
    final isExcused = log.isExcused;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (!isAbsent) {
      statusColor = colorScheme.primary;
      statusIcon = Icons.event_available_outlined;
      statusLabel = 'present'.tr();
    } else if (isExcused) {
      statusColor = colorScheme.tertiary;
      statusIcon = Icons.event_busy_outlined;
      statusLabel = 'excused'.tr();
    } else {
      statusColor = colorScheme.error;
      statusIcon = Icons.event_busy_outlined;
      statusLabel = 'unexcused'.tr();
    }

    return Card(
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(dateFormat.format(log.date)),
        subtitle: Text(statusLabel, style: TextStyle(color: statusColor)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAbsent)
              IconButton(
                onPressed: () => onToggleExcused(!isExcused),
                icon: Icon(
                  isExcused
                      ? Icons.check_circle_outline
                      : Icons.unpublished_outlined,
                ),
                tooltip: isExcused ? 'unexcused'.tr() : 'excused'.tr(),
                color: isExcused ? colorScheme.tertiary : null,
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'delete'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBarChart extends StatelessWidget {
  const _AttendanceBarChart({required this.logs});

  final List<AttendanceLog> logs;

  @override
  Widget build(BuildContext context) {
    final monthlyCounts = <(int year, int month), int>{};
    for (final log in logs) {
      final key = (log.date.year, log.date.month);
      monthlyCounts[key] = (monthlyCounts[key] ?? 0) + 1;
    }

    final sortedMonths = monthlyCounts.keys.toList()
      ..sort((a, b) {
        final yearCmp = a.$1.compareTo(b.$1);
        return yearCmp != 0 ? yearCmp : a.$2.compareTo(b.$2);
      });

    final maxCount = monthlyCounts.values.reduce(math.max).toDouble();

    final barGroups = [
      for (var i = 0; i < sortedMonths.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthlyCounts[sortedMonths[i]]!.toDouble(),
              color: Theme.of(context).colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'absences_per_month'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxCount + 1,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= sortedMonths.length) {
                            return const SizedBox.shrink();
                          }
                          final month = sortedMonths[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat.MMM(
                                Localizations.localeOf(
                                  context,
                                ).toLanguageTag(),
                              ).format(DateTime(month.$1, month.$2)),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
