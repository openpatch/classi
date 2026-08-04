import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/utils/grade_categories.dart'
    show
        GradeCategory,
        colorForCategory,
        colorFromHex,
        defaultGradeCategories,
        onColorForBackground,
        parseGradeCategories;
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/content_constraints.dart';
import '../../shared/widgets/student_avatar.dart';
import '../grades/grade_picker_dialog.dart';
import '../notes/note_links.dart';
import 'group_detail_screen.dart'
    show groupNotesProvider, groupProvider, groupStudentsProvider;
import 'timeframe_editor_sheet.dart';

class TimeframeGradesScreen extends ConsumerWidget {
  const TimeframeGradesScreen({required this.timeframe, super.key});

  final Timeframe timeframe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = timeframe.groupId;
    final params = (
      groupId: groupId,
      startDate: timeframe.startDate,
      endDate: timeframe.endDate,
    );

    final studentsValue = ref.watch(groupStudentsProvider(groupId));
    final notesValue = ref.watch(groupNotesProvider(groupId));
    final groupValue = ref.watch(groupProvider(groupId));
    final categoryAveragesValue = ref.watch(
      timeframeCategoryAveragesProvider(params),
    );
    final timeframeGradesValue = ref.watch(
      timeframeGradesProvider(timeframe.id),
    );
    final attendanceValue = ref.watch(timeframeAttendanceProvider(params));
    final materialValue = ref.watch(timeframeMaterialProvider(params));
    final homeworkValue = ref.watch(timeframeHomeworkProvider(params));

    final group = groupValue.asData?.value;
    final appBar = group != null
        ? AppBar(
            backgroundColor: colorFromHex(group.colorHex),
            foregroundColor: onColorForBackground(colorFromHex(group.colorHex)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeframe.label),
                Text(
                  '${formatShortDate(timeframe.startDate)} – ${formatShortDate(timeframe.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'edit'.tr(),
                onPressed: () => _editTimeframe(context, ref, timeframe),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'delete'.tr(),
                onPressed: () => _deleteTimeframe(context, ref, timeframe),
              ),
            ],
          )
        : AppBar(title: Text(timeframe.label));

    return Scaffold(
      appBar: appBar,
      body: studentsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            AppErrorState(title: 'Error loading data', body: error.toString()),
        data: (students) {
          if (students.isEmpty) {
            return Center(child: Text('no_students_in_group'.tr()));
          }

          final group = groupValue.asData?.value;
          final gradeScaleEntries = group != null
              ? parseGradeScaleEntries(group.gradeScaleJson)
              : defaultGradeScaleEntries;
          final gradeScale = gradeScaleEntries.map((e) => e.label).toList();
          final categories = group != null
              ? parseGradeCategories(group.gradeCategoriesJson)
              : defaultGradeCategories;

          final notes = notesValue.asData?.value ?? [];
          final notesByStudent = <int, List<TeacherNote>>{};
          for (final note in notes) {
            for (final studentId in noteStudentIds(note)) {
              notesByStudent.putIfAbsent(studentId, () => []).add(note);
            }
          }

          final categoryAverages = categoryAveragesValue.asData?.value ?? {};
          final finalGrades = <int, String>{
            for (final g in timeframeGradesValue.asData?.value ?? [])
              g.studentId: g.grade,
          };
          final attendanceLogs = attendanceValue.asData?.value ?? {};
          final materialLogs = materialValue.asData?.value ?? {};
          final homeworkLogs = homeworkValue.asData?.value ?? {};

          return _TimeframeTable(
            students: students,
            timeframe: timeframe,
            categories: categories,
            gradeScaleEntries: gradeScaleEntries,
            gradeScale: gradeScale,
            notesByStudent: notesByStudent,
            categoryAverages: categoryAverages,
            finalGrades: finalGrades,
            attendanceLogs: attendanceLogs,
            materialLogs: materialLogs,
            homeworkLogs: homeworkLogs,
          );
        },
      ),
    );
  }

  Future<void> _editTimeframe(
    BuildContext context,
    WidgetRef ref,
    Timeframe timeframe,
  ) async {
    final result = await showTimeframeEditorSheet(
      context: context,
      groupId: timeframe.groupId,
      timeframeRepository: ref.read(timeframeRepositoryProvider),
      initialLabel: timeframe.label,
      initialStartDate: timeframe.startDate,
      initialEndDate: timeframe.endDate,
      timeframeId: timeframe.id,
    );
    if (result != null) {
      await ref
          .read(timeframeRepositoryProvider)
          .updateTimeframe(
            id: timeframe.id,
            label: result.label,
            startDate: result.startDate,
            endDate: result.endDate,
          );
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _deleteTimeframe(
    BuildContext context,
    WidgetRef ref,
    Timeframe timeframe,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'delete_timeframe'.tr(),
      body: 'delete_timeframe_confirmation'.tr(),
    );
    if (confirmed) {
      await ref
          .read(timeframeGradeRepositoryProvider)
          .deleteGradesForTimeframe(timeframe.id);
      await ref.read(timeframeRepositoryProvider).deleteTimeframe(timeframe.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _TimeframeTable extends ConsumerWidget {
  const _TimeframeTable({
    required this.students,
    required this.timeframe,
    required this.categories,
    required this.gradeScaleEntries,
    required this.gradeScale,
    required this.notesByStudent,
    required this.categoryAverages,
    required this.finalGrades,
    required this.attendanceLogs,
    required this.materialLogs,
    required this.homeworkLogs,
  });

  final List<Student> students;
  final Timeframe timeframe;
  final List<GradeCategory> categories;
  final List<GradeScaleEntry> gradeScaleEntries;
  final List<String> gradeScale;
  final Map<int, List<TeacherNote>> notesByStudent;
  final Map<int, Map<String, double>> categoryAverages;
  final Map<int, String> finalGrades;
  final Map<int, List<AttendanceLog>> attendanceLogs;
  final Map<int, List<MaterialLog>> materialLogs;
  final Map<int, List<HomeworkLog>> homeworkLogs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: appScreenPadding,
      child: ContentConstraints(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: appCardPadding,
            child: Column(
              children: [
                _TableHeader(),
                for (var i = 0; i < students.length; i++) ...[
                  _TimeframeStudentRow(
                    student: students[i],
                    timeframe: timeframe,
                    categories: categories,
                    gradeScaleEntries: gradeScaleEntries,
                    gradeScale: gradeScale,
                    notes: notesByStudent[students[i].id] ?? [],
                    perCategoryAverages: categoryAverages[students[i].id] ?? {},
                    finalGrade: finalGrades[students[i].id],
                    attendanceLogs: attendanceLogs[students[i].id] ?? [],
                    materialLogs: materialLogs[students[i].id] ?? [],
                    homeworkLogs: homeworkLogs[students[i].id] ?? [],
                  ),
                  if (i < students.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      child: Row(
        children: [
          _HeaderCell(label: 'name', flex: 5),
          _HeaderCell(label: 'final_grade', flex: 2),
          _HeaderCell(label: 'attendance', flex: 2),
          _HeaderCell(label: 'material', flex: 2),
          _HeaderCell(label: 'homework', flex: 2),
          _HeaderCell(label: 'notes', flex: 2),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TimeframeStudentRow extends ConsumerWidget {
  const _TimeframeStudentRow({
    required this.student,
    required this.timeframe,
    required this.categories,
    required this.gradeScaleEntries,
    required this.gradeScale,
    required this.notes,
    required this.perCategoryAverages,
    required this.finalGrade,
    required this.attendanceLogs,
    required this.materialLogs,
    required this.homeworkLogs,
  });

  final Student student;
  final Timeframe timeframe;
  final List<GradeCategory> categories;
  final List<GradeScaleEntry> gradeScaleEntries;
  final List<String> gradeScale;
  final List<TeacherNote> notes;
  final Map<String, double> perCategoryAverages;
  final String? finalGrade;
  final List<AttendanceLog> attendanceLogs;
  final List<MaterialLog> materialLogs;
  final List<HomeworkLog> homeworkLogs;

  String _formatPercent(int count, int total) {
    if (total == 0) return '–';
    return '${(count / total * 100).round()}%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);

    final presentCount = attendanceLogs.where((l) => !l.isAbsent).length;
    final attendancePercent = _formatPercent(
      presentCount,
      attendanceLogs.length,
    );

    final hadMaterialCount = materialLogs.where((l) => l.hadMaterial).length;
    final materialPercent = _formatPercent(
      hadMaterialCount,
      materialLogs.length,
    );

    final hadHomeworkCount = homeworkLogs.where((l) => l.hadHomework).length;
    final homeworkPercent = _formatPercent(
      hadHomeworkCount,
      homeworkLogs.length,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.push('/students/${student.id}'),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xSmall / 2),
                    child: StudentAvatar(student: student, size: 40),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentDisplayName(
                          firstName: student.firstName,
                          lastName: student.lastName,
                          callName: student.callName,
                          sortField: sortField,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (perCategoryAverages.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xSmall),
                        Wrap(
                          spacing: AppSpacing.xSmall,
                          runSpacing: AppSpacing.xSmall,
                          children: [
                            for (final category in categories)
                              if (perCategoryAverages[category.id]
                                  case final v?)
                                _CategoryChip(
                                  label:
                                      '${category.name}: ${gradeLabelForNumericValue(v, gradeScaleEntries)}',
                                  color: colorForCategory(category),
                                ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xSmall,
              ),
              child: OutlinedButton(
                onPressed: () => _pickFinalGrade(context, ref),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                  ),
                  backgroundColor: finalGrade == null
                      ? Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: 0.35)
                      : null,
                ),
                child: Text(
                  finalGrade ?? 'no_grade'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(flex: 2, child: _StatCell(value: attendancePercent)),
          Expanded(flex: 2, child: _StatCell(value: materialPercent)),
          Expanded(flex: 2, child: _StatCell(value: homeworkPercent)),
          Expanded(
            flex: 2,
            child: Center(
              child: Badge(
                isLabelVisible: notes.isNotEmpty,
                label: Text('${notes.length}'),
                child: IconButton(
                  icon: const Icon(Icons.sticky_note_2_outlined),
                  tooltip: 'notes'.tr(),
                  onPressed: notes.isEmpty
                      ? null
                      : () async {
                          if (context.mounted) {
                            await _showNotes(context);
                          }
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFinalGrade(BuildContext context, WidgetRef ref) async {
    final result = await showGradePickerDialog(
      context: context,
      gradeScale: gradeScale,
      initialValue: finalGrade,
    );
    if (result == null || !result.confirmed) return;

    final repo = ref.read(timeframeGradeRepositoryProvider);
    if (result.value == null) {
      final existing = await repo.getGrade(timeframe.id, student.id);
      if (existing != null) await repo.deleteGrade(existing.id);
    } else {
      await repo.saveGrade(
        timeframeId: timeframe.id,
        studentId: student.id,
        grade: result.value!,
      );
    }
  }

  Future<void> _showNotes(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          studentDisplayName(
            firstName: student.firstName,
            lastName: student.lastName,
            callName: student.callName,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: notes
                  .map(
                    (note) => ListTile(
                      title: Text(
                        note.body.length > 80
                            ? '${note.body.substring(0, 80)}…'
                            : note.body,
                      ),
                      trailing: Text(formatShortDate(note.createdAt)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: 2,
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}
