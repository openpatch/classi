import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/student_avatar.dart';
import '../lessons/lesson_widgets.dart';
import '../seating_plan/seating_plan_grid.dart';
import '../seating_plan/seating_plan_selector_sheet.dart';

/// A seating plan view for use inside the lesson mode screen.
///
/// Renders the [SeatingPlanCanvas] with live attendance/grade overlays and
/// calls the same callbacks as [LessonStudentsTable] when a chip is tapped.
class LessonSeatingView extends ConsumerStatefulWidget {
  const LessonSeatingView({
    required this.groupId,
    required this.students,
    required this.absentStudents,
    required this.excusedStudents,
    required this.materialSelections,
    required this.homeworkSelections,
    required this.gradeSelections,
    required this.noteCountsByStudent,
    required this.onSetAbsent,
    required this.onSetPresent,
    required this.onToggleExcused,
    required this.onMaterialChanged,
    required this.onHomeworkChanged,
    required this.onPickGrade,
    required this.onOpenNotes,
    required this.onAddQuickNote,
    required this.onOpenStudent,
    super.key,
  });

  final int groupId;
  final List<Student> students;
  final Set<int> absentStudents;
  final Set<int> excusedStudents;
  final Map<int, bool> materialSelections;
  final Map<int, bool> homeworkSelections;
  final Map<int, String> gradeSelections;
  final Map<int, int> noteCountsByStudent;
  final ValueChanged<Student> onSetAbsent;
  final ValueChanged<Student> onSetPresent;
  final void Function(Student student, bool excused) onToggleExcused;
  final void Function(Student student, bool? value) onMaterialChanged;
  final void Function(Student student, bool? value) onHomeworkChanged;
  final ValueChanged<Student> onPickGrade;
  final ValueChanged<Student> onOpenNotes;
  final ValueChanged<Student> onAddQuickNote;
  final ValueChanged<Student> onOpenStudent;

  @override
  ConsumerState<LessonSeatingView> createState() => _LessonSeatingViewState();
}

class _LessonSeatingViewState extends ConsumerState<LessonSeatingView> {
  SeatingPlan? _activePlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureActivePlan());
  }

  Future<void> _ensureActivePlan() async {
    final repo = ref.read(seatingPlanRepositoryProvider);
    var plan = await repo.getDefaultOrFirstPlan(widget.groupId);
    if (plan == null) {
      final id = await repo.createPlan(
        groupId: widget.groupId,
        name: 'default_seating_plan_name'.tr(),
        columns: 6,
      );
      final plans = await repo.watchPlansForGroup(widget.groupId).first;
      plan = plans.where((p) => p.id == id).firstOrNull;
    }
    if (plan == null || !mounted) return;
    if (_activePlan?.id != plan.id) {
      setState(() => _activePlan = plan);
    }
    await repo.initializePositionsForPlan(
      planId: plan.id,
      students: widget.students,
      columns: plan.columns,
    );
  }

  Future<void> _openPlanSelector() async {
    final selected = await showSeatingPlanSelectorSheet(
      context: context,
      groupId: widget.groupId,
      activePlan: _activePlan,
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() => _activePlan = selected);
      await ref
          .read(seatingPlanRepositoryProvider)
          .initializePositionsForPlan(
            planId: selected.id,
            students: widget.students,
            columns: selected.columns,
          );
    } else {
      // The active plan may have been deleted — reload the next available plan.
      await _ensureActivePlan();
    }
  }

  void _onChipTap(Student student) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _StudentActionSheet(
        student: student,
        absent: widget.absentStudents.contains(student.id),
        excused: widget.excusedStudents.contains(student.id),
        materialValue: widget.materialSelections[student.id],
        homeworkValue: widget.homeworkSelections[student.id],
        grade: widget.gradeSelections[student.id],
        noteCount: widget.noteCountsByStudent[student.id] ?? 0,
        onSetAbsent: () {
          Navigator.of(ctx).pop();
          widget.onSetAbsent(student);
        },
        onSetPresent: () {
          Navigator.of(ctx).pop();
          widget.onSetPresent(student);
        },
        onToggleExcused: (excused) => widget.onToggleExcused(student, excused),
        onMaterialChanged: (value) => widget.onMaterialChanged(student, value),
        onHomeworkChanged: (value) => widget.onHomeworkChanged(student, value),
        onPickGrade: () {
          Navigator.of(ctx).pop();
          widget.onPickGrade(student);
        },
        onOpenNotes: () {
          Navigator.of(ctx).pop();
          widget.onOpenNotes(student);
        },
        onAddQuickNote: () {
          Navigator.of(ctx).pop();
          widget.onAddQuickNote(student);
        },
        onOpenStudent: () {
          Navigator.of(ctx).pop();
          widget.onOpenStudent(student);
        },
      ),
    );
  }

  Widget? _buildOverlay(Student student) {
    final absent = widget.absentStudents.contains(student.id);
    final noteCount = widget.noteCountsByStudent[student.id] ?? 0;
    final materialValue = widget.materialSelections[student.id];
    final homeworkValue = widget.homeworkSelections[student.id];
    final grade = widget.gradeSelections[student.id];
    final hasIndicators =
        noteCount > 0 || materialValue != null || homeworkValue != null;

    if (!absent && grade == null && !hasIndicators) return null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (absent)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (grade != null)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                grade,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (noteCount > 0)
          Positioned(
            left: -4,
            top: -4,
            child: _LessonOverlayIconBadge(
              icon: Icons.sticky_note_2_outlined,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer,
            ),
          ),
        if (materialValue != null)
          Positioned(
            left: -4,
            bottom: -4,
            child: _LessonOverlayIconBadge(
              icon: Icons.backpack_outlined,
              backgroundColor: _statusColor(materialValue),
              foregroundColor: Colors.white,
            ),
          ),
        if (homeworkValue != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: _LessonOverlayIconBadge(
              icon: Icons.fact_check_outlined,
              backgroundColor: _statusColor(homeworkValue),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _statusColor(bool value) {
    final colorScheme = Theme.of(context).colorScheme;
    return value ? colorScheme.primary : colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final plan = _activePlan;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              AppSpacing.medium,
              AppSpacing.small,
              AppSpacing.medium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    plan?.name ?? 'seating_plan'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openPlanSelector,
                  icon: const Icon(Icons.tune_outlined, size: 18),
                  label: Text('seating_plans'.tr()),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          if (plan == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                0,
                AppSpacing.large,
                AppSpacing.large,
              ),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _openPlanSelector,
                  icon: const Icon(Icons.add),
                  label: Text('add_seating_plan'.tr()),
                ),
              ),
            )
          else
            _SeatingCanvas(
              plan: plan,
              students: widget.students,
              onChipTap: _onChipTap,
              overlayBuilder: _buildOverlay,
              opacityBuilder: (student) =>
                  widget.absentStudents.contains(student.id) ? 0.5 : 1,
            ),
          if (plan != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                0,
                AppSpacing.large,
                AppSpacing.medium,
              ),
              child: Text(
                'tap_student_for_actions'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonOverlayIconBadge extends StatelessWidget {
  const _LessonOverlayIconBadge({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 10, color: foregroundColor),
      ),
    );
  }
}

class _SeatingCanvas extends ConsumerWidget {
  const _SeatingCanvas({
    required this.plan,
    required this.students,
    required this.onChipTap,
    required this.overlayBuilder,
    required this.opacityBuilder,
  });

  final SeatingPlan plan;
  final List<Student> students;
  final void Function(Student student) onChipTap;
  final Widget? Function(Student student) overlayBuilder;
  final double Function(Student student) opacityBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionsValue = ref.watch(seatingPlanPositionsProvider(plan.id));
    final positions =
        positionsValue.value ?? const <int, ({int col, int row})>{};

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      child: SeatingPlanGrid(
        students: students,
        columns: plan.columns,
        positions: positions,
        onChipTap: onChipTap,
        lessonOverlayBuilder: overlayBuilder,
        lessonOpacityBuilder: opacityBuilder,
        onPositionChanged: (_, _, _) {},
      ),
    );
  }
}

/// A bottom sheet with all per-student lesson actions.
class _StudentActionSheet extends ConsumerStatefulWidget {
  const _StudentActionSheet({
    required this.student,
    required this.absent,
    required this.excused,
    required this.materialValue,
    required this.homeworkValue,
    required this.grade,
    required this.noteCount,
    required this.onSetAbsent,
    required this.onSetPresent,
    required this.onToggleExcused,
    required this.onMaterialChanged,
    required this.onHomeworkChanged,
    required this.onPickGrade,
    required this.onOpenNotes,
    required this.onAddQuickNote,
    required this.onOpenStudent,
  });

  final Student student;
  final bool absent;
  final bool excused;
  final bool? materialValue;
  final bool? homeworkValue;
  final String? grade;
  final int noteCount;
  final VoidCallback onSetAbsent;
  final VoidCallback onSetPresent;
  final ValueChanged<bool> onToggleExcused;
  final ValueChanged<bool?> onMaterialChanged;
  final ValueChanged<bool?> onHomeworkChanged;
  final VoidCallback onPickGrade;
  final VoidCallback onOpenNotes;
  final VoidCallback onAddQuickNote;
  final VoidCallback onOpenStudent;

  @override
  ConsumerState<_StudentActionSheet> createState() =>
      _StudentActionSheetState();
}

class _StudentActionSheetState extends ConsumerState<_StudentActionSheet> {
  late bool _excused;
  late bool? _materialValue;
  late bool? _homeworkValue;

  @override
  void initState() {
    super.initState();
    _excused = widget.excused;
    _materialValue = widget.materialValue;
    _homeworkValue = widget.homeworkValue;
  }

  @override
  void didUpdateWidget(covariant _StudentActionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.excused != widget.excused) {
      _excused = widget.excused;
    }
    if (oldWidget.materialValue != widget.materialValue) {
      _materialValue = widget.materialValue;
    }
    if (oldWidget.homeworkValue != widget.homeworkValue) {
      _homeworkValue = widget.homeworkValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
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
          Row(
            children: [
              StudentAvatar(student: widget.student, size: 40),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  studentDisplayName(
                    firstName: widget.student.firstName,
                    lastName: widget.student.lastName,
                    sortField: sortField,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_outlined),
                tooltip: 'open_student'.tr(),
                onPressed: widget.onOpenStudent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.medium),
          // Attendance row
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: widget.absent
                      ? widget.onSetPresent
                      : widget.onSetAbsent,
                  icon: Icon(
                    widget.absent
                        ? Icons.check_circle_outline
                        : Icons.person_off_outlined,
                  ),
                  label: Text(widget.absent ? 'present'.tr() : 'absent'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.absent
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    foregroundColor: widget.absent
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (widget.absent) ...[
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: FilterChip(
                    label: Text('excused'.tr()),
                    selected: _excused,
                    onSelected: (value) {
                      setState(() => _excused = value);
                      widget.onToggleExcused(value);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          // Grade + notes row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onPickGrade,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: Text(widget.grade ?? 'grade'.tr()),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onOpenNotes,
                  icon: const Icon(Icons.sticky_note_2_outlined),
                  label: Text(
                    widget.noteCount > 0
                        ? '${'notes'.tr()} (${widget.noteCount})'
                        : 'add_note'.tr(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LessonTriStateField(
                  label: 'material'.tr(),
                  value: _materialValue,
                  enabled: !widget.absent,
                  onChanged: (value) {
                    setState(() => _materialValue = value);
                    widget.onMaterialChanged(value);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: LessonTriStateField(
                  label: 'homework'.tr(),
                  value: _homeworkValue,
                  enabled: !widget.absent,
                  onChanged: (value) {
                    setState(() => _homeworkValue = value);
                    widget.onHomeworkChanged(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
