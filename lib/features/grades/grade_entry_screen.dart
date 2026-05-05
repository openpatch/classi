import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_bar_title.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/student_avatar.dart';
import 'grade_picker_dialog.dart';

final gradeEntryGroupProvider = StreamProvider.family<Group?, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final gradeEntryStudentsProvider = StreamProvider.family<List<Student>, String>(
  (ref, groupId) => ref
      .watch(studentRepositoryProvider)
      .watchByGroup(groupId, sortField: ref.watch(studentSortFieldProvider)),
);

final gradeSelectionsProvider =
    FutureProvider.family<Map<String, String>, (String, DateTime, String, String)>(
      (ref, args) => ref
          .watch(gradeRepositoryProvider)
          .getSessionSelections(
            groupId: args.$1,
            date: args.$2,
            sessionLabel: args.$3,
            categoryId: args.$4,
          ),
    );

class GradeEntryScreen extends ConsumerStatefulWidget {
  const GradeEntryScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends ConsumerState<GradeEntryScreen> {
  static const String _noGradeSelectionValue = '__classi_no_grade__';

  late final TextEditingController _sessionController;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _sessionController = TextEditingController();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    final groupValue = ref.watch(gradeEntryGroupProvider(widget.groupId));
    final studentsValue = ref.watch(gradeEntryStudentsProvider(widget.groupId));

    return groupValue.when(
      data: (group) {
        if (group == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final gradeScaleEntries = parseGradeScaleEntries(group.gradeScaleJson);
        final gradeScale = [for (final entry in gradeScaleEntries) entry.label];
        final gradeCategories = parseGradeCategories(group.gradeCategoriesJson);
        _selectedCategoryId ??= gradeCategories.first.id;
        final sessionLabel = _sessionController.text.trim();
        final selectionsValue = ref.watch(
          gradeSelectionsProvider((
            widget.groupId,
            _selectedDate,
            sessionLabel,
            _selectedCategoryId ?? defaultGradeCategoryId,
          )),
        );
        final selectedCategory = gradeCategories.firstWhere(
          (category) => category.id == _selectedCategoryId,
          orElse: () => gradeCategories.first,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colorFromHex(group.colorHex),
            foregroundColor: onColorForBackground(colorFromHex(group.colorHex)),
            title: AppBarTitle(title: 'grade_entry'.tr(), subtitle: group.name),
          ),
          body: studentsValue.when(
            data: (students) {
              final selections = selectionsValue.value ?? const <String, String>{};
              final done = selections.length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _sessionController,
                            decoration: InputDecoration(
                              labelText: 'session_label'.tr(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            items: [
                              for (final category in gradeCategories)
                                DropdownMenuItem(
                                  value: category.id,
                                  child: Text(
                                    '${category.name} (${formatNumber(category.weight)})',
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedCategoryId = value),
                            decoration: InputDecoration(
                              labelText: 'grade_category'.tr(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('date'.tr()),
                            subtitle: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_selectedDate),
                            ),
                            trailing: IconButton(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: students.isEmpty
                                ? 0
                                : done / students.length,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'progress'.tr(
                              namedArgs: {
                                'done': done.toString(),
                                'total': students.length.toString(),
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3.6),
                        1: FlexColumnWidth(2.1),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          children: [
                            _GradeHeaderCell(label: 'name'.tr()),
                            _GradeHeaderCell(label: 'grade'.tr()),
                          ],
                        ),
                        for (final student in students)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    StudentAvatar(student: student, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        studentDisplayName(
                                          firstName: student.firstName,
                                          lastName: student.lastName,
                                          sortField: sortField,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _GradeSelectionCell(
                                key: ValueKey(
                                  '${student.id}:${selections[student.id] ?? _noGradeSelectionValue}',
                                ),
                                value:
                                    selections[student.id] ??
                                    _noGradeSelectionValue,
                                gradeScale: gradeScale,
                                noGradeValue: _noGradeSelectionValue,
                                onTap: () => _pickGrade(
                                  studentId: student.id,
                                  category: selectedCategory,
                                  currentValue:
                                      selections[student.id] ??
                                      _noGradeSelectionValue,
                                  gradeScale: gradeScale,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
            error: (error, _) => const AppErrorState(),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, _) => const AppErrorScaffold(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _selectedDate = DateUtils.dateOnly(selected));
    }
  }

  Future<void> _saveGrade({
    required String studentId,
    required GradeCategory category,
    required String value,
  }) async {
    final sessionLabel = _sessionController.text.trim();
    await ref
        .read(gradeRepositoryProvider)
        .saveEntry(
          studentId: studentId,
          date: _selectedDate,
          sessionLabel: sessionLabel,
          value: value,
          categoryId: category.id,
          categoryName: category.name,
        );
    ref.invalidate(
      gradeSelectionsProvider((
        widget.groupId,
        _selectedDate,
        sessionLabel,
        category.id,
      )),
    );
  }

  Future<void> _setGradeValue({
    required String studentId,
    required GradeCategory category,
    required String? value,
  }) {
    if (value == null || value == _noGradeSelectionValue) {
      return _clearGrade(studentId: studentId, category: category);
    }
    return _saveGrade(studentId: studentId, category: category, value: value);
  }

  Future<void> _pickGrade({
    required String studentId,
    required GradeCategory category,
    required String currentValue,
    required List<String> gradeScale,
  }) async {
    final result = await showGradePickerDialog(
      context: context,
      gradeScale: gradeScale,
      initialValue: currentValue == _noGradeSelectionValue
          ? null
          : currentValue,
    );
    if (result == null || !result.confirmed) {
      return;
    }

    await _setGradeValue(
      studentId: studentId,
      category: category,
      value: result.value ?? _noGradeSelectionValue,
    );
  }

  Future<void> _clearGrade({
    required String studentId,
    required GradeCategory category,
  }) async {
    final sessionLabel = _sessionController.text.trim();
    await ref
        .read(gradeRepositoryProvider)
        .clearSessionSelection(
          studentId: studentId,
          date: _selectedDate,
          sessionLabel: sessionLabel,
          categoryId: category.id,
        );
    ref.invalidate(
      gradeSelectionsProvider((
        widget.groupId,
        _selectedDate,
        sessionLabel,
        category.id,
      )),
    );
  }
}

class _GradeHeaderCell extends StatelessWidget {
  const _GradeHeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GradeSelectionCell extends StatelessWidget {
  const _GradeSelectionCell({
    required this.value,
    required this.gradeScale,
    required this.noGradeValue,
    required this.onTap,
    super.key,
  });

  final String value;
  final List<String> gradeScale;
  final String noGradeValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasGrade = value != noGradeValue;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasGrade ? value : 'no_grade'.tr(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
