import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/theme/app_ui.dart';
import 'seating_fit.dart';
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
    this.fitScores,
    this.fitTooltipBuilder,
    this.relationLines = const [],
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

  /// How well each student's seat matches the group's seating rules, from
  /// `-1` (bad) to `1` (good), keyed by studentId. Scored seats are tinted
  /// green or red; students missing from the map keep a plain cell.
  final Map<int, double>? fitScores;

  /// Optional explanation of a student's fit score, shown as a cell tooltip.
  final String? Function(Student student)? fitTooltipBuilder;

  /// Rules to draw across the grid as a line between the pair they name,
  /// green for students that belong together and red — dashed, so the two
  /// stay apart for colour-blind eyes as well — for students to keep apart.
  /// Empty draws nothing.
  ///
  /// While a student is selected only the lines that name them are drawn, so
  /// a class with many rules stays readable while one seat is being sorted
  /// out.
  final List<SeatingRelationLine> relationLines;

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
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      int row = bounds.rowStart;
                      row <= bounds.rowEnd;
                      row++
                    )
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
                // Above the cells so a line stays visible over a tinted seat,
                // but never in the way of a tap.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _RelationLinesPainter(
                        segments: _lineSegments(bounds),
                        positiveColor: seatingRelationColor(
                          context,
                          isPositive: true,
                        ),
                        negativeColor: seatingRelationColor(
                          context,
                          isPositive: false,
                        ),
                      ),
                    ),
                  ),
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

  /// The lines to draw, in the grid's own pixel coordinates.
  ///
  /// A rule is skipped when either of its students has no seat on this plan.
  List<_LineSegment> _lineSegments(_GridBounds bounds) {
    Offset? centerOf(int studentId) {
      final position = widget.positions[studentId];
      if (position == null) return null;
      return Offset(
        (position.col - bounds.colStart + 0.5) * _cellSize,
        (position.row - bounds.rowStart + 0.5) * _cellSize,
      );
    }

    final selected = _selectedStudentId;

    return [
      for (final line in widget.relationLines)
        if (selected == null ||
            line.studentAId == selected ||
            line.studentBId == selected)
          if (centerOf(line.studentAId) case final a?)
            if (centerOf(line.studentBId) case final b?)
              (from: a, to: b, isPositive: line.isPositive),
    ];
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
        fitScore: widget.fitScores?[student.id],
        fitTooltip: widget.fitTooltipBuilder?.call(student),
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
    this.fitScore,
    this.fitTooltip,
    this.lessonOverlay,
  });

  final Student student;
  final bool isSelected;
  final bool isSwapTarget;
  final VoidCallback onTap;
  final double opacity;
  final double? fitScore;
  final String? fitTooltip;
  final Widget? lessonOverlay;

  @override
  Widget build(BuildContext context) {
    // Selection has to stay readable, so it wins over the fit tint.
    final background = isSelected
        ? Theme.of(context).colorScheme.primaryContainer
        : seatingFitColor(context, fitScore) ?? Colors.transparent;

    // The chip is a good deal smaller than its cell, so let the whole cell
    // take the tap: aiming for the avatar is fiddly, and a miss used to do
    // nothing at all.
    final cell = SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: background,
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
      ),
    );

    final tooltip = fitTooltip;
    if (tooltip == null) return cell;
    return Tooltip(message: tooltip, child: cell);
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required super.key, this.highlight = false, this.onTap});

  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Same as an occupied cell: the gap around the outline is part of the
    // target, so a click near the edge still places the selected student.
    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: Padding(
            padding: const EdgeInsets.all(4),
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

/// One drawn rule: the two seat centres it connects and its colour.
typedef _LineSegment = ({Offset from, Offset to, bool isPositive});

/// How far a line stops short of a seat's centre, so the faces stay clear.
const double _avatarClearance = 26.0;

class _RelationLinesPainter extends CustomPainter {
  const _RelationLinesPainter({
    required this.segments,
    required this.positiveColor,
    required this.negativeColor,
  });

  final List<_LineSegment> segments;
  final Color positiveColor;
  final Color negativeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final segment in segments) {
      final direction = segment.to - segment.from;
      final length = direction.distance;
      // Two students on the same cell — an older plan can still hold that —
      // have no line to draw.
      if (length <= 2 * _avatarClearance) continue;

      final step = direction / length;
      final from = segment.from + step * _avatarClearance;
      final to = segment.to - step * _avatarClearance;

      paint.color = (segment.isPositive ? positiveColor : negativeColor)
          .withValues(alpha: 0.85);
      if (segment.isPositive) {
        canvas.drawLine(from, to, paint);
      } else {
        _drawDashed(canvas, from, to, paint);
      }
    }
  }

  void _drawDashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 7.0;
    const gap = 5.0;
    final direction = to - from;
    final length = direction.distance;
    final step = direction / length;

    for (var start = 0.0; start < length; start += dash + gap) {
      final end = min(start + dash, length);
      canvas.drawLine(from + step * start, from + step * end, paint);
    }
  }

  @override
  bool shouldRepaint(_RelationLinesPainter oldDelegate) {
    return oldDelegate.positiveColor != positiveColor ||
        oldDelegate.negativeColor != negativeColor ||
        !listEquals(oldDelegate.segments, segments);
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
