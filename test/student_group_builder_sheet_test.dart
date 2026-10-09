import 'dart:async';
import 'dart:convert';

import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/features/attendance/attendance_repository.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/lessons/group_builder/student_group_builder_sheet.dart';
import 'package:classi/features/lessons/lesson_mode_screen.dart';
import 'package:classi/features/lessons/lesson_support.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/features/students/student_sorting.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:classi/shared/widgets/student_avatar.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Map<String, dynamic> _english;
late Map<String, dynamic> _german;
final _date = DateTime(2026, 10, 9);
final _roster = [
  for (var id = 1; id <= 7; id++)
    Student(
      id: id,
      groupId: 1,
      firstName: 'Student $id',
      lastName: 'Test',
      callName: id == 1 ? 'Call name' : null,
      createdAt: _date,
      updatedAt: _date,
    ),
];

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      locale.languageCode == 'de' ? _german : _english;
}

Widget _localized(Widget home, Locale locale) => EasyLocalization(
  assetLoader: const _TestAssetLoader(),
  supportedLocales: const [Locale('en'), Locale('de')],
  startLocale: locale,
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
);

Future<void> _pump(
  WidgetTester tester, {
  Stream<List<Student>>? students,
  Stream<Set<int>>? absences,
  Locale locale = const Locale('en'),
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentSortFieldProvider.overrideWith(
          (ref) => StudentSortField.firstName,
        ),
        lessonStudentsProvider(
          1,
        ).overrideWith((ref) => students ?? Stream.value(_roster)),
        lessonAbsenceSelectionsProvider((
          1,
          _date,
          5,
        )).overrideWith((ref) => absences ?? Stream.value(<int>{})),
      ],
      child: _localized(
        StudentGroupBuilderSheet(groupId: 1, date: _date, periodStart: 5),
        locale,
      ),
    ),
  );
  for (
    var attempt = 0;
    attempt < 10 && find.byType(MaterialApp).evaluate().isEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (settle) await tester.pumpAndSettle();
}

List<int> _assignedIds(WidgetTester tester) => [
  for (final avatar in tester.widgetList<StudentAvatar>(
    find.byType(StudentAvatar),
  ))
    avatar.student.id,
];

Future<void> _generate(WidgetTester tester, {bool reshuffle = false}) async {
  final button = find.widgetWithText(
    FilledButton,
    reshuffle ? 'Reshuffle groups' : 'Generate groups',
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    _english = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/translations/en.json'))
          as Map,
    );
    _german = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/translations/de.json'))
          as Map,
    );
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'selects a size and reshuffles only present students on a phone',
    (tester) async {
      phone(tester);
      await _pump(tester, absences: Stream.value({7}));
      expect(find.text('Present: 6 · Groups: 2'), findsOneWidget);
      expect(find.text('Excluded: 1 absent'), findsOneWidget);
      expect(_assignedIds(tester), isEmpty);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2').last);
      await tester.pumpAndSettle();
      expect(find.text('Present: 6 · Groups: 3'), findsOneWidget);

      await _generate(tester);
      expect(find.text('Group 1'), findsOneWidget);
      expect(find.text('Group 2'), findsOneWidget);
      expect(find.text('Group 3'), findsOneWidget);
      expect(find.text('Call name Test'), findsOneWidget);
      expect(_assignedIds(tester), unorderedEquals([1, 2, 3, 4, 5, 6]));
      for (var round = 0; round < 3; round++) {
        await _generate(tester, reshuffle: true);
        expect(_assignedIds(tester), unorderedEquals([1, 2, 3, 4, 5, 6]));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('waits for attendance and handles attendance errors', (
    tester,
  ) async {
    final absences = StreamController<Set<int>>();
    addTearDown(absences.close);
    await _pump(tester, absences: absences.stream, settle: false);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Generate groups'), findsNothing);
    absences.add({7});
    await tester.pumpAndSettle();
    await _generate(tester);
    expect(_assignedIds(tester), isNot(contains(7)));
    absences.addError(StateError('Attendance unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Generate groups'), findsNothing);
    expect(find.text('Reshuffle groups'), findsNothing);
    expect(_assignedIds(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clears old groups when attendance or class membership changes', (
    tester,
  ) async {
    final students = StreamController<List<Student>>();
    final absences = StreamController<Set<int>>();
    addTearDown(students.close);
    addTearDown(absences.close);
    await _pump(
      tester,
      students: students.stream,
      absences: absences.stream,
      settle: false,
    );
    students.add(_roster);
    absences.add({7});
    await tester.pumpAndSettle();
    await _generate(tester);

    absences.add({1, 7});
    await tester.pumpAndSettle();
    expect(_assignedIds(tester), isEmpty);
    expect(
      find.text(
        'Attendance or the student list changed. Generate groups again.',
      ),
      findsOneWidget,
    );
    await _generate(tester);
    expect(_assignedIds(tester), unorderedEquals([2, 3, 4, 5, 6]));

    students.add(_roster.where((student) => student.id != 2).toList());
    await tester.pumpAndSettle();
    expect(_assignedIds(tester), isEmpty);
    await _generate(tester);
    expect(_assignedIds(tester), unorderedEquals([3, 4, 5, 6]));

    absences.add({1, 3, 4, 5, 6, 7});
    await tester.pumpAndSettle();
    expect(
      find.text('Everyone is marked absent for this lesson.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    students.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No students in this group yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'uses two columns on desktop and clears groups when size changes',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester);
      await _generate(tester);
      final first = tester.getTopLeft(find.text('Group 1'));
      final second = tester.getTopLeft(find.text('Group 2'));
      expect(first.dy, second.dy);
      expect(second.dx, greaterThan(first.dx));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7').last);
      await tester.pumpAndSettle();
      expect(_assignedIds(tester), isEmpty);
      await _generate(tester);
      expect(find.text('Group 1'), findsOneWidget);
      expect(find.text('Group 2'), findsNothing);
      expect(_assignedIds(tester), unorderedEquals([1, 2, 3, 4, 5, 6, 7]));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('supports German on a phone with just one present student', (
    tester,
  ) async {
    phone(tester);
    await _pump(
      tester,
      locale: const Locale('de'),
      absences: Stream.value({2, 3, 4, 5, 6, 7}),
    );
    expect(find.text('Schüler:innen pro Gruppe (maximal)'), findsOneWidget);
    expect(find.text('Anwesend: 1 · Gruppen: 1'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Gruppen bilden'));
    await tester.pumpAndSettle();
    expect(find.text('Gruppe 1'), findsOneWidget);
    expect(_assignedIds(tester), [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens from lesson mode using the selected lesson attendance', (
    tester,
  ) async {
    final database = AppDatabase.test(NativeDatabase.memory());
    addTearDown(database.close);
    late int groupId;
    late int ada;
    late int grace;
    late int alan;
    await tester.runAsync(() async {
      groupId = await GroupRepository(
        database,
      ).createGroup(name: 'Maths', gradeScale: defaultGradeScaleEntries);
      final students = StudentRepository(database);
      ada = await students.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'Lovelace',
      );
      grace = await students.addStudent(
        groupId: groupId,
        firstName: 'Grace',
        lastName: 'Hopper',
      );
      alan = await students.addStudent(
        groupId: groupId,
        firstName: 'Alan',
        lastName: 'Turing',
      );
      final attendance = AttendanceRepository(database);
      await attendance.markAbsent(studentId: ada, date: _date, periodStart: 1);
      await attendance.markAbsent(
        studentId: grace,
        date: _date,
        periodStart: 5,
      );
      await attendance.setExcused(
        studentId: grace,
        date: _date,
        periodStart: 5,
        excused: true,
      );
      await attendance.markLate(studentId: alan, date: _date, periodStart: 5);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          studentSortFieldProvider.overrideWith(
            (ref) => StudentSortField.firstName,
          ),
          bellTimesProvider.overrideWith((ref) async => {}),
        ],
        child: _localized(
          LessonModeScreen(
            groupId: groupId,
            initialDate: _date,
            initialSessionLabel: 'Topic',
            initialPeriods: (start: 5, end: 6),
          ),
          const Locale('en'),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Group builder'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Present: 2 · Groups: 1'), findsOneWidget);
    await _generate(tester);
    expect(_assignedIds(tester), unorderedEquals([ada, alan]));
    expect(_assignedIds(tester), isNot(contains(grace)));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
