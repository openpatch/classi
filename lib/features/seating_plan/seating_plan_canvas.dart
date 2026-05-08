import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import 'seating_plan_chip.dart';

/// An interactive 2D canvas on which [SeatingPlanChip]s can be freely dragged.
///
/// [positions] maps each studentId to its current canvas [Offset].
/// [onPositionChanged] is called when the user finishes dragging a chip.
///
/// Wrapping the canvas in [InteractiveViewer] lets the teacher pan and zoom
/// the whole plane without conflicting with individual chip drags.
class SeatingPlanCanvas extends StatefulWidget {
  const SeatingPlanCanvas({
    required this.students,
    required this.positions,
    required this.onPositionChanged,
    this.lessonOverlayBuilder,
    this.onChipTap,
    super.key,
  });

  final List<Student> students;

  /// Current positions indexed by studentId.
  final Map<int, Offset> positions;

  /// Called when the user drops a chip at a new position.
  final void Function(int studentId, double x, double y) onPositionChanged;

  /// Optional builder for the lesson-mode overlay painted on each chip's avatar.
  final Widget? Function(Student student)? lessonOverlayBuilder;

  /// Called when a chip is tapped.
  final void Function(Student student)? onChipTap;

  @override
  State<SeatingPlanCanvas> createState() => _SeatingPlanCanvasState();
}

class _SeatingPlanCanvasState extends State<SeatingPlanCanvas> {
  /// Live overrides while a drag is in progress, so the chip moves smoothly.
  final Map<int, Offset> _dragOffsets = {};

  /// Positions committed locally on drop, before the parent stream delivers
  /// the persisted value. Prevents a chip from snapping back to its old
  /// position while another chip is being dragged.
  final Map<int, Offset> _committedPositions = {};

  static const double _canvasWidth = 1200.0;
  static const double _canvasHeight = 900.0;

  @override
  void didUpdateWidget(SeatingPlanCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Once the stream-backed positions arrive, discard any locally cached
    // value for chips that are not currently being dragged.
    if (!identical(oldWidget.positions, widget.positions)) {
      _committedPositions.removeWhere((id, _) => !_dragOffsets.containsKey(id));
    }
  }

  Offset _baseFor(int studentId) =>
      _committedPositions[studentId] ??
      widget.positions[studentId] ??
      Offset.zero;

  Offset _clamp(Offset offset) {
    return Offset(
      offset.dx.clamp(0.0, _canvasWidth - _chipWidth),
      offset.dy.clamp(0.0, _canvasHeight - chipHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(40),
        minScale: 0.4,
        maxScale: 2.0,
        child: SizedBox(
          width: _canvasWidth,
          height: _canvasHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final student in widget.students)
                _buildChip(student),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(Student student) {
    final base = _baseFor(student.id);
    final current = _dragOffsets[student.id] ?? base;

    return Positioned(
      left: current.dx,
      top: current.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _dragOffsets[student.id] = _clamp(
              (_dragOffsets[student.id] ?? base) + details.delta,
            );
          });
        },
        onPanEnd: (_) {
          final newOffset = _dragOffsets[student.id] ?? base;
          setState(() {
            _dragOffsets.remove(student.id);
            // Cache locally so the chip stays put until the stream catches up.
            _committedPositions[student.id] = newOffset;
          });
          widget.onPositionChanged(student.id, newOffset.dx, newOffset.dy);
        },
        child: SeatingPlanChip(
          student: student,
          onTap: () => widget.onChipTap?.call(student),
          lessonOverlay: widget.lessonOverlayBuilder?.call(student),
        ),
      ),
    );
  }
}

const double _chipWidth = 80.0;
