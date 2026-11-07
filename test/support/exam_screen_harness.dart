import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/features/exams/data/exam_repository.dart';
import 'package:classi/features/exams/domain/exam_structure.dart';
import 'package:classi/features/exams/domain/grade_scheme.dart';
import 'package:classi/features/exams/exam_providers.dart';
import 'package:classi/features/exams/ui/exam_screen.dart';
import 'package:classi/features/groups/group_detail_screen.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every tab of the exam screen at [width] and fails on any
/// exception (layout overflows included). One width per test file: only the
/// first EasyLocalization of a file renders its translations.
void runExamScreenTabsTest(String name, double width) {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final date = DateTime(2026, 11, 3);
  Student student(int id, String first, String last) => Student(
    id: id,
    firstName: first,
    lastName: last,
    groupId: 1,
    createdAt: date,
    updatedAt: date,
  );
  final students = [
    student(1, 'Ada', 'Lovelace'),
    student(2, 'Grace', 'Hopper'),
    student(3, 'Alan', 'Turing'),
    student(4, 'Katherine', 'Johnson-With-A-Rather-Long-Name'),
  ];
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
    title: 'Klassenarbeit 1: Quadratische Gleichungen und Funktionen',
    date: date,
    categoryId: 'klassenarbeit',
    categoryName: 'Klassenarbeit',
    source: 'typst',
    gradeSchemeJson: GradeScheme(
      thresholds: [
        for (final t in defaultThresholdsFor(defaultGradeScaleEntries))
          GradeThreshold(
            label: t.label,
            minPercent: t.minPercent,
            sourceLabel: 'sehr gut ${t.label}',
          ),
      ],
    ).encode(),
    structureJson: const ExamStructureMeta(
      electiveGroups: [
        ElectiveGroupInfo(id: 'W', label: 'Wahlteil', countedTasks: 1),
      ],
      taskTitles: {'1': 'Gleichungen'},
    ).encode(),
    rubricSha256: 'abc',
    createdAt: date,
    updatedAt: date,
  );
  ExamItem item(
    int id,
    ExpectationKind kind,
    String task,
    double max, {
    String? part,
    String? label,
    String? group,
  }) => ExamItem(
    id: id,
    matchKey: 'k$id',
    kind: kind,
    task: task,
    part: part,
    groupKey: group,
    label: label,
    description:
        'Expectation $id with a description long enough to wrap on a phone screen',
    maxPoints: max,
    sortOrder: id,
  );
  final items = [
    item(1, ExpectationKind.regular, '1', 2, label: 'AFB I'),
    item(2, ExpectationKind.regular, '1', 3, label: 'AFB II'),
    item(3, ExpectationKind.alternative, '1', 0),
    item(4, ExpectationKind.regular, '2', 4, part: 'a', label: 'AFB III'),
    item(5, ExpectationKind.elective, '3', 3, group: 'W'),
    item(6, ExpectationKind.elective, '4', 3, group: 'W'),
    item(7, ExpectationKind.additional, '', 1),
  ];
  final snapshot = ExamSnapshot(
    exam: exam,
    items: items,
    meta: ExamStructureMeta.decode(exam.structureJson),
    scheme: GradeScheme.decode(exam.gradeSchemeJson),
    scores: const {
      1: {1: 2, 2: 3, 4: 4, 5: 3, 7: 1},
      2: {1: 1, 2: 1.5},
      4: {1: 0, 2: 0, 4: 1, 6: 2, 7: 0},
    },
    participants: {
      3: ExamParticipant(
        id: 1,
        examId: 5,
        studentId: 3,
        status: 'absent',
        createdAt: date,
        updatedAt: date,
      ),
    },
  );

  {
    testWidgets('every tab renders on a $name', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            examSnapshotProvider(5).overrideWithValue(AsyncData(snapshot)),
            examTypstChangedProvider(5).overrideWith((ref) async => true),
            groupProvider(1).overrideWith((ref) => Stream.value(group)),
            groupStudentsProvider(
              1,
            ).overrideWith((ref) => Stream.value(students)),
            typstSupportedProvider.overrideWithValue(true),
            selectedDatabasePathProvider.overrideWithValue(null),
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
                home: const ExamScreen(groupId: 1, examId: 5),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(MaterialBanner),
        findsOneWidget,
        reason: 'document changed',
      );
      for (final tab in [
        'exam_tab_results',
        'exam_tab_points',
        'exam_tab_structure',
        'exam_tab_scheme',
        'exam_tab_analysis',
      ]) {
        await tester.tap(find.text(tab.tr()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      // Analysis lists the labels used as requirement levels.
      await tester.scrollUntilVisible(
        find.text('AFB III'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .first,
      );
      expect(find.text('AFB III'), findsWidgets);
    });
  }
}
