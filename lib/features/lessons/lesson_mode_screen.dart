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
import '../../shared/widgets/quick_note_dialog.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../shared/theme/app_ui.dart';
import '../attendance/attendance_state.dart';
import '../grades/grade_distribution.dart';
import '../grades/grade_picker_dialog.dart';
import '../grades/grade_round_screen.dart';
import '../notes/note_editor.dart';
import '../notes/note_links.dart';
import '../seating_plan/lesson_seating_view.dart';
import '../webuntis/webuntis_lesson_day.dart';
import '../webuntis/webuntis_link.dart';
import 'group_builder/student_group_builder_sheet.dart';
import 'lesson_periods.dart';
import 'lesson_sections.dart';
import 'lesson_support.dart';
import 'lesson_widgets.dart';
import 'student_picker/student_picker_sheet.dart';

class LessonModeScreen extends ConsumerStatefulWidget {
  const LessonModeScreen({
    required this.groupId,
    required this.initialDate,
    this.initialSessionLabel,
    this.initialCategoryId,
    this.initialPeriods,
    super.key,
  });

  final int groupId;
  final DateTime initialDate;
  final String? initialSessionLabel;
  final String? initialCategoryId;

  /// The lesson to open, when the caller knows it. Otherwise lesson mode
  /// works it out from the group's timetable and the clock.
  final LessonPeriods? initialPeriods;

  @override
  ConsumerState<LessonModeScreen> createState() => _LessonModeScreenState();
}

class _LessonModeScreenState extends ConsumerState<LessonModeScreen> {
  static const String _noGradeSelectionValue = '__classi_no_grade__';

  late final TextEditingController _sessionController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;

  /// The lesson being held, `null` for a whole-day entry.
  LessonPeriods? _periods;

  int get _periodStart => _periods?.start ?? 0;
  _LessonViewMode _viewMode = _LessonViewMode.list;

  @override
  void initState() {
    super.initState();
    _selectedDate = normalizeLessonDate(widget.initialDate);
    _selectedCategoryId = widget.initialCategoryId;
    _periods = widget.initialPeriods;
    _sessionController = TextEditingController(
      text: widget.initialSessionLabel,
    );
    Future<void>.microtask(() async {
      if (_periods == null) {
        await _resolveCurrentLesson();
      }
      await _restoreSessionLabelForCurrentSelection();
    });
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
      lessonMaterialSelectionsProvider((
        widget.groupId,
        _selectedDate,
        _periodStart,
      )),
    );
    final homeworkSelectionsValue = ref.watch(
      lessonHomeworkSelectionsProvider((
        widget.groupId,
        _selectedDate,
        _periodStart,
      )),
    );
    final absenceSelectionsValue = ref.watch(
      lessonAbsenceSelectionsProvider((
        widget.groupId,
        _selectedDate,
        _periodStart,
      )),
    );
    final excusedSelectionsValue = ref.watch(
      lessonExcusedSelectionsProvider((
        widget.groupId,
        _selectedDate,
        _periodStart,
      )),
    );
    final lateSelectionsValue = ref.watch(
      lessonLateSelectionsProvider((
        widget.groupId,
        _selectedDate,
        _periodStart,
      )),
    );
    final activitySelectionsValue = ref.watch(
      lessonActivitySelectionsProvider((
        widget.groupId,
        _selectedDate,
        _periodStart,
      )),
    );
    final examSelectionsValue = ref.watch(
      lessonExamSelectionsProvider((
        widget.groupId,
        _selectedDate,
        _periodStart,
      )),
    );
    final notesValue = ref.watch(lessonNotesProvider(widget.groupId));

    return groupValue.when(
      data: (group) {
        if (group == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final groupColor = colorFromHex(group.colorHex);
        final appBarForeground = onColorForBackground(groupColor);
        final gradeCategories = gradableCategories(
          parseGradeCategories(group.gradeCategoriesJson),
          keep: _selectedCategoryId,
        );
        _selectedCategoryId ??= gradeCategories.first.id;
        final selectedCategory = _resolveSelectedCategory(gradeCategories);

        final gradeScaleEntries = parseGradeScaleEntries(group.gradeScaleJson);
        final gradeScale = [for (final entry in gradeScaleEntries) entry.label];
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
            title: AppBarTitle(
              title: 'lesson_mode'.tr(),
              subtitle: sessionLabel.isEmpty
                  ? group.name
                  : '${group.name} · $sessionLabel',
            ),
            actions: [
              IconButton(
                onPressed: studentsValue.hasValue
                    ? () => _openGroupBuilder(context)
                    : null,
                icon: const Icon(Icons.groups_outlined),
                tooltip: 'group_builder'.tr(),
              ),
              IconButton(
                onPressed: studentsValue.hasValue
                    ? () => _openStudentPicker(context)
                    : null,
                icon: const Icon(Icons.casino_outlined),
                tooltip: 'random_student'.tr(),
              ),
              IconButton(
                onPressed: () async {
                  final sessions = ref.read(sessionRepositoryProvider);
                  final periods = _periods;
                  if (periods == null) {
                    await sessions.upsertSessionForDate(
                      groupId: widget.groupId,
                      date: _selectedDate,
                      categoryId: selectedCategory.id,
                      categoryName: selectedCategory.name,
                      label: _sessionController.text.trim(),
                    );
                  } else {
                    await sessions.upsertSession(
                      groupId: widget.groupId,
                      date: _selectedDate,
                      categoryId: selectedCategory.id,
                      categoryName: selectedCategory.name,
                      label: _sessionController.text.trim(),
                      periodStart: periods.start,
                      periodEnd: periods.end,
                    );
                  }
                  await ref
                      .read(attendanceRepositoryProvider)
                      .savePresenceForDate(
                        groupId: widget.groupId,
                        date: _selectedDate,
                        periodStart: _periodStart,
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
              final lateStudents = lateSelectionsValue.value ?? const <int>{};
              final activityStudents =
                  activitySelectionsValue.value ?? const <int>{};
              final examStudents = examSelectionsValue.value ?? const <int>{};
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

              // Add extra bottom padding when the FAB is visible so the last
              // list item is not obscured by it.
              // 56dp is the standard Material extended FAB height.
              const kExtendedFabHeight = 56.0;
              final hasFab = gradeCategories.length > 1;
              final listPadding = hasFab
                  ? appScreenPadding.copyWith(
                      bottom:
                          appScreenPadding.bottom +
                          kFloatingActionButtonMargin +
                          kExtendedFabHeight,
                    )
                  : appScreenPadding;

              return ContentConstraints(
                child: ListView(
                  padding: listPadding,
                  children: [
                    LessonContextCard(
                      sessionController: _sessionController,
                      selectedDate: _selectedDate,
                      onSessionChanged: (_) => setState(() {}),
                      onPickDate: _pickDate,
                      lessonSelector: LessonPicker(
                        lessons:
                            ref
                                .watch(
                                  lessonsOnDateProvider((
                                    widget.groupId,
                                    _selectedDate,
                                  )),
                                )
                                .value ??
                            const [],
                        selected: _periods,
                        weekday: _selectedDate.weekday,
                        bellTimes:
                            ref.watch(bellTimesProvider).value ?? const {},
                        onSelected: _selectLesson,
                      ),
                      topicSource: switch (WebUntisGroupLink.ofGroup(group)) {
                        final link? => WebUntisLessonPanel(
                          link: link,
                          date: _selectedDate,
                          periods: _periods,
                          localTopic: _sessionController.text,
                          onApplyTopic: (topic) =>
                              setState(() => _sessionController.text = topic),
                          students: students,
                          absentStudents: absentStudents,
                          excusedStudents: excusedStudents,
                          lateStudents: lateStudents,
                          activityStudents: activityStudents,
                          examStudents: examStudents,
                        ),
                        null => null,
                      },
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
                              activityStudents: activityStudents,
                              examStudents: examStudents,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    _LessonGradesCard(
                      category: selectedCategory,
                      gradeSelections: gradeSelections,
                      gradeScale: gradeScaleEntries,
                      onStartRound: () => _startGradeRound(
                        context: context,
                        students: students,
                        absentStudents: absentStudents,
                        gradeSelections: gradeSelections,
                        gradeScale: gradeScaleEntries,
                        category: selectedCategory,
                      ),
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
                      onChanged: (mode) => setState(() => _viewMode = mode),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    if (_viewMode == _LessonViewMode.list)
                      LessonStudentsTable(
                        students: students,
                        absentStudents: absentStudents,
                        excusedStudents: excusedStudents,
                        lateStudents: lateStudents,
                        activityStudents: activityStudents,
                        examStudents: examStudents,
                        materialSelections: materialSelections,
                        homeworkSelections: homeworkSelections,
                        gradeSelections: gradeSelections,
                        noteCountsByStudent: noteCountsByStudent,
                        onOpenStudent: (student) =>
                            context.push('/students/${student.id}'),
                        onSwipeAbsent: (student) => _setAttendance(
                          context: context,
                          group: group,
                          student: student,
                          from: _attendanceOf(
                            student,
                            absentStudents,
                            lateStudents,
                          ),
                          to: absentStudents.contains(student.id)
                              ? AttendanceState.present
                              : AttendanceState.absent,
                        ),
                        onSwipeLate: (student) => _setAttendance(
                          context: context,
                          group: group,
                          student: student,
                          from: _attendanceOf(
                            student,
                            absentStudents,
                            lateStudents,
                          ),
                          to: lateStudents.contains(student.id)
                              ? AttendanceState.present
                              : AttendanceState.late,
                        ),
                        onToggleExcused: (student, excused) => _toggleExcused(
                          studentId: student.id,
                          excused: excused,
                        ),
                        onToggleActivity: (student, activity) =>
                            _toggleActivity(
                              studentId: student.id,
                              activity: activity,
                            ),
                        onToggleExam: (student, exam) => _toggleActivity(
                          studentId: student.id,
                          activity: exam,
                          exam: true,
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
                        activityStudents: activityStudents,
                        examStudents: examStudents,
                        materialSelections: materialSelections,
                        homeworkSelections: homeworkSelections,
                        gradeSelections: gradeSelections,
                        noteCountsByStudent: noteCountsByStudent,
                        onSetAbsent: (student) => _setAttendance(
                          context: context,
                          group: group,
                          student: student,
                          from: _attendanceOf(
                            student,
                            absentStudents,
                            lateStudents,
                          ),
                          to: AttendanceState.absent,
                        ),
                        onSetPresent: (student) => _setAttendance(
                          context: context,
                          group: group,
                          student: student,
                          from: _attendanceOf(
                            student,
                            absentStudents,
                            lateStudents,
                          ),
                          to: AttendanceState.present,
                        ),
                        onToggleExcused: (student, excused) => _toggleExcused(
                          studentId: student.id,
                          excused: excused,
                        ),
                        onToggleActivity: (student, activity) =>
                            _toggleActivity(
                              studentId: student.id,
                              activity: activity,
                            ),
                        onToggleExam: (student, exam) => _toggleActivity(
                          studentId: student.id,
                          activity: exam,
                          exam: true,
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
            error: (error, stackTrace) =>
                AppErrorState(error: error, stackTrace: stackTrace),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stackTrace) =>
          AppErrorScaffold(error: error, stackTrace: stackTrace),
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
    setState(() {
      _selectedCategoryId = category.id;
    });
    await _restoreSessionLabelForCurrentSelection(
      categoryId: category.id,
      date: _selectedDate,
    );
  }

  /// Opens the group's lesson that is running now, or the day's first one
  /// on another day. Stays on a whole-day entry when the group has no lesson
  /// in its timetable that day.
  Future<void> _resolveCurrentLesson() async {
    final date = _selectedDate;
    // Straight from the repositories: reading an auto-disposing provider's
    // future before anything listens to it can leave the future pending.
    final slots = await ref
        .read(lessonSlotRepositoryProvider)
        .slots(widget.groupId);
    final sessions = await ref
        .read(sessionRepositoryProvider)
        .watchSessionsOnDate(groupId: widget.groupId, date: date)
        .first;
    final bellTimes = await ref
        .read(webUntisSettingsServiceProvider)
        .readBellTimes();
    final lessons = lessonsOnDate(date: date, slots: slots, sessions: sessions);
    if (!mounted || _selectedDate != date) return;
    final picked = pickCurrentLesson(
      lessons: lessons,
      date: date,
      now: DateTime.now(),
      bellTimes: bellTimes,
    );
    if (picked != _periods) {
      setState(() => _periods = picked);
    }
  }

  /// Switches to another lesson of the same day.
  Future<void> _selectLesson(LessonPeriods? periods) async {
    if (periods == _periods) return;
    setState(() {
      _periods = periods;
      _sessionController.clear();
    });
    await _restoreSessionLabelForCurrentSelection();
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

    // First try to restore from an existing session record.
    final periods = _periods;
    final session = periods == null
        ? await ref
              .read(sessionRepositoryProvider)
              .sessionForDate(
                groupId: widget.groupId,
                date: targetDate,
                categoryId: targetCategoryId,
              )
        : await ref
              .read(sessionRepositoryProvider)
              .getSession(
                groupId: widget.groupId,
                date: targetDate,
                categoryId: targetCategoryId,
                periodStart: periods.start,
              );
    if (!mounted ||
        _sessionController.text.trim().isNotEmpty ||
        _selectedCategoryId != targetCategoryId ||
        _selectedDate != targetDate) {
      return;
    }
    if (session != null && session.label.isNotEmpty) {
      _sessionController.text = session.label;
      setState(() {});
      return;
    }

    // Fall back to grade entries for backwards compatibility.
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
    required Set<int> activityStudents,
    required Set<int> examStudents,
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
                      callName: student.callName,
                      sortField: sortField,
                    ),
                  ),
                  trailing: examStudents.contains(student.id)
                      ? Chip(
                          label: Text('exam_elsewhere'.tr()),
                          visualDensity: VisualDensity.compact,
                        )
                      : activityStudents.contains(student.id)
                      ? Chip(
                          label: Text('activity'.tr()),
                          visualDensity: VisualDensity.compact,
                        )
                      : excusedStudents.contains(student.id)
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

    setState(() {
      _selectedDate = normalizeLessonDate(selected);
      _periods = null;
      _sessionController.clear();
    });
    await _resolveCurrentLesson();
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
      callName: student.callName,
      sortField: sortField,
    );
    final body = await showQuickNoteDialog(context: context, studentName: name);
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

  Future<void> _setMaterialValue({
    required int studentId,
    required bool? value,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .clearAbsenceOnly(
          studentId: studentId,
          date: _selectedDate,
          periodStart: _periodStart,
        );
    if (value == null) {
      await ref
          .read(materialRepositoryProvider)
          .clearLog(
            studentId: studentId,
            date: _selectedDate,
            periodStart: _periodStart,
          );
      return;
    }

    await ref
        .read(materialRepositoryProvider)
        .saveLog(
          studentId: studentId,
          date: _selectedDate,
          periodStart: _periodStart,
          hadMaterial: value,
        );
  }

  Future<void> _setHomeworkValue({
    required int studentId,
    required bool? value,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .clearAbsenceOnly(
          studentId: studentId,
          date: _selectedDate,
          periodStart: _periodStart,
        );
    if (value == null) {
      await ref
          .read(homeworkRepositoryProvider)
          .clearLog(
            studentId: studentId,
            date: _selectedDate,
            periodStart: _periodStart,
          );
      return;
    }

    await ref
        .read(homeworkRepositoryProvider)
        .saveLog(
          studentId: studentId,
          date: _selectedDate,
          periodStart: _periodStart,
          hadHomework: value,
        );
  }

  static AttendanceState _attendanceOf(
    Student student,
    Set<int> absentStudents,
    Set<int> lateStudents,
  ) {
    if (absentStudents.contains(student.id)) {
      return AttendanceState.absent;
    }
    if (lateStudents.contains(student.id)) {
      return AttendanceState.late;
    }
    return AttendanceState.present;
  }

  /// Records [to] for [student] in this lesson, with a snackbar to take it
  /// back. Classi never writes attendance to WebUntis.
  Future<void> _setAttendance({
    required BuildContext context,
    required Group group,
    required Student student,
    required AttendanceState from,
    required AttendanceState to,
    bool offerUndo = true,
  }) async {
    if (from == to) return;
    final date = _selectedDate;
    final periodStart = _periodStart;
    final attendance = ref.read(attendanceRepositoryProvider);
    switch (to) {
      case AttendanceState.present:
        await attendance.clearAbsence(
          studentId: student.id,
          date: date,
          periodStart: periodStart,
        );
      case AttendanceState.absent:
        await attendance.markAbsent(
          studentId: student.id,
          date: date,
          periodStart: periodStart,
        );
      case AttendanceState.late:
        await attendance.markLate(
          studentId: student.id,
          date: date,
          periodStart: periodStart,
        );
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (offerUndo) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              switch (to) {
                AttendanceState.present => 'marked_present',
                AttendanceState.absent => 'marked_absent',
                AttendanceState.late => 'marked_late',
              }.tr(namedArgs: {'name': student.callName ?? student.firstName}),
            ),
            action: SnackBarAction(
              label: 'undo'.tr(),
              onPressed: () => _setAttendance(
                context: context,
                group: group,
                student: student,
                from: to,
                to: from,
                offerUndo: false,
              ),
            ),
          ),
        );
    }
  }

  Future<void> _toggleExcused({required int studentId, required bool excused}) {
    return ref
        .read(attendanceRepositoryProvider)
        .setExcused(
          studentId: studentId,
          date: _selectedDate,
          periodStart: _periodStart,
          excused: excused,
        );
  }

  Future<void> _toggleActivity({
    required int studentId,
    required bool activity,
    bool exam = false,
  }) {
    return ref
        .read(attendanceRepositoryProvider)
        .setActivity(
          studentId: studentId,
          date: _selectedDate,
          periodStart: _periodStart,
          activity: activity,
          exam: exam,
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
          periodStart: _periodStart,
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

  Future<void> _startGradeRound({
    required BuildContext context,
    required List<Student> students,
    required Set<int> absentStudents,
    required Map<int, String> gradeSelections,
    required List<GradeScaleEntry> gradeScale,
    required GradeCategory category,
  }) {
    final sessionLabel = _sessionController.text.trim();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GradeRoundScreen(
          title: sessionLabel.isEmpty
              ? category.name
              : '$sessionLabel · ${category.name}',
          students: students,
          absentStudentIds: absentStudents,
          initialSelections: gradeSelections,
          gradeScale: gradeScale,
          color: colorForCategory(category),
          onSave: (studentId, value) => _saveGrade(
            studentId: studentId,
            category: category,
            value: value,
          ),
          onClear: (studentId) =>
              _clearGrade(studentId: studentId, category: category),
        ),
      ),
    );
  }

  void _openGroupBuilder(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StudentGroupBuilderSheet(
          groupId: widget.groupId,
          date: _selectedDate,
          periodStart: _periodStart,
        ),
      ),
    );
  }

  void _openStudentPicker(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StudentPickerSheet(
          groupId: widget.groupId,
          date: _selectedDate,
          periodStart: _periodStart,
        ),
      ),
    );
  }
}

enum _LessonViewMode { list, seatingPlan }

/// The grades of this lesson in the selected category: how they are spread,
/// and the way into grading everyone in one go.
class _LessonGradesCard extends StatelessWidget {
  const _LessonGradesCard({
    required this.category,
    required this.gradeSelections,
    required this.gradeScale,
    required this.onStartRound,
  });

  final GradeCategory category;
  final Map<int, String> gradeSelections;
  final List<GradeScaleEntry> gradeScale;
  final VoidCallback onStartRound;

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(category);
    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: color),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onStartRound,
                  icon: const Icon(Icons.bolt_outlined),
                  label: Text('grade_round'.tr()),
                ),
              ],
            ),
            if (gradeSelections.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.medium),
              GradeDistributionChart(
                distribution: computeGradeDistribution(
                  gradeSelections.values,
                  gradeScale,
                ),
                gradeScale: gradeScale,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonViewToggle extends StatelessWidget {
  const _LessonViewToggle({required this.viewMode, required this.onChanged});

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
