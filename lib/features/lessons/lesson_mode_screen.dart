import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_bar_title.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/content_constraints.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../shared/theme/app_ui.dart';
import '../grades/grade_picker_dialog.dart';
import '../notes/note_editor.dart';
import '../notes/note_links.dart';
import '../seating_plan/lesson_seating_view.dart';
import 'lesson_sections.dart';
import 'lesson_support.dart';
import 'lesson_widgets.dart';

class LessonModeScreen extends ConsumerStatefulWidget {
  const LessonModeScreen({
    required this.groupId,
    required this.initialDate,
    this.initialSessionLabel,
    this.initialCategoryId,
    super.key,
  });

  final int groupId;
  final DateTime initialDate;
  final String? initialSessionLabel;
  final String? initialCategoryId;

  @override
  ConsumerState<LessonModeScreen> createState() => _LessonModeScreenState();
}

class _LessonModeScreenState extends ConsumerState<LessonModeScreen> {
  static const String _noGradeSelectionValue = '__classi_no_grade__';

  late final TextEditingController _sessionController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  _LessonViewMode _viewMode = _LessonViewMode.list;

  @override
  void initState() {
    super.initState();
    _selectedDate = normalizeLessonDate(widget.initialDate);
    _selectedCategoryId = widget.initialCategoryId;
    _sessionController = TextEditingController(
      text: widget.initialSessionLabel,
    );
    Future<void>.microtask(_restoreSessionLabelForCurrentSelection);
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupValue = ref.watch(lessonGroupProvider(widget.groupId));
    final studentsValue = ref.watch(lessonStudentsProvider(widget.groupId));
    final materialSelectionsValue = ref.watch(
      lessonMaterialSelectionsProvider((widget.groupId, _selectedDate)),
    );
    final homeworkSelectionsValue = ref.watch(
      lessonHomeworkSelectionsProvider((widget.groupId, _selectedDate)),
    );
    final absenceSelectionsValue = ref.watch(
      lessonAbsenceSelectionsProvider((widget.groupId, _selectedDate)),
    );
    final excusedSelectionsValue = ref.watch(
      lessonExcusedSelectionsProvider((widget.groupId, _selectedDate)),
    );
    final notesValue = ref.watch(lessonNotesProvider(widget.groupId));

    return groupValue.when(
      data: (group) {
        if (group == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final groupColor = colorFromHex(group.colorHex);
        final appBarForeground = onColorForBackground(groupColor);
        final gradeCategories = parseGradeCategories(group.gradeCategoriesJson);
        _selectedCategoryId ??= gradeCategories.first.id;
        final selectedCategory = _resolveSelectedCategory(gradeCategories);
        final gradeScale = [
          for (final entry in parseGradeScaleEntries(group.gradeScaleJson))
            entry.label,
        ];
        final sessionLabel = _sessionController.text.trim();
        final gradeSelectionsValue = ref.watch(
          lessonGradeSelectionsProvider((
            widget.groupId,
            _selectedDate,
            sessionLabel,
            selectedCategory.id,
          )),
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: groupColor,
            foregroundColor: appBarForeground,
            title: AppBarTitle(title: 'lesson_mode'.tr(), subtitle: group.name),
            actions: [
              IconButton(
                onPressed: () async {
                  await ref
                      .read(attendanceRepositoryProvider)
                      .savePresenceForDate(
                        groupId: widget.groupId,
                        date: _selectedDate,
                      );
                  if (context.mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/groups/${widget.groupId}');
                    }
                  }
                },
                icon: const Icon(Icons.check),
                tooltip: 'save'.tr(),
              ),
            ],
          ),
          floatingActionButton: gradeCategories.length <= 1
              ? null
              : LessonCategoryFabMenu(
                  categories: gradeCategories,
                  selectedCategoryId: selectedCategory.id,
                  heroTagPrefix: 'lesson-category-${widget.groupId}',
                  mainLabel: selectedCategory.name,
                  mainIcon: Icons.category_outlined,
                  backgroundColor: colorForCategory(selectedCategory),
                  foregroundColor: onColorForBackground(
                    colorForCategory(selectedCategory),
                  ),
                  onSelected: _selectCategory,
                ),
          body: studentsValue.when(
            data: (students) {
              if (students.isEmpty) {
                return EmptyState(
                  icon: Icons.people_outline,
                  title: 'empty_students'.tr(),
                );
              }

              final materialSelections =
                  materialSelectionsValue.value ?? const <int, bool>{};
              final homeworkSelections =
                  homeworkSelectionsValue.value ?? const <int, bool>{};
              final absentStudents =
                  absenceSelectionsValue.value ?? const <int>{};
              final excusedStudents =
                  excusedSelectionsValue.value ?? const <int>{};
              final gradeSelections =
                  gradeSelectionsValue.value ?? const <int, String>{};
              final lessonNotes = notesForLessonDate(
                notesValue.value ?? const <TeacherNote>[],
                _selectedDate,
              );
              final noteCountsByStudent = <int, int>{};
              for (final note in lessonNotes) {
                for (final studentId in noteStudentIds(note)) {
                  noteCountsByStudent.update(
                    studentId,
                    (count) => count + 1,
                    ifAbsent: () => 1,
                  );
                }
              }

              return ContentConstraints(
                child: ListView(
                  padding: appScreenPadding,
                  children: [
                    LessonContextCard(
                      sessionController: _sessionController,
                      selectedDate: _selectedDate,
                      onSessionChanged: (_) => setState(() {}),
                      onPickDate: _pickDate,
                      action: absentStudents.isNotEmpty
                          ? OutlinedButton.icon(
                              onPressed: () => _clearAbsencesForDate(context),
                              icon: const Icon(Icons.person_off_outlined),
                              label: Text('clear_absences_for_date'.tr()),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    LessonSummaryCard(
                      absentCount: absentStudents.length,
                      gradeCount: gradeSelections.length,
                      homeworkCount: homeworkSelections.length,
                      materialCount: materialSelections.length,
                      totalStudents: students.length,
                      onAbsentTap: absentStudents.isNotEmpty
                          ? () => _showAbsentStudents(
                              context: context,
                              students: students,
                              absentStudents: absentStudents,
                              excusedStudents: excusedStudents,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    LessonNotesCard(
                      notes: lessonNotes,
                      students: students,
                      onAddGroupNote: () => _addGroupNote(
                        context: context,
                        group: group,
                        students: students,
                      ),
                      onEditNote: (note) => _editNote(
                        context: context,
                        group: group,
                        students: students,
                        note: note,
                      ),
                      onDeleteNote: (note) =>
                          _deleteNote(context: context, note: note),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    _LessonViewToggle(
                      viewMode: _viewMode,
                      onChanged: (mode) =>
                          setState(() => _viewMode = mode),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    if (_viewMode == _LessonViewMode.list)
                      LessonStudentsTable(
                        students: students,
                        absentStudents: absentStudents,
                        excusedStudents: excusedStudents,
                        materialSelections: materialSelections,
                        homeworkSelections: homeworkSelections,
                        gradeSelections: gradeSelections,
                        noteCountsByStudent: noteCountsByStudent,
                        onOpenStudent: (student) =>
                            context.push('/students/${student.id}'),
                        onSetAbsent: (student) =>
                            _setAbsent(studentId: student.id, absent: true),
                        onSetPresent: (student) =>
                            _setAbsent(studentId: student.id, absent: false),
                        onToggleExcused: (student, excused) => _toggleExcused(
                          studentId: student.id,
                          excused: excused,
                        ),
                        onMaterialChanged: (student, value) =>
                            _setMaterialValue(
                          studentId: student.id,
                          value: value,
                        ),
                        onHomeworkChanged: (student, value) =>
                            _setHomeworkValue(
                          studentId: student.id,
                          value: value,
                        ),
                        onPickGrade: (student) => _pickGrade(
                          studentId: student.id,
                          category: selectedCategory,
                          currentValue:
                              gradeSelections[student.id] ??
                              _noGradeSelectionValue,
                          gradeScale: gradeScale,
                        ),
                        onOpenNotes: (student) => _showStudentNotes(
                          context: context,
                          group: group,
                          students: students,
                          student: student,
                        ),
                        onAddQuickNote: (student) => _addQuickNote(
                          context: context,
                          group: group,
                          student: student,
                        ),
                      )
                    else
                      LessonSeatingView(
                        groupId: widget.groupId,
                        students: students,
                        absentStudents: absentStudents,
                        excusedStudents: excusedStudents,
                        gradeSelections: gradeSelections,
                        noteCountsByStudent: noteCountsByStudent,
                        onSetAbsent: (student) =>
                            _setAbsent(studentId: student.id, absent: true),
                        onSetPresent: (student) =>
                            _setAbsent(studentId: student.id, absent: false),
                        onToggleExcused: (student, excused) => _toggleExcused(
                          studentId: student.id,
                          excused: excused,
                        ),
                        onMaterialChanged: (student, value) =>
                            _setMaterialValue(
                          studentId: student.id,
                          value: value,
                        ),
                        onHomeworkChanged: (student, value) =>
                            _setHomeworkValue(
                          studentId: student.id,
                          value: value,
                        ),
                        onPickGrade: (student) => _pickGrade(
                          studentId: student.id,
                          category: selectedCategory,
                          currentValue:
                              gradeSelections[student.id] ??
                              _noGradeSelectionValue,
                          gradeScale: gradeScale,
                        ),
                        onOpenNotes: (student) => _showStudentNotes(
                          context: context,
                          group: group,
                          students: students,
                          student: student,
                        ),
                        onAddQuickNote: (student) => _addQuickNote(
                          context: context,
                          group: group,
                          student: student,
                        ),
                        onOpenStudent: (student) =>
                            context.push('/students/${student.id}'),
                      ),
                  ],
                ),
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

  GradeCategory _resolveSelectedCategory(List<GradeCategory> categories) {
    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null) {
      return categories.first;
    }

    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        return category;
      }
    }

    return GradeCategory(
      id: selectedCategoryId,
      name: categoryNameFor(
        categoryId: selectedCategoryId,
        categories: categories,
      ),
      weight: 1,
      colorHex: colorToHex(
        colorForCategoryId(
          categoryId: selectedCategoryId,
          categories: categories,
        ),
      ),
    );
  }

  Future<void> _selectCategory(GradeCategory category) async {
    if (category.id == _selectedCategoryId) {
      return;
    }
    setState(() => _selectedCategoryId = category.id);
    await _restoreSessionLabelForCurrentSelection(
      categoryId: category.id,
      date: _selectedDate,
    );
  }

  Future<void> _restoreSessionLabelForCurrentSelection({
    String? categoryId,
    DateTime? date,
  }) async {
    if (_sessionController.text.trim().isNotEmpty) {
      return;
    }

    final targetCategoryId = (categoryId ?? _selectedCategoryId)?.trim();
    if (targetCategoryId == null || targetCategoryId.isEmpty) {
      return;
    }
    final targetDate = normalizeLessonDate(date ?? _selectedDate);
    final sessionLabel = await ref
        .read(gradeRepositoryProvider)
        .getPreferredSessionLabel(
          groupId: widget.groupId,
          date: targetDate,
          categoryId: targetCategoryId,
        );
    if (!mounted ||
        sessionLabel == null ||
        _sessionController.text.trim().isNotEmpty ||
        _selectedCategoryId != targetCategoryId ||
        _selectedDate != targetDate) {
      return;
    }

    _sessionController.text = sessionLabel;
    setState(() {});
  }

  Future<void> _showAbsentStudents({
    required BuildContext context,
    required List<Student> students,
    required Set<int> absentStudents,
    required Set<int> excusedStudents,
  }) {
    final sortField = ref.read(studentSortFieldProvider);
    final absentList = [
      for (final student in students)
        if (absentStudents.contains(student.id)) student,
    ];

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xLarge,
            AppSpacing.small,
            AppSpacing.xLarge,
            AppSpacing.xxLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('absent'.tr(), style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.large),
              for (final student in absentList)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: StudentAvatar(student: student, size: 36),
                  title: Text(
                    studentDisplayName(
                      firstName: student.firstName,
                      lastName: student.lastName,
                      sortField: sortField,
                    ),
                  ),
                  trailing: excusedStudents.contains(student.id)
                      ? Chip(
                          label: Text('excused'.tr()),
                          visualDensity: VisualDensity.compact,
                        )
                      : Chip(
                          label: Text('unexcused'.tr()),
                          visualDensity: VisualDensity.compact,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }

    setState(() => _selectedDate = normalizeLessonDate(selected));
    await _restoreSessionLabelForCurrentSelection(date: _selectedDate);
  }

  Future<void> _addGroupNote({
    required BuildContext context,
    required Group group,
    required List<Student> students,
  }) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: [group],
      students: students,
      initialGroupId: group.id,
      initialCreatedAt: _selectedDate,
      title: 'add_group_note'.tr(),
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

  Future<void> _addStudentNote({
    required BuildContext context,
    required Group group,
    required List<Student> students,
    required Student student,
  }) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: [group],
      students: students,
      initialGroupId: group.id,
      initialStudentIds: [student.id],
      initialCreatedAt: _selectedDate,
      title: 'add_note'.tr(),
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

  Future<void> _editNote({
    required BuildContext context,
    required Group group,
    required List<Student> students,
    required TeacherNote note,
  }) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: [group],
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

  Future<void> _deleteNote({
    required BuildContext context,
    required TeacherNote note,
  }) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_delete'.tr(namedArgs: {'name': 'note_body'.tr()}),
      body: note.body,
    );
    if (!confirmed) {
      return;
    }

    await ref.read(noteRepositoryProvider).deleteNote(note.id);
  }

  Future<void> _showStudentNotes({
    required BuildContext context,
    required Group group,
    required List<Student> students,
    required Student student,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => LessonStudentNotesSheet(
        groupId: group.id,
        selectedDate: _selectedDate,
        student: student,
        students: students,
        onAddNote: () => _addStudentNote(
          context: sheetContext,
          group: group,
          students: students,
          student: student,
        ),
        onEditNote: (note) => _editNote(
          context: sheetContext,
          group: group,
          students: students,
          note: note,
        ),
        onDeleteNote: (note) => _deleteNote(context: sheetContext, note: note),
      ),
    );
  }

  Future<void> _addQuickNote({
    required BuildContext context,
    required Group group,
    required Student student,
  }) async {
    final sortField = ref.read(studentSortFieldProvider);
    final name = studentDisplayName(
      firstName: student.firstName,
      lastName: student.lastName,
      sortField: sortField,
    );
    final body = await _showQuickNoteDialog(
      context: context,
      studentName: name,
    );
    if (body == null || body.trim().isEmpty) return;

    await ref
        .read(noteRepositoryProvider)
        .saveNote(
          body: body.trim(),
          groupId: group.id,
          studentIds: [student.id],
          isTodo: false,
          createdAt: _selectedDate,
        );
  }

  Future<String?> _showQuickNoteDialog({
    required BuildContext context,
    required String studentName,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) =>
          _QuickNoteDialog(studentName: studentName, controller: controller),
    );
  }

  Future<void> _setMaterialValue({
    required int studentId,
    required bool? value,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .clearAbsence(studentId: studentId, date: _selectedDate);
    if (value == null) {
      await ref
          .read(materialRepositoryProvider)
          .clearLog(studentId: studentId, date: _selectedDate);
      return;
    }

    await ref
        .read(materialRepositoryProvider)
        .saveLog(studentId: studentId, date: _selectedDate, hadMaterial: value);
  }

  Future<void> _setHomeworkValue({
    required int studentId,
    required bool? value,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .clearAbsence(studentId: studentId, date: _selectedDate);
    if (value == null) {
      await ref
          .read(homeworkRepositoryProvider)
          .clearLog(studentId: studentId, date: _selectedDate);
      return;
    }

    await ref
        .read(homeworkRepositoryProvider)
        .saveLog(studentId: studentId, date: _selectedDate, hadHomework: value);
  }

  Future<void> _setAbsent({required int studentId, required bool absent}) {
    if (absent) {
      return ref
          .read(attendanceRepositoryProvider)
          .markAbsent(studentId: studentId, date: _selectedDate);
    }

    return ref
        .read(attendanceRepositoryProvider)
        .clearAbsence(studentId: studentId, date: _selectedDate);
  }

  Future<void> _toggleExcused({required int studentId, required bool excused}) {
    return ref
        .read(attendanceRepositoryProvider)
        .setExcused(
          studentId: studentId,
          date: _selectedDate,
          excused: excused,
        );
  }

  Future<void> _clearAbsencesForDate(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'clear_absences_for_date'.tr(),
      body: 'clear_absences_for_date_body'.tr(),
    );
    if (!confirmed) return;

    await ref
        .read(attendanceRepositoryProvider)
        .clearGroupAbsencesForDate(
          groupId: widget.groupId,
          date: _selectedDate,
        );
  }

  Future<void> _saveGrade({
    required int studentId,
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
  }

  Future<void> _clearGrade({
    required int studentId,
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
  }

  Future<void> _pickGrade({
    required int studentId,
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

    if (result.value == null || result.value == _noGradeSelectionValue) {
      await _clearGrade(studentId: studentId, category: category);
      return;
    }

    await _saveGrade(
      studentId: studentId,
      category: category,
      value: result.value!,
    );
  }
}

class _QuickNoteDialog extends StatelessWidget {
  const _QuickNoteDialog({required this.studentName, required this.controller});

  final String studentName;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(studentName),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'add_note'.tr(),
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: Text('save'.tr()),
        ),
      ],
    );
  }

  void _submit(BuildContext context) =>
      Navigator.of(context).pop(controller.text);
}

enum _LessonViewMode { list, seatingPlan }

class _LessonViewToggle extends StatelessWidget {
  const _LessonViewToggle({
    required this.viewMode,
    required this.onChanged,
  });

  final _LessonViewMode viewMode;
  final ValueChanged<_LessonViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_LessonViewMode>(
      segments: [
        ButtonSegment(
          value: _LessonViewMode.list,
          icon: const Icon(Icons.list_outlined),
          label: Text('list_view'.tr()),
        ),
        ButtonSegment(
          value: _LessonViewMode.seatingPlan,
          icon: const Icon(Icons.grid_view_outlined),
          label: Text('seating_plan'.tr()),
        ),
      ],
      selected: {viewMode},
      onSelectionChanged: (modes) => onChanged(modes.first),
      showSelectedIcon: false,
    );
  }
}
