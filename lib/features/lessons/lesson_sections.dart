import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../shared/widgets/student_link_chip.dart';
import '../../shared/widgets/surface_list_tile.dart';
import '../notes/note_links.dart';
import 'lesson_support.dart';

class LessonSummaryCard extends StatelessWidget {
  const LessonSummaryCard({
    required this.absentCount,
    required this.gradeCount,
    required this.homeworkCount,
    required this.materialCount,
    required this.totalStudents,
    this.onAbsentTap,
    super.key,
  });

  final int absentCount;
  final int gradeCount;
  final int homeworkCount;
  final int materialCount;
  final int totalStudents;
  final VoidCallback? onAbsentTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            _SummaryChip(
              icon: Icons.person_off_outlined,
              label: '${'absent'.tr()}: $absentCount/$totalStudents',
              onTap: onAbsentTap,
            ),
            _SummaryChip(
              icon: Icons.edit_note_outlined,
              label: '${'grades'.tr()}: $gradeCount/$totalStudents',
            ),
            _SummaryChip(
              icon: Icons.fact_check_outlined,
              label: '${'homework'.tr()}: $homeworkCount/$totalStudents',
            ),
            _SummaryChip(
              icon: Icons.backpack_outlined,
              label: '${'material'.tr()}: $materialCount/$totalStudents',
            ),
          ],
        ),
      ),
    );
  }
}

class LessonNotesCard extends StatelessWidget {
  const LessonNotesCard({
    required this.notes,
    required this.students,
    required this.onAddGroupNote,
    required this.onEditNote,
    required this.onDeleteNote,
    super.key,
  });

  final List<TeacherNote> notes;
  final List<Student> students;
  final VoidCallback onAddGroupNote;
  final ValueChanged<TeacherNote> onEditNote;
  final ValueChanged<TeacherNote> onDeleteNote;

  @override
  Widget build(BuildContext context) {
    final studentsById = {for (final student in students) student.id: student};
    final displayedNotes = notes;

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'session_notes'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAddGroupNote,
                  icon: const Icon(Icons.add),
                  label: Text('add_group_note'.tr()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (displayedNotes.isEmpty)
              Text('no_session_notes'.tr())
            else
              for (final note in displayedNotes) ...[
                SurfaceListTile(
                  onTap: () => onEditNote(note),
                  title: Text(
                    note.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => onEditNote(note),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'edit'.tr(),
                      ),
                      IconButton(
                        onPressed: () => onDeleteNote(note),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'delete'.tr(),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.small),
                    child: Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [
                        if (_formatLessonNoteTime(context, note.createdAt)
                            case final timeLabel?)
                          Chip(label: Text(timeLabel)),
                        for (final studentId in noteStudentIds(note))
                          if (studentsById[studentId] != null)
                            StudentLinkChip(student: studentsById[studentId]!),
                        if (note.isTodo)
                          Chip(
                            label: Text(
                              note.todoDone ? 'done'.tr() : 'todo'.tr(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (note != displayedNotes.last)
                  const SizedBox(height: AppSpacing.small),
              ],
          ],
        ),
      ),
    );
  }
}

class LessonStudentsTable extends StatelessWidget {
  const LessonStudentsTable({
    required this.students,
    required this.absentStudents,
    required this.excusedStudents,
    required this.materialSelections,
    required this.homeworkSelections,
    required this.gradeSelections,
    required this.noteCountsByStudent,
    required this.onOpenStudent,
    required this.onSetAbsent,
    required this.onSetPresent,
    required this.onToggleExcused,
    required this.onMaterialChanged,
    required this.onHomeworkChanged,
    required this.onPickGrade,
    required this.onOpenNotes,
    required this.onAddQuickNote,
    super.key,
  });

  final List<Student> students;
  final Set<int> absentStudents;
  final Set<int> excusedStudents;
  final Map<int, bool> materialSelections;
  final Map<int, bool> homeworkSelections;
  final Map<int, String> gradeSelections;
  final Map<int, int> noteCountsByStudent;
  final ValueChanged<Student> onOpenStudent;
  final ValueChanged<Student> onSetAbsent;
  final ValueChanged<Student> onSetPresent;
  final void Function(Student student, bool excused) onToggleExcused;
  final void Function(Student student, bool? value) onMaterialChanged;
  final void Function(Student student, bool? value) onHomeworkChanged;
  final ValueChanged<Student> onPickGrade;
  final ValueChanged<Student> onOpenNotes;
  final ValueChanged<Student> onAddQuickNote;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.medium,
              ),
              child: Row(
                children: [
                  _LessonTableHeaderCell(label: 'name', flex: 5),
                  _LessonTableHeaderCell(label: 'grade', flex: 2),
                  _LessonTableHeaderCell(label: 'material', flex: 2),
                  _LessonTableHeaderCell(label: 'homework', flex: 2),
                  _LessonTableHeaderCell(label: 'notes', flex: 2),
                ],
              ),
            ),
          ),
          for (var index = 0; index < students.length; index++) ...[
            _LessonStudentRow(
              student: students[index],
              absent: absentStudents.contains(students[index].id),
              excused: excusedStudents.contains(students[index].id),
              materialValue: materialSelections[students[index].id],
              homeworkValue: homeworkSelections[students[index].id],
              gradeValue: gradeSelections[students[index].id],
              noteCount: noteCountsByStudent[students[index].id] ?? 0,
              onOpenStudent: () => onOpenStudent(students[index]),
              onSetAbsent: () => onSetAbsent(students[index]),
              onSetPresent: () => onSetPresent(students[index]),
              onToggleExcused: (excused) =>
                  onToggleExcused(students[index], excused),
              onMaterialChanged: (value) =>
                  onMaterialChanged(students[index], value),
              onHomeworkChanged: (value) =>
                  onHomeworkChanged(students[index], value),
              onPickGrade: () => onPickGrade(students[index]),
              onOpenNotes: () => onOpenNotes(students[index]),
              onAddQuickNote: () => onAddQuickNote(students[index]),
            ),
            if (index < students.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class LessonStudentNotesSheet extends ConsumerWidget {
  const LessonStudentNotesSheet({
    required this.groupId,
    required this.selectedDate,
    required this.student,
    required this.students,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
    super.key,
  });

  final int groupId;
  final DateTime selectedDate;
  final Student student;
  final List<Student> students;
  final Future<void> Function() onAddNote;
  final Future<void> Function(TeacherNote note) onEditNote;
  final Future<void> Function(TeacherNote note) onDeleteNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    final notesValue = ref.watch(lessonNotesProvider(groupId));
    final studentsById = {for (final item in students) item.id: item};

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xLarge,
          AppSpacing.small,
          AppSpacing.xLarge,
          AppSpacing.xxLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${studentDisplayName(firstName: student.firstName, lastName: student.lastName, callName: student.callName, sortField: sortField)} · ${'notes'.tr()}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAddNote,
                  icon: const Icon(Icons.add),
                  label: Text('add_note'.tr()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            Expanded(
              child: notesValue.when(
                data: (notes) {
                  final studentNotes = [
                    for (final note in notesForLessonDate(notes, selectedDate))
                      if (noteStudentIds(note).contains(student.id)) note,
                  ];

                  if (studentNotes.isEmpty) {
                    return EmptyState(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'empty_notes'.tr(),
                    );
                  }

                  return ListView.separated(
                    itemCount: studentNotes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.medium),
                    itemBuilder: (context, index) => _LessonStudentNoteCard(
                      note: studentNotes[index],
                      student: student,
                      studentsById: studentsById,
                      onEdit: () => onEditNote(studentNotes[index]),
                      onDelete: () => onDeleteNote(studentNotes[index]),
                    ),
                  );
                },
                error: (error, stackTrace) =>
                    AppErrorState(error: error, stackTrace: stackTrace),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xSmall),
              Icon(
                Icons.expand_more,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.large),
      child: chip,
    );
  }
}

class _LessonTableHeaderCell extends StatelessWidget {
  const _LessonTableHeaderCell({required this.label, required this.flex});

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _LessonStudentRow extends StatelessWidget {
  const _LessonStudentRow({
    required this.student,
    required this.absent,
    required this.excused,
    required this.materialValue,
    required this.homeworkValue,
    required this.gradeValue,
    required this.noteCount,
    required this.onOpenStudent,
    required this.onSetAbsent,
    required this.onSetPresent,
    required this.onToggleExcused,
    required this.onMaterialChanged,
    required this.onHomeworkChanged,
    required this.onPickGrade,
    required this.onOpenNotes,
    required this.onAddQuickNote,
  });

  final Student student;
  final bool absent;
  final bool excused;
  final bool? materialValue;
  final bool? homeworkValue;
  final String? gradeValue;
  final int noteCount;
  final VoidCallback onOpenStudent;
  final VoidCallback onSetAbsent;
  final VoidCallback onSetPresent;
  final ValueChanged<bool> onToggleExcused;
  final ValueChanged<bool?> onMaterialChanged;
  final ValueChanged<bool?> onHomeworkChanged;
  final VoidCallback onPickGrade;
  final VoidCallback onOpenNotes;
  final VoidCallback onAddQuickNote;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('lesson-student-${student.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        switch (direction) {
          case DismissDirection.startToEnd:
            onSetAbsent();
            return false;
          case DismissDirection.endToStart:
            onSetPresent();
            return false;
          case DismissDirection.none:
          case DismissDirection.down:
          case DismissDirection.up:
          case DismissDirection.horizontal:
          case DismissDirection.vertical:
            return false;
        }
      },
      background: _SwipeAttendanceBackground(
        alignment: Alignment.centerLeft,
        color: colorScheme.errorContainer,
        icon: Icons.person_off_outlined,
        label: 'absent'.tr(),
      ),
      secondaryBackground: _SwipeAttendanceBackground(
        alignment: Alignment.centerRight,
        color: colorScheme.primaryContainer,
        icon: Icons.check_circle_outline,
        label: 'present'.tr(),
      ),
      child: Container(
        color: absent
            ? colorScheme.errorContainer.withValues(alpha: 0.24)
            : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _LessonNameCell(
                student: student,
                absent: absent,
                excused: excused,
                noteCount: noteCount,
                onOpenStudent: onOpenStudent,
                onToggleExcused: absent ? onToggleExcused : null,
              ),
            ),
            Expanded(
              flex: 2,
              child: _LessonGradeCell(
                gradeValue: gradeValue,
                onPressed: onPickGrade,
              ),
            ),
            Expanded(
              flex: 2,
              child: _LessonTriStateCheckboxCell(
                value: materialValue,
                enabled: !absent,
                onChanged: onMaterialChanged,
              ),
            ),
            Expanded(
              flex: 2,
              child: _LessonTriStateCheckboxCell(
                value: homeworkValue,
                enabled: !absent,
                onChanged: onHomeworkChanged,
              ),
            ),
            Expanded(
              flex: 2,
              child: _LessonNoteCell(
                noteCount: noteCount,
                onPressed: onOpenNotes,
                onAdd: onAddQuickNote,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonNameCell extends ConsumerWidget {
  const _LessonNameCell({
    required this.student,
    required this.absent,
    required this.excused,
    required this.noteCount,
    required this.onOpenStudent,
    this.onToggleExcused,
  });

  final Student student;
  final bool absent;
  final bool excused;
  final int noteCount;
  final VoidCallback onOpenStudent;
  final ValueChanged<bool>? onToggleExcused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    return Row(
      children: [
        InkWell(
          onTap: onOpenStudent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xSmall / 2),
            child: StudentAvatar(student: student, size: 48),
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
              const SizedBox(height: AppSpacing.xSmall),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.xSmall,
                children: [
                  _LessonMetaBadge(
                    icon: absent
                        ? Icons.person_off_outlined
                        : Icons.check_circle_outline,
                    label: absent ? 'absent'.tr() : 'present'.tr(),
                  ),
                  if (absent && onToggleExcused != null)
                    FilterChip(
                      label: Text('excused'.tr()),
                      selected: excused,
                      onSelected: onToggleExcused,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (noteCount > 0)
                    _LessonMetaBadge(
                      icon: Icons.sticky_note_2_outlined,
                      label: '$noteCount',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonMetaBadge extends StatelessWidget {
  const _LessonMetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: AppSpacing.xSmall),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _LessonGradeCell extends StatelessWidget {
  const _LessonGradeCell({required this.gradeValue, required this.onPressed});

  final String? gradeValue;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasGrade = gradeValue != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xSmall),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
          backgroundColor: hasGrade
              ? null
              : Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.35),
        ),
        child: Text(
          gradeValue ?? 'no_grade'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LessonNoteCell extends StatelessWidget {
  const _LessonNoteCell({
    required this.noteCount,
    required this.onPressed,
    required this.onAdd,
  });

  final int noteCount;
  final VoidCallback onPressed;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onAdd,
          tooltip: 'add_note'.tr(),
          icon: const Icon(Icons.add_comment_outlined),
          iconSize: 20,
        ),
        Badge(
          isLabelVisible: noteCount > 0,
          label: Text('$noteCount'),
          child: IconButton(
            onPressed: onPressed,
            tooltip: 'notes'.tr(),
            icon: const Icon(Icons.sticky_note_2_outlined),
          ),
        ),
      ],
    );
  }
}

class _LessonStudentNoteCard extends StatelessWidget {
  const _LessonStudentNoteCard({
    required this.note,
    required this.student,
    required this.studentsById,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherNote note;
  final Student student;
  final Map<int, Student> studentsById;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final relatedStudents = [
      for (final linkedStudentId in noteStudentIds(note))
        if (linkedStudentId != student.id &&
            studentsById[linkedStudentId] != null)
          studentsById[linkedStudentId]!,
    ];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xLarge),
        onTap: onEdit,
        child: Padding(
          padding: appCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.body,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'edit'.tr(),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'delete'.tr(),
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
                      label: Text(note.todoDone ? 'done'.tr() : 'todo'.tr()),
                    ),
                  for (final linkedStudent in relatedStudents)
                    StudentLinkChip(student: linkedStudent),
                  if (_formatLessonNoteTime(context, note.createdAt)
                      case final timeLabel?)
                    Chip(label: Text(timeLabel)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTriStateCheckboxCell extends StatelessWidget {
  const _LessonTriStateCheckboxCell({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool? value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Checkbox(
        tristate: true,
        value: value,
        onChanged: enabled ? (_) => onChanged(_nextValue(value)) : null,
      ),
    );
  }

  bool? _nextValue(bool? currentValue) {
    if (currentValue == null) {
      return true;
    }
    if (currentValue) {
      return false;
    }
    return null;
  }
}

class _SwipeAttendanceBackground extends StatelessWidget {
  const _SwipeAttendanceBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final padding = alignment == Alignment.centerLeft
        ? const EdgeInsets.only(left: AppSpacing.xLarge)
        : const EdgeInsets.only(right: AppSpacing.xLarge);

    return Container(
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(label),
            const SizedBox(width: AppSpacing.small),
            Icon(icon),
          ] else ...[
            Icon(icon),
            const SizedBox(width: AppSpacing.small),
            Text(label),
          ],
        ],
      ),
    );
  }
}

String? _formatLessonNoteTime(BuildContext context, DateTime createdAt) {
  final timeOfDay = TimeOfDay.fromDateTime(createdAt);
  if (timeOfDay.hour == 0 && timeOfDay.minute == 0) {
    return null;
  }
  return MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay);
}
