import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/features/seating_plan/seating_fit.dart';
import 'package:classi/features/seating_plan/seating_plan_grid.dart';
import 'package:classi/features/students/student_sorting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('extra border cells are only visible in edit mode', (
    tester,
  ) async {
    final students = [_student(id: 1, firstName: 'Ada', lastName: 'Lovelace')];
    final positions = <int, ({int col, int row})>{1: (col: 0, row: 0)};

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: students,
          columns: 2,
          positions: positions,
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('seating-plan-cell-0--1')), findsNothing);
    expect(find.byKey(const ValueKey('seating-plan-cell--1-0')), findsNothing);
    expect(find.byKey(const ValueKey('seating-plan-cell-2-0')), findsNothing);
    expect(find.byKey(const ValueKey('seating-plan-cell-0-1')), findsNothing);

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: students,
          columns: 2,
          positions: positions,
          editMode: true,
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('seating-plan-cell-0--1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('seating-plan-cell--1-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('seating-plan-cell-2-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('seating-plan-cell-0-1')), findsOneWidget);
  });

  testWidgets('clicking another student in edit mode targets that cell', (
    tester,
  ) async {
    final students = [
      _student(id: 1, firstName: 'Ada', lastName: 'Lovelace'),
      _student(id: 2, firstName: 'Grace', lastName: 'Hopper'),
    ];
    final positions = <int, ({int col, int row})>{
      1: (col: 0, row: 0),
      2: (col: 1, row: 0),
    };
    (int studentId, int col, int row)? movedTo;

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: students,
          columns: 2,
          positions: positions,
          editMode: true,
          onPositionChanged: (studentId, col, row) {
            movedTo = (studentId, col, row);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grace Hopper'));
    await tester.pumpAndSettle();

    expect(movedTo, (1, 1, 0));
  });

  testWidgets('the whole cell selects, not just the chip inside it', (
    tester,
  ) async {
    (int, int, int)? movedTo;

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: [_student(id: 1, firstName: 'Ada', lastName: 'Lovelace')],
          columns: 2,
          positions: const {1: (col: 0, row: 0)},
          editMode: true,
          // A tooltip wraps the cell, so this also covers that it does not
          // swallow the tap.
          fitTooltipBuilder: (_) => 'Should not sit with: Grace Hopper',
          onPositionChanged: (id, col, row) => movedTo = (id, col, row),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The chip sits in the middle of its cell; aim at the corner instead,
    // which used to be dead space.
    Offset corner(int col, int row) =>
        tester.getTopLeft(
          find.byKey(ValueKey('seating-plan-cell-$col-$row')),
        ) +
        const Offset(4, 4);

    await tester.tapAt(corner(0, 0));
    await tester.pumpAndSettle();
    // Only a selected student can be placed, so the move proves the corner
    // tap selected Ada.
    await tester.tapAt(corner(1, 0));
    await tester.pumpAndSettle();

    expect(movedTo, (1, 1, 0));
  });

  testWidgets('a scored seat is tinted and explains itself in a tooltip', (
    tester,
  ) async {
    final students = [
      _student(id: 1, firstName: 'Ada', lastName: 'Lovelace'),
      _student(id: 2, firstName: 'Grace', lastName: 'Hopper'),
    ];

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: students,
          columns: 2,
          positions: const {1: (col: 0, row: 0), 2: (col: 1, row: 0)},
          fitScores: const {1: -1, 2: -1},
          fitTooltipBuilder: (student) =>
              student.id == 1 ? 'Should not sit near: Grace Hopper' : null,
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_cellColor(tester, 0, 0), seatingFitColor(_cellContext(tester), -1));
    expect(
      tester
          .widget<Tooltip>(
            find.descendant(
              of: find.byKey(const ValueKey('seating-plan-cell-0-0')),
              matching: find.byType(Tooltip),
            ),
          )
          .message,
      'Should not sit near: Grace Hopper',
    );
    // Grace has no tooltip text, so her cell must not be wrapped either.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('seating-plan-cell-1-0')),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
    );
  });

  testWidgets('a cell keeps its tooltip in edit mode', (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: [_student(id: 1, firstName: 'Ada', lastName: 'Lovelace')],
          columns: 2,
          positions: const {1: (col: 0, row: 0)},
          editMode: true,
          fitScores: const <int, double>{},
          fitTooltipBuilder: (_) => 'Should not sit with: Grace Hopper',
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Edit mode grows the grid by a row and a column on each side, so the
    // student sits in the cell that still carries their own coordinates.
    expect(
      tester
          .widget<Tooltip>(
            find.descendant(
              of: find.byKey(const ValueKey('seating-plan-cell-0-0')),
              matching: find.byType(Tooltip),
            ),
          )
          .message,
      'Should not sit with: Grace Hopper',
    );
  });

  testWidgets('a rule draws a line between the two seats it names', (
    tester,
  ) async {
    final students = [
      _student(id: 1, firstName: 'Ada', lastName: 'Lovelace'),
      _student(id: 2, firstName: 'Grace', lastName: 'Hopper'),
    ];

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: students,
          columns: 2,
          positions: const {1: (col: 0, row: 0), 2: (col: 1, row: 0)},
          relationLines: const [
            (studentAId: 1, studentBId: 2, isPositive: true),
          ],
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cells are 96 wide, so the seats' centres are 96 apart; the line stops
    // short of both avatars.
    expect(
      find.byType(SeatingPlanGrid),
      paints..line(
        p1: const Offset(74, 48),
        p2: const Offset(118, 48),
        color: seatingRelationColor(
          _cellContext(tester),
          isPositive: true,
        ).withValues(alpha: 0.85),
      ),
    );
  });

  testWidgets('a keep-apart rule is drawn dashed and in red', (tester) async {
    final students = [
      _student(id: 1, firstName: 'Ada', lastName: 'Lovelace'),
      _student(id: 2, firstName: 'Grace', lastName: 'Hopper'),
    ];

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: students,
          columns: 2,
          positions: const {1: (col: 0, row: 0), 2: (col: 1, row: 0)},
          relationLines: const [
            (studentAId: 1, studentBId: 2, isPositive: false),
          ],
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final red = seatingRelationColor(
      _cellContext(tester),
      isPositive: false,
    ).withValues(alpha: 0.85);
    // Several segments rather than one: the dashes are what tells the two
    // kinds of rule apart without relying on colour.
    expect(
      find.byType(SeatingPlanGrid),
      paints
        ..line(color: red)
        ..line(color: red)
        ..line(color: red),
    );
  });

  testWidgets('selecting a student narrows the lines down to theirs', (
    tester,
  ) async {
    final students = [
      _student(id: 1, firstName: 'Ada', lastName: 'Lovelace'),
      _student(id: 2, firstName: 'Grace', lastName: 'Hopper'),
      _student(id: 3, firstName: 'Alan', lastName: 'Turing'),
      _student(id: 4, firstName: 'Katherine', lastName: 'Johnson'),
    ];

    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: students,
          columns: 4,
          positions: const {
            1: (col: 0, row: 0),
            2: (col: 1, row: 0),
            3: (col: 2, row: 0),
            4: (col: 3, row: 0),
          },
          editMode: true,
          relationLines: const [
            (studentAId: 1, studentBId: 2, isPositive: true),
            (studentAId: 3, studentBId: 4, isPositive: true),
          ],
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final green = seatingRelationColor(
      _cellContext(tester),
      isPositive: true,
    ).withValues(alpha: 0.85);
    // Edit mode keeps a spare row and column around the seats, so the first
    // student's centre sits one cell in.
    const adaToGrace = (p1: Offset(170, 144), p2: Offset(214, 144));
    const alanToKatherine = (p1: Offset(362, 144), p2: Offset(406, 144));
    expect(
      find.byType(SeatingPlanGrid),
      paints
        ..line(p1: adaToGrace.p1, p2: adaToGrace.p2)
        ..line(p1: alanToKatherine.p1, p2: alanToKatherine.p2),
    );

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();

    // Only Ada's rule is left; the pair across the room is out of the way.
    expect(
      find.byType(SeatingPlanGrid),
      paints..line(p1: adaToGrace.p1, p2: adaToGrace.p2, color: green),
    );
    expect(
      find.byType(SeatingPlanGrid),
      isNot(
        paints..line(
          p1: alanToKatherine.p1,
          p2: alanToKatherine.p2,
          color: green,
        ),
      ),
    );
  });

  testWidgets('no lines are drawn when the rules are toggled off', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: [
            _student(id: 1, firstName: 'Ada', lastName: 'Lovelace'),
            _student(id: 2, firstName: 'Grace', lastName: 'Hopper'),
          ],
          columns: 2,
          positions: const {1: (col: 0, row: 0), 2: (col: 1, row: 0)},
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SeatingPlanGrid), isNot(paints..line()));
  });

  testWidgets('a rule naming a student who has no seat draws nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: [_student(id: 1, firstName: 'Ada', lastName: 'Lovelace')],
          columns: 2,
          positions: const {1: (col: 0, row: 0)},
          relationLines: const [
            (studentAId: 1, studentBId: 7, isPositive: true),
          ],
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SeatingPlanGrid), isNot(paints..line()));
  });

  testWidgets('an unscored seat keeps a plain cell', (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        child: SeatingPlanGrid(
          students: [_student(id: 1, firstName: 'Ada', lastName: 'Lovelace')],
          columns: 2,
          positions: const {1: (col: 0, row: 0)},
          fitScores: const <int, double>{},
          onPositionChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_cellColor(tester, 0, 0), Colors.transparent);
  });
}

/// The painted background of the cell at [col], [row].
///
/// The avatar inside the cell animates a container of its own, so take the
/// outermost match — the cell's own background.
Color? _cellColor(WidgetTester tester, int col, int row) {
  final container = tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byKey(ValueKey('seating-plan-cell-$col-$row')),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .first;
  return (container.decoration! as BoxDecoration).color;
}

/// A context below the [MaterialApp], so the theme brightness the grid sees is
/// the one the expected colour is built from.
BuildContext _cellContext(WidgetTester tester) =>
    tester.element(find.byType(SeatingPlanGrid));

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        studentSortFieldProvider.overrideWith(
          (ref) => StudentSortField.firstName,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }
}

Student _student({
  required int id,
  required String firstName,
  required String lastName,
}) {
  return Student(
    id: id,
    firstName: firstName,
    lastName: lastName,
    groupId: 1,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}
