import 'package:classi/features/schedule/lesson_schedule.dart';
import 'package:classi/features/schedule/lesson_schedule_editor_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('applying a detected pattern updates the visible dropdowns', (
    tester,
  ) async {
    List<LessonSlotDraft>? saved;

    await tester.pumpWidget(
      _harness(
        onOpen: (context) async {
          saved = await showLessonScheduleEditorSheet(
            context: context,
            gradeCategories: const [],
            initialSlots: const [],
            suggestedSlots: const [
              LessonSlotDraft(
                weekday: DateTime.monday,
                periodStart: 1,
                periodEnd: 2,
                categoryId: 'sonstige-mitarbeit',
              ),
              LessonSlotDraft(
                weekday: DateTime.friday,
                periodStart: 3,
                periodEnd: 4,
                categoryId: 'sonstige-mitarbeit',
              ),
            ],
          );
        },
      ),
    );

    await _openSheet(tester);

    // The suggestion is offered before anything is in the editor.
    expect(find.text('Detected pattern'), findsOneWidget);

    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();

    // Both rows must render the applied values, not the state they were
    // seeded with — the periods 1, 2, 3 and 4 each appear once.
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    for (final period in ['1', '2', '3', '4']) {
      expect(
        find.text(period),
        findsOneWidget,
        reason: 'period $period should be selected in exactly one dropdown',
      );
    }

    // A slot added by hand shows up, and removing it takes it away again.
    // The new slot takes the first free weekday, Tuesday, so it sorts into
    // the middle of the timetable rather than onto the end.
    await tester.tap(find.text('Add slot'));
    await tester.pumpAndSettle();
    expect(find.text('Weekday'), findsNWidgets(3));
    expect(find.text('Tuesday'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Weekday'), findsNWidgets(2));
    expect(find.text('Tuesday'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(2));
    expect(saved!.first.weekday, DateTime.monday);
    expect(saved!.first.periodStart, 1);
    expect(saved!.first.periodEnd, 2);
    expect(saved!.last.weekday, DateTime.friday);
    expect(saved!.last.periodStart, 3);
    expect(saved!.last.periodEnd, 4);
  });
}

/// Pumps until EasyLocalization has loaded its translations, then opens the
/// sheet. The load resolves off the frame loop, so a single settle can land
/// before the tree carries the button.
Future<void> _openSheet(WidgetTester tester) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('open').evaluate().isNotEmpty) break;
  }
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Widget _harness({required Future<void> Function(BuildContext) onOpen}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: Scaffold(
          body: Builder(
            builder: (innerContext) => Center(
              child: TextButton(
                onPressed: () => onOpen(innerContext),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
