import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A spinning wheel that displays student names as coloured segments.
///
/// Call [spin] to animate the wheel to a random segment. The [onComplete]
/// callback fires with the index of the segment the pointer landed on.
class SpinningWheel extends StatefulWidget {
  const SpinningWheel({
    required this.segments,
    required this.onComplete,
    super.key,
  });

  /// The labels shown on the wheel, one per segment.
  final List<String> segments;

  /// Called when a spin finishes, with the index of the selected segment.
  final ValueChanged<int> onComplete;

  @override
  State<SpinningWheel> createState() => SpinningWheelState();
}

class SpinningWheelState extends State<SpinningWheel>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _animation;
  final math.Random _random = math.Random();

  // Where the wheel currently rests, in turns within [0, 1). Normalising after
  // every spin keeps the next target an absolute angle instead of an offset
  // that accumulates the previous landing positions.
  double _baseRotation = 0;

  int _targetIndex = 0;
  double _spinDelta = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    // Spin fast, then coast to a stop instead of halting mid-turn.
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete(_targetIndex);
      }
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Starts a spin, returning whether one was actually started.
  ///
  /// Returns `false` when there is nothing to spin or a spin is already
  /// running, so callers can keep their own busy state in sync.
  bool spin() {
    if (widget.segments.isEmpty || _controller.isAnimating) {
      return false;
    }

    // Fold the finished spin into the rest position first: the animation still
    // reads 1, so the delta it holds is part of where the wheel sits now.
    // Normalising to [0, 1) keeps the next target an absolute angle.
    _baseRotation = (_baseRotation + _spinDelta) % 1.0;
    _targetIndex = _random.nextInt(widget.segments.length);

    // Segment centres sit at index / segments turns clockwise from the pointer
    // (see [_WheelPainter.paint]), so the wheel has to come to rest at
    // -targetCentre turns. Subtracting the current rest position makes the
    // delta an absolute correction rather than a relative one.
    final targetCentre = _targetIndex / widget.segments.length;
    final extraSpins = 5 + _random.nextInt(3); // 5–7 full spins
    _spinDelta = extraSpins + (1.0 - targetCentre) - _baseRotation;

    _controller.forward(from: 0);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Pointer(),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final rotation =
                      _baseRotation + _animation.value * _spinDelta;
                  return Transform.rotate(
                    angle: rotation * 2 * math.pi,
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: size,
                  painter: _WheelPainter(
                    segments: widget.segments,
                    theme: Theme.of(context),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Pointer extends StatelessWidget {
  const _Pointer();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: const Size(20, 16),
      painter: _PointerPainter(color: color),
    );
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.segments, required this.theme});

  final List<String> segments;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / segments.length;
    final isDark = theme.brightness == Brightness.dark;

    for (var i = 0; i < segments.length; i++) {
      // Segment i starts at -pi/2 - segmentAngle/2 + i * segmentAngle so that
      // segment 0 is centred at the top (pointer position).
      final startAngle = -math.pi / 2 - segmentAngle / 2 + i * segmentAngle;

      // Distinct, pleasant colour per segment using HSL hue rotation, kept
      // darker in a dark theme so the wheel does not glare.
      final hue = (i * 360 / segments.length) % 360;
      final fillColor = HSLColor.fromAHSL(
        1,
        hue,
        0.5,
        isDark ? 0.42 : 0.68,
      ).toColor();
      final fill = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        fill,
      );

      // Outline each segment.
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        Paint()
          ..color = theme.colorScheme.outline.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Draw the label along the slice, running from the hub outwards. Slices
      // on the left half are turned around so their names stay the right way
      // up instead of reading back to front.
      final labelAngle = startAngle + segmentAngle / 2;
      final isFlipped = math.cos(labelAngle) < 0;
      final labelDistance = radius * 0.6;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(isFlipped ? labelAngle + math.pi : labelAngle);

      final textSpan = TextSpan(
        text: segments[i],
        style: TextStyle(
          color:
              ThemeData.estimateBrightnessForColor(fillColor) == Brightness.dark
              ? Colors.white
              : Colors.black87,
          fontSize: _fontSizeFor(segments.length, radius),
          fontWeight: FontWeight.w600,
        ),
      );
      // A slice is far longer than it is wide, so a name only needs shortening
      // when it would run past the rim. The length is capped short of the hub
      // as well: slices are at their narrowest there, and a long name reaching
      // that far in would run into its neighbours.
      final painter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.62);
      painter.paint(
        canvas,
        Offset(
          (isFlipped ? -labelDistance : labelDistance) - painter.width / 2,
          -painter.height / 2,
        ),
      );
      canvas.restore();
    }

    // Centre hub.
    canvas.drawCircle(
      center,
      radius * 0.08,
      Paint()..color = theme.colorScheme.surface,
    );
    canvas.drawCircle(
      center,
      radius * 0.08,
      Paint()
        ..color = theme.colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  double _fontSizeFor(int totalSegments, double radius) {
    if (totalSegments > 20) return radius * 0.06;
    if (totalSegments > 12) return radius * 0.075;
    return radius * 0.085;
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      !listEquals(segments, oldDelegate.segments) || theme != oldDelegate.theme;
}
