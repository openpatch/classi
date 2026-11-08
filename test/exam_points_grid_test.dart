import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/exams/data/exam_repository.dart';
import 'package:classi/features/exams/domain/exam_structure.dart';
import 'package:classi/features/exams/domain/grade_scheme.dart';
import 'package:classi/features/exams/exam_providers.dart';
import 'package:classi/features/exams/ui/exam_points_grid.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records writes instead of touching a database.
class _RecordingRepository extends ExamRepository {
  _RecordingRepository() : super(AppDatabase.test(NativeDatabase.memory()));

  final saved = <(int expectation, int student, double? points)>[];

  @override
  Future<void> setScore({
    required int examId,
    required int expectationId,
    required int studentId,
    required double? points,
  }) async {
    saved.add((expectationId, studentId, points));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final date = DateTime(2026, 11, 3);
  Student student(int id, String first) => Student(
    id: id,
    firstName: first,
    lastName: 'Test',
    groupId: 1,
    createdAt: date,
    updatedAt: date,
  );
  final ada = student(1, 'Ada');
  final grace = student(2, 'Grace');
  final exam = Exam(
    id: 5,
    groupId: 1,
    title: 'KA 1',
    date: date,
    categoryId: 'klassenarbeit',
    categoryName: 'Klassenarbeit',
    source: 'manual',
    gradeSchemeJson: GradeScheme(
      thresholds: defaultThresholdsFor(defaultGradeScaleEntries),
    ).encode(),
    structureJson: '{}',
    createdAt: date,
    updatedAt: date,
  );
  ExamItem item(int id, String task, double max) => ExamItem(
    id: id,
    matchKey: 'k$id',
    kind: ExpectationKind.regular,
    task: task,
    description: 'Expectation $id',
    maxPoints: max,
    sortOrder: id,
  );
  final snapshot = ExamSnapshot(
    exam: exam,
    items: [item(10, '1', 2), item(11, '1', 3), item(12, '2', 4)],
    meta: const ExamStructureMeta(),
    scheme: GradeScheme.decode(exam.gradeSchemeJson),
    scores: const {
      2: {10: 2},
    },
    participants: const {},
  );

  Widget app(Widget home, List overrides) => ProviderScope(
    overrides: [...overrides],
    child: EasyLocalization(
      supportedLocales: const [Locale('en')],
      fallbackLocale: const Locale('en'),
      path: 'assets/translations',
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: home,
        ),
      ),
    ),
  );

  void wideView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('the grid saves with the keyboard and rejects invalid values', (
    tester,
  ) async {
    wideView(tester);
    final repository = _RecordingRepository();
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ExamPointsGrid(snapshot: snapshot, students: [ada, grace]),
        ),
        [examRepositoryProvider.overrideWithValue(repository)],
      ),
    );
    await tester.pumpAndSettle();

    // Cells are plain text until selected: no text field yet.
    expect(find.byType(TextField), findsNothing);
    final editor = find.byType(TextField);

    // Grace already has 2 points for item 10; open that cell.
    await tester.tap(
      find.descendant(
        of: find.byType(GestureDetector),
        matching: find.text('2'),
      ),
    );
    await tester.pumpAndSettle();
    expect(editor, findsOneWidget);
    expect(tester.widget<TextField>(editor).controller!.text, '2');

    await type(tester, '1,5');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(repository.saved, [(10, 2, 1.5)]);
    // The saved value stays visible until the database reports it back.
    expect(
      find.descendant(
        of: find.byType(GestureDetector),
        matching: find.text('1.5'),
      ),
      findsOneWidget,
    );

    // Enter moved to Grace's second expectation (max 3): too many points.
    await type(tester, '5');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(
      repository.saved,
      hasLength(1),
      reason: 'invalid value is not saved and the cell stays open',
    );

    await type(tester, '3');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(repository.saved.last, (11, 2, 3.0));

    // Tab and Shift+Tab move sideways; typing lands in the new cell.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await type(tester, '2');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(repository.saved.last, (12, 1, 2.0));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    // Back on Ada's last expectation: Escape discards what was typed.
    await type(tester, '1');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(editor).controller!.text, '2');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(repository.saved, hasLength(3));
  });
}

/// Types into whatever has keyboard focus, like a real keyboard (unlike
/// `tester.enterText`, which focuses the field first).
Future<void> type(WidgetTester tester, String text) async {
  expect(
    tester.testTextInput.hasAnyClients,
    isTrue,
    reason: 'no field accepts typing',
  );
  tester.testTextInput.enterText(text);
  await tester.pump();
}
