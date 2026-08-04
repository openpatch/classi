import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../features/groups/group_detail_screen.dart';
import '../../features/students/student_detail_screen.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/widgets/app_bar_title.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/content_constraints.dart';
import '../../shared/widgets/student_avatar.dart';

/// A read-only overview of a student's performance for parent meetings.
class StudentSummaryScreen extends ConsumerWidget {
  const StudentSummaryScreen({required this.studentId, super.key});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    final studentValue = ref.watch(studentProvider(studentId));

    return studentValue.when(
      data: (student) {
        if (student == null) return const Scaffold(body: SizedBox.shrink());

        final groupValue = ref.watch(groupProvider(student.groupId));
        final gradesValue = ref.watch(studentGradesProvider(studentId));
        final attendanceValue = ref.watch(studentAttendanceProvider(studentId));
        final homeworkValue = ref.watch(studentHomeworkProvider(studentId));
        final materialValue = ref.watch(studentMaterialProvider(studentId));
        final notesValue = ref.watch(studentNotesProvider(studentId));

        // Apply the same date filter as the detail screen.
        final dateFilter = ref.watch(studentDateFilterProvider(studentId));

        final group = groupValue.value;
        final groupColor = group == null ? null : colorFromHex(group.colorHex);
        final groupForeground = groupColor == null
            ? null
            : onColorForBackground(groupColor);
        final gradeScaleEntries = parseGradeScaleEntries(
          group?.gradeScaleJson ?? '',
        );
        final categories = parseGradeCategories(group?.gradeCategoriesJson);

        final allGrades = gradesValue.value ?? const [];
        final allAttendance = attendanceValue.value ?? const [];
        final allHomework = homeworkValue.value ?? const [];
        final allMaterial = materialValue.value ?? const [];
        final allNotes = notesValue.value ?? const [];

        final grades = dateFilter.isAll
            ? allGrades
            : allGrades.where((g) => dateFilter.includes(g.date)).toList();
        final attendance = dateFilter.isAll
            ? allAttendance
            : allAttendance.where((a) => dateFilter.includes(a.date)).toList();
        final homework = dateFilter.isAll
            ? allHomework
            : allHomework.where((h) => dateFilter.includes(h.date)).toList();
        final material = dateFilter.isAll
            ? allMaterial
            : allMaterial.where((m) => dateFilter.includes(m.date)).toList();
        final notes = dateFilter.isAll
            ? allNotes
            : allNotes.where((n) => dateFilter.includes(n.createdAt)).toList();

        // Compute category averages first, then calculate weighted average.
        final categoryAverages = _computeCategoryAverages(
          grades,
          gradeScaleEntries,
        );
        final gradeInputs = categoryAverages.entries
            .map((e) => (value: e.value, categoryId: e.key))
            .toList();
        final studentAverage = calculateWeightedAverage(
          gradeInputs,
          categories,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: groupColor,
            foregroundColor: groupForeground,
            title: AppBarTitle(
              title: 'parent_summary'.tr(),
              subtitle: studentDisplayNameWithOrigin(
                firstName: student.firstName,
                lastName: student.lastName,
                originNote: student.originNote,
                sortField: sortField,
              ),
            ),
          ),
          body: ContentConstraints(
            child: ListView(
              padding: appScreenPadding,
              children: [
                _SummaryHeader(
                  student: student,
                  group: group,
                  dateFilter: dateFilter,
                ),
                const SizedBox(height: AppSpacing.large),
                _SummaryAttendanceCard(attendance: attendance),
                const SizedBox(height: AppSpacing.large),
                _SummaryGradesCard(
                  studentAverage: studentAverage,
                  categoryAverages: categoryAverages,
                  categories: categories,
                  gradeScaleEntries: gradeScaleEntries,
                  totalGrades: grades.length,
                ),
                const SizedBox(height: AppSpacing.large),
                _SummaryWorkHabitsCard(homework: homework, material: material),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.large),
                  _SummaryNotesCard(notes: notes),
                ],
                const SizedBox(height: AppSpacing.xxLarge),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final controller = TextEditingController();
              final body = await showDialog<String>(
                context: context,
                builder: (_) => _QuickNoteDialog(
                  studentName: studentDisplayName(
                    firstName: student.firstName,
                    lastName: student.lastName,
                  ),
                  controller: controller,
                ),
              );
              if (body == null || body.trim().isEmpty) return;
              await ref
                  .read(noteRepositoryProvider)
                  .saveNote(
                    body: body.trim(),
                    groupId: student.groupId,
                    studentIds: [studentId],
                    isTodo: false,
                  );
            },
            icon: const Icon(Icons.note_add_outlined),
            label: Text('add_note'.tr()),
          ),
        );
      },
      error: (e, s) => const AppErrorScaffold(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  /// Computes a simple mean per category from the given grade list.
  Map<String, double> _computeCategoryAverages(
    List<GradeEntry> grades,
    List<GradeScaleEntry> gradeScale,
  ) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final g in grades) {
      final v = gradeValueToNumber(g.value, gradeScale);
      if (v == null) continue;
      sums[g.categoryId] = (sums[g.categoryId] ?? 0) + v;
      counts[g.categoryId] = (counts[g.categoryId] ?? 0) + 1;
    }
    return {for (final e in sums.entries) e.key: e.value / counts[e.key]!};
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.student,
    required this.group,
    required this.dateFilter,
  });

  final Student student;
  final Group? group;
  final DateRangeFilter dateFilter;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat.yMMMMd(
      context.locale.toLanguageTag(),
    ).format(DateTime.now());
    return Row(
      children: [
        StudentAvatar(student: student, size: 56),
        const SizedBox(width: AppSpacing.large),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentDisplayName(
                  firstName: student.firstName,
                  lastName: student.lastName,
                ),
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (group != null)
                Text(
                  group!.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                today,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (!dateFilter.isAll) ...[
                const SizedBox(height: AppSpacing.xSmall),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFilter.label(context),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------------

class _SummaryAttendanceCard extends StatelessWidget {
  const _SummaryAttendanceCard({required this.attendance});

  final List<AttendanceLog> attendance;

  @override
  Widget build(BuildContext context) {
    final total = attendance.length;
    final presentCount = attendance.where((l) => !l.isAbsent).length;
    final absentLogs = attendance.where((l) => l.isAbsent).toList();
    final excusedCount = absentLogs.where((l) => l.isExcused).length;
    final unexcusedCount = absentLogs.length - excusedCount;
    final percent = total > 0 ? (presentCount / total * 100).round() : null;

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'attendance'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.medium),
            if (total == 0)
              Text(
                'empty_attendance'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              _BigStat(
                value: percent != null ? '$percent%' : '—',
                label: 'present'.tr(),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.check_circle_outline,
                      label: 'present'.tr(),
                      value: presentCount.toString(),
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.cancel_outlined,
                      label: 'absent'.tr(),
                      value: absentLogs.length.toString(),
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.verified_outlined,
                      label: 'excused'.tr(),
                      value: excusedCount.toString(),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.warning_amber_outlined,
                      label: 'unexcused'.tr(),
                      value: unexcusedCount.toString(),
                      color: Theme.of(context).colorScheme.errorContainer,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grades
// ---------------------------------------------------------------------------

class _SummaryGradesCard extends StatelessWidget {
  const _SummaryGradesCard({
    required this.studentAverage,
    required this.categoryAverages,
    required this.categories,
    required this.gradeScaleEntries,
    required this.totalGrades,
  });

  final double? studentAverage;
  final Map<String, double>? categoryAverages;
  final List<GradeCategory> categories;
  final List<GradeScaleEntry> gradeScaleEntries;
  final int totalGrades;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('grades'.tr(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.medium),
            if (studentAverage == null || totalGrades == 0)
              Text(
                'empty_grades'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              _BigStat(
                value: gradeLabelForNumericValue(
                  studentAverage!,
                  gradeScaleEntries,
                ),
                label: 'average'.tr(),
                color: Theme.of(context).colorScheme.primary,
              ),
              if (categoryAverages != null && categories.length > 1) ...[
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    for (final cat in categories)
                      if (categoryAverages![cat.id] != null)
                        _CategoryAverageTile(
                          label: gradeLabelForNumericValue(
                            categoryAverages![cat.id]!,
                            gradeScaleEntries,
                          ),
                          categoryName: cat.name,
                          color: colorForCategory(cat),
                        ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryAverageTile extends StatelessWidget {
  const _CategoryAverageTile({
    required this.label,
    required this.categoryName,
    required this.color,
  });

  final String label;
  final String categoryName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            categoryName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Work habits
// ---------------------------------------------------------------------------

class _SummaryWorkHabitsCard extends StatelessWidget {
  const _SummaryWorkHabitsCard({
    required this.homework,
    required this.material,
  });

  final List<HomeworkLog> homework;
  final List<MaterialLog> material;

  @override
  Widget build(BuildContext context) {
    final hwTotal = homework.length;
    final hwDone = homework.where((h) => h.hadHomework).length;
    final hwPercent = hwTotal > 0 ? (hwDone / hwTotal * 100).round() : null;

    final matTotal = material.length;
    final matDone = material.where((m) => m.hadMaterial).length;
    final matPercent = matTotal > 0 ? (matDone / matTotal * 100).round() : null;

    if (hwTotal == 0 && matTotal == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'work_habits'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                if (hwTotal > 0)
                  Expanded(
                    child: _PercentBar(
                      label: 'homework'.tr(),
                      percent: hwPercent ?? 0,
                      detail: '$hwDone / $hwTotal',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (hwTotal > 0 && matTotal > 0)
                  const SizedBox(width: AppSpacing.large),
                if (matTotal > 0)
                  Expanded(
                    child: _PercentBar(
                      label: 'material'.tr(),
                      percent: matPercent ?? 0,
                      detail: '$matDone / $matTotal',
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentBar extends StatelessWidget {
  const _PercentBar({
    required this.label,
    required this.percent,
    required this.detail,
    required this.color,
  });

  final String label;
  final int percent;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          detail,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

class _SummaryNotesCard extends StatelessWidget {
  const _SummaryNotesCard({required this.notes});

  final List<TeacherNote> notes;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd(context.locale.toLanguageTag());
    final recent = notes.take(5).toList();

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('notes'.tr(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.small),
            for (final note in recent) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xSmall,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.body,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      dateFormat.format(note.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.small),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick note dialog
// ---------------------------------------------------------------------------

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
