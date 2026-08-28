import 'package:classi/features/schedule/weekly_timetable.dart';
import 'package:classi/features/schedule/weekly_timetable_providers.dart';
import 'package:classi/features/schedule/weekly_timetable_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

TimetableLesson _lesson({
  required int groupId,
  required String name,
  required int weekday,
  required int periodStart,
  required int periodEnd,
  required bool planned,
}) {
  return TimetableLesson(
    groupId: groupId,
    groupName: name,
    groupColorHex: '#FF1E88E5',
    date: DateTime(2026, 8, 24 + weekday - 1),
    weekday: weekday,
    periodStart: periodStart,
    periodEnd: periodEnd,
    categoryId: 'sonstige-mitarbeit',
    categoryName: 'Sonstige Mitarbeit',
    planned: planned,
  );
}

Future<void> _pumpScreen(WidgetTester tester, WeeklyTimetable timetable) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      fallbackLocale: const Locale('en'),
      path: 'assets/translations',
      child: ProviderScope(
        overrides: [
          weeklyTimetableProvider.overrideWith(
            (ref, arg) => AsyncData(timetable),
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const WeeklyTimetableScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('renders the grid and offers to plan an unplanned lesson', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      WeeklyTimetable(
        weekStart: DateTime(2026, 8, 24),
        weekdays: const [1, 2, 3, 4, 5],
        periodCount: 6,
        lessons: [
          _lesson(
            groupId: 1,
            name: 'Alpha',
            weekday: DateTime.monday,
            periodStart: 1,
            periodEnd: 2,
            planned: true,
          ),
          _lesson(
            groupId: 2,
            name: 'Beta',
            weekday: DateTime.wednesday,
            periodStart: 3,
            periodEnd: 4,
            planned: false,
          ),
        ],
      ),
    );

    expect(find.text('Timetable'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.textContaining('not planned yet'), findsOneWidget);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(find.text('Plan this lesson?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Plan this lesson?'), findsNothing);
  });
}
