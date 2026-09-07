import 'dart:async';

import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/core/storage/project_settings_store.dart';
import 'package:classi/features/lessons/lesson_support.dart';
import 'package:classi/features/lessons/student_picker/spinning_wheel.dart';
import 'package:classi/features/lessons/student_picker/student_picker_sheet.dart';
import 'package:classi/features/students/student_sorting.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory stand-in for the library settings sidecar.
class _InMemorySettingsStore implements ProjectSettingsStore {
  Map<String, dynamic> _settings = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> read() async =>
      Map<String, dynamic>.from(_settings);

  @override
  Future<void> write(Map<String, dynamic> settings) async {
    _settings = settings;
  }

  @override
  Future<void> update(
    Map<String, dynamic> Function(Map<String, dynamic> current) transform,
  ) async {
    await write(transform(await read()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  const groupId = 1;
  final date = DateTime(2025, 3, 14);

  Student student(int id, String firstName, String lastName) => Student(
    id: id,
    firstName: firstName,
    lastName: lastName,
    groupId: groupId,
    createdAt: date,
    updatedAt: date,
  );

  final ada = student(1, 'Ada', 'Lovelace');
  final grace = student(2, 'Grace', 'Hopper');
  final alan = student(3, 'Alan', 'Turing');
  final roster = [ada, grace, alan];

  String nameOf(Student value) => studentDisplayName(
    firstName: value.firstName,
    lastName: value.lastName,
    sortField: StudentSortField.firstName,
  );

  // Only the first EasyLocalization of a test file renders its translations,
  // so the picker is mounted once and driven through its states from there.
  testWidgets('picks a present student, giving everyone a turn', (
    tester,
  ) async {
    final view = tester.view;
    // The picker is a tall column; give it room so nothing is off screen.
    view.physicalSize = const Size(1000, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    final absences = StreamController<Set<int>>.broadcast();
    addTearDown(absences.close);

    Future<void> setAbsent(Set<int> ids) async {
      absences.add(ids);
      await tester.pumpAndSettle();
    }

    /// The names currently on the wheel.
    List<String> wheelSegments() =>
        tester.widget<SpinningWheel>(find.byType(SpinningWheel)).segments;

    /// Spins once and returns the name shown on the result card.
    Future<String> spin() async {
      final button = find.widgetWithText(FilledButton, 'Spin');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final card = find.ancestor(
        of: find.text('Selected'),
        matching: find.byType(Card),
      );
      // The card holds the avatar initials, the 'Selected' label, and last the
      // name of the student the wheel landed on.
      return tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .whereType<String>()
          .where((label) => label != 'Selected')
          .last;
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSettingsStoreProvider.overrideWithValue(
            _InMemorySettingsStore(),
          ),
          studentSortFieldProvider.overrideWith(
            (ref) => StudentSortField.firstName,
          ),
          lessonStudentsProvider(
            groupId,
          ).overrideWith((ref) => Stream.value(roster)),
          lessonAbsenceSelectionsProvider((
            groupId,
            date,
          )).overrideWith((ref) => absences.stream),
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
              home: StudentPickerSheet(groupId: groupId, date: date),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Absent students stay off the wheel.
    await setAbsent({alan.id});
    expect(find.text('Not on the wheel: 1 absent'), findsOneWidget);
    expect(wheelSegments(), isNot(contains(nameOf(alan))));
    for (var i = 0; i < 5; i++) {
      expect(await spin(), isNot(nameOf(alan)));
    }

    // With the lesson memory on, everyone gets a turn before anyone repeats.
    await setAbsent(const {});
    await tester.tap(find.text('Lesson'));
    await tester.pumpAndSettle();

    final picked = <String>{};
    for (var i = 0; i < roster.length; i++) {
      picked.add(await spin());
      expect(find.text('${i + 1} of 3 picked'), findsOneWidget);
      // The winner stays on the wheel of the round it was drawn in.
      expect(wheelSegments(), contains(picked.last));
    }
    expect(picked, {nameOf(ada), nameOf(grace), nameOf(alan)});

    // The round is complete, so the next spin opens a fresh one.
    await spin();
    expect(find.text('1 of 3 picked'), findsOneWidget);

    // Resetting the memory puts everyone back on the wheel, once confirmed.
    Future<void> tapReset() async {
      final reset = find.widgetWithText(TextButton, 'Reset memory');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
    }

    await tapReset();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    // Cancelling leaves the round that is under way untouched.
    expect(find.text('1 of 3 picked'), findsOneWidget);

    await tapReset();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 picked'), findsOneWidget);
    expect(wheelSegments(), hasLength(roster.length));

    // Nobody to pick from at all.
    await setAbsent({for (final value in roster) value.id});
    expect(
      find.text('Everyone is marked absent for this lesson.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });
}
