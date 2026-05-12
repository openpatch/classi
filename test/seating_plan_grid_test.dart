import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
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
}

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
  );
}
