import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/features/grades/grade_round_screen.dart';
import 'package:classi/features/students/student_sorting.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final date = DateTime(2026, 9, 7);
  Student student(int id, String firstName, String lastName) => Student(
    id: id,
    firstName: firstName,
    lastName: lastName,
    groupId: 1,
    createdAt: date,
    updatedAt: date,
  );

  final ada = student(1, 'Ada', 'Lovelace');
  final grace = student(2, 'Grace', 'Hopper');
  final alan = student(3, 'Alan', 'Turing');

  // Only the first EasyLocalization of a test file renders its translations,
  // so the round is mounted once and driven through from there.
  testWidgets('grades one student after the other, skipping the absent', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(1000, 2000);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    final saved = <int, String>{};
    final cleared = <int>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentSortFieldProvider.overrideWith(
            (ref) => StudentSortField.firstName,
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en')],
          fallbackLocale: const Locale('en'),
          path: 'assets/translations',
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: GradeRoundScreen(
                title: 'Test',
                students: [ada, grace, alan],
                absentStudentIds: {grace.id},
                initialSelections: const {},
                gradeScale: defaultGradeScaleEntries,
                onSave: (id, value) async => saved[id] = value,
                onClear: (id) async => cleared.add(id),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Grace is absent, so the round goes Ada, then Alan.
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('1 of 2 · 0 graded'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '2'));
    await tester.pumpAndSettle();
    expect(saved, {ada.id: '2'});
    expect(find.text('Alan Turing'), findsOneWidget);

    // Typing a grade on the keyboard takes it at once.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pumpAndSettle();
    expect(saved, {ada.id: '2', alan.id: '4'});

    // After the last student comes the grade distribution.
    expect(find.text('Grade distribution'), findsOneWidget);
    expect(find.text('2 grades · Ø 3.00 (3)'), findsOneWidget);
    expect(cleared, isEmpty);
  });
}
