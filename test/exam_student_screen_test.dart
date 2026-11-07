import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/exams/data/exam_repository.dart';
import 'package:classi/features/exams/domain/exam_structure.dart';
import 'package:classi/features/exams/domain/grade_scheme.dart';
import 'package:classi/features/exams/exam_providers.dart';
import 'package:classi/features/exams/ui/exam_student_screen.dart';
import 'package:classi/features/groups/group_detail_screen.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
  final group = Group(
    id: 1,
    name: '8a',
    colorHex: '#FF1E88E5',
    gradeScaleJson: encodeGradeScaleEntries(defaultGradeScaleEntries),
    gradeCategoriesJson: '[]',
    createdAt: date,
    updatedAt: date,
  );
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

  testWidgets('the per-student screen steps points and moves on', (
    tester,
  ) async {
    wideView(tester);
    final repository = _RecordingRepository();
    await tester.pumpWidget(
      app(const ExamStudentScreen(groupId: 1, examId: 5, studentId: 1), [
        examRepositoryProvider.overrideWithValue(repository),
        examSnapshotProvider(5).overrideWithValue(AsyncData(snapshot)),
        groupProvider(1).overrideWith((ref) => Stream.value(group)),
        groupStudentsProvider(
          1,
        ).overrideWith((ref) => Stream.value([ada, grace])),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expectation 10'), findsOneWidget);
    // "+" on the first expectation: 0 -> 0.5.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    expect(repository.saved.single, (10, 1, 0.5));

    // The "max" chip of the last expectation.
    await tester.tap(find.widgetWithText(ActionChip, '4'));
    await tester.pump();
    expect(repository.saved.last, (12, 1, 4.0));

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    final previous = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    expect(previous.onPressed, isNull, reason: 'Ada is the first student');
  });
}
