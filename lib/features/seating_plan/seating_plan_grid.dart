import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/theme/app_ui.dart';
import 'seating_plan_chip.dart';

const double _cellSize = 96.0;

/// A fixed-grid seating plan layout.
///
/// Students occupy discrete cells in a [columns]-column grid. The grid
/// scrolls horizontally; all rows are always visible without scrolling
/// vertically.
///
/// **Edit mode** (`editMode: true`): Tap a chip to select it (highlighted
/// background). Then tap any cell to move the student there. Tapping another
/// occupied cell swaps the two students. Edit mode also exposes one extra row
/// and column on each side of the current layout.
///
/// **View mode**: Tapping a chip invokes [onChipTap].
class SeatingPlanGrid extends StatefulWidget {
  const SeatingPlanGrid({
    required this.students,
    required this.columns,
    required this.positions,
    required this.onPositionChanged,
    this.editMode = false,
    this.lessonOverlayBuilder,
    this.lessonOpacityBuilder,
    this.onChipTap,
    super.key,
  });

  /// All students to show on the grid.
  final List<Student> students;

  /// Number of columns in the grid (1–12).
  final int columns;

  /// Current grid position of each student, keyed by studentId.
  final Map<int, ({int col, int row})> positions;

  /// Called when the user drops a selected student into a new cell.
  final void Function(int studentId, int col, int row) onPositionChanged;

  /// When `true`, chips can be rearranged via tap-to-select-then-place.
  final bool editMode;

  /// Optional overlay widget for lesson-mode indicators.
  final Widget? Function(Student student)? lessonOverlayBuilder;

  /// Optional opacity override for lesson-mode chips.
  final double Function(Student student)? lessonOpacityBuilder;

  /// Called when a chip is tapped in view mode.
  final void Function(Student student)? onChipTap;

  @override
  State<SeatingPlanGrid> createState() => _SeatingPlanGridState();
}

class _SeatingPlanGridState extends State<SeatingPlanGrid> {
  int? _selectedStudentId;

  @override
  void didUpdateWidget(SeatingPlanGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.editMode) _selectedStudentId = null;
  }

  _GridBounds get _bounds {
    if (widget.positions.isEmpty) {
      return _GridBounds(
        rowStart: widget.editMode ? -1 : 0,
        rowEnd: widget.editMode ? 1 : 0,
        colStart: widget.editMode ? -1 : 0,
        colEnd: widget.columns - 1 + (widget.editMode ? 1 : 0),
      );
    }

    final minRow = widget.positions.values.map((p) => p.row).reduce(min);
    final maxRow = widget.positions.values.map((p) => p.row).reduce(max);
    final minCol = widget.positions.values.map((p) => p.col).reduce(min);
    final maxCol = widget.positions.values.map((p) => p.col).reduce(max);

    return _GridBounds(
      rowStart: widget.editMode ? minRow - 1 : minRow,
      rowEnd: widget.editMode ? maxRow + 1 : maxRow,
      colStart: widget.editMode ? minCol - 1 : minCol,
      colEnd: max(maxCol, widget.columns - 1) + (widget.editMode ? 1 : 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentById = {for (final s in widget.students) s.id: s};

    final cellToStudent = <(int, int), Student>{};
    for (final entry in widget.positions.entries) {
      final student = studentById[entry.key];
      if (student == null) continue;
      cellToStudent[(entry.value.col, entry.value.row)] = student;
    }

    final unplaced = widget.students
        .where((s) => !widget.positions.containsKey(s.id))
        .toList();

    final bounds = _bounds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _cellSize * bounds.colCount,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int row = bounds.rowStart; row <= bounds.rowEnd; row++)
                  Row(
                    children: [
                      for (
                        int col = bounds.colStart;
                        col <= bounds.colEnd;
                        col++
                      )
                        _buildCell(context, col, row, cellToStudent),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (unplaced.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Text(
            'unplaced_students'.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final student in unplaced)
                SeatingPlanChip(
                  student: student,
                  onTap: () => widget.onChipTap?.call(student),
                  opacity: widget.lessonOpacityBuilder?.call(student) ?? 1,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    int col,
    int row,
    Map<(int, int), Student> cellToStudent,
  ) {
    final student = cellToStudent[(col, row)];
    if (student != null) {
      final isSelected = student.id == _selectedStudentId;
      return _OccupiedCell(
        key: ValueKey('seating-plan-cell-$col-$row'),
        student: student,
        isSelected: isSelected,
        isSwapTarget:
            widget.editMode &&
            _selectedStudentId != null &&
            _selectedStudentId != student.id,
        lessonOverlay: widget.lessonOverlayBuilder?.call(student),
        opacity: widget.lessonOpacityBuilder?.call(student) ?? 1,
        onTap: () {
          if (widget.editMode) {
            if (_selectedStudentId != null && !isSelected) {
              widget.onPositionChanged(_selectedStudentId!, col, row);
              setState(() => _selectedStudentId = null);
              return;
            }
            setState(() => _selectedStudentId = isSelected ? null : student.id);
          } else {
            widget.onChipTap?.call(student);
          }
        },
      );
    }

    return _EmptyCell(
      key: ValueKey('seating-plan-cell-$col-$row'),
      highlight: widget.editMode && _selectedStudentId != null,
      onTap: widget.editMode && _selectedStudentId != null
          ? () {
              widget.onPositionChanged(_selectedStudentId!, col, row);
              setState(() => _selectedStudentId = null);
            }
          : null,
    );
  }
}

class _OccupiedCell extends StatelessWidget {
  const _OccupiedCell({
    required super.key,
    required this.student,
    required this.isSelected,
    required this.isSwapTarget,
    required this.onTap,
    required this.opacity,
    this.lessonOverlay,
  });

  final Student student;
  final bool isSelected;
  final bool isSwapTarget;
  final VoidCallback onTap;
  final double opacity;
  final Widget? lessonOverlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          border: isSwapTarget
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Center(
          child: SeatingPlanChip(
            student: student,
            onTap: onTap,
            opacity: opacity,
            lessonOverlay: lessonOverlay,
          ),
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required super.key, this.highlight = false, this.onTap});

  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                border: Border.all(
                  color: highlight
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: highlight ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridBounds {
  const _GridBounds({
    required this.rowStart,
    required this.rowEnd,
    required this.colStart,
    required this.colEnd,
  });

  final int rowStart;
  final int rowEnd;
  final int colStart;
  final int colEnd;

  int get colCount => colEnd - colStart + 1;
}
