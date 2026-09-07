import 'dart:math' as math;

import 'package:classi/features/lessons/student_picker/spinning_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const segmentCount = 8;
  final labels = [for (var i = 0; i < segmentCount; i++) 'Student $i'];

  /// The rotation the wheel currently rests at, in turns.
  double restingTurns(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(AspectRatio),
        matching: find.byType(Transform),
      ),
    );
    final matrix = transform.transform.storage;
    final angle = math.atan2(matrix[1], matrix[0]);
    return (angle / (2 * math.pi)) % 1.0;
  }

  /// How far the centre of [index] sits from the pointer, in segments.
  double offsetFromPointer(double turns, int index) {
    // Segment centres sit at index / segmentCount turns from the pointer.
    final position = (index / segmentCount + turns) % 1.0;
    return math.min(position, 1 - position) * segmentCount;
  }

  testWidgets('stops with the reported segment under the pointer', (
    tester,
  ) async {
    final reported = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SpinningWheel(
              key: const Key('wheel'),
              segments: labels,
              onComplete: reported.add,
            ),
          ),
        ),
      ),
    );

    final state = tester.state<SpinningWheelState>(find.byType(SpinningWheel));

    // Several spins in a row: the landing angle must not drift as rotations
    // accumulate, and it must hit the segment centre rather than its border.
    for (var spin = 1; spin <= 5; spin++) {
      expect(state.spin(), isTrue);
      await tester.pumpAndSettle();

      expect(reported, hasLength(spin));
      expect(
        offsetFromPointer(restingTurns(tester), reported.last),
        closeTo(0, 0.01),
        reason: 'spin $spin landed away from the centre of ${reported.last}',
      );
    }
  });

  testWidgets('refuses to start a second spin while one runs', (tester) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SpinningWheel(
              segments: labels,
              onComplete: (_) => completions++,
            ),
          ),
        ),
      ),
    );

    final state = tester.state<SpinningWheelState>(find.byType(SpinningWheel));

    expect(state.spin(), isTrue);
    await tester.pump(const Duration(milliseconds: 500));
    expect(state.spin(), isFalse);

    await tester.pumpAndSettle();
    expect(completions, 1);
  });

  testWidgets('refuses to spin without segments', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SpinningWheel(segments: const [], onComplete: (_) {}),
          ),
        ),
      ),
    );

    final state = tester.state<SpinningWheelState>(find.byType(SpinningWheel));
    expect(state.spin(), isFalse);
  });
}
