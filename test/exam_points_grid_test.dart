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

    final fields = find.byType(TextField);
    // 2 students x 3 expectations; Grace already has 2 points for item 10.
    expect(fields, findsNWidgets(6));
    expect(find.widgetWithText(TextField, '2'), findsOneWidget);

    await tester.tap(fields.at(0));
    await tester.enterText(fields.at(0), '1,5');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(repository.saved, [(10, 1, 1.5)]);

    // Focus moved to Ada's second expectation (max 3): too many points.
    await tester.enterText(fields.at(1), '5');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      repository.saved,
      hasLength(1),
      reason: 'invalid value is not saved',
    );

    // Now in Grace's second field: clear-and-type a valid value.
    await tester.enterText(fields.at(4), '3');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(repository.saved.last, (11, 2, 3.0));
  });
}
