import 'package:classi/features/groups/group_form.dart';
import 'package:classi/features/settings/grade_system_controller.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:classi/shared/utils/grade_categories.dart';
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

  testWidgets('puts a category under another one', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(1000, 3000);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    GroupFormResult? result;
    await tester.pumpWidget(
      EasyLocalization(
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
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await showGroupFormSheet(
                      context: context,
                      gradeSystems: const [
                        GradeSystemDefinition(
                          id: 'default-1-6',
                          name: '1–6',
                          entries: defaultGradeScaleEntries,
                        ),
                      ],
                      schoolYears: const [],
                      initialName: '10A',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The defaults are Sonstige Mitarbeit, Klassenarbeit, Präsentation; file
    // Präsentation under Sonstige Mitarbeit.
    expect(find.text('Belongs to'), findsNWidgets(3));
    await tester.tap(find.text('Nothing (top level)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sonstige Mitarbeit').last);
    await tester.pumpAndSettle();

    // A category others belong to cannot be filed under another one.
    expect(
      find.text(
        'Other categories belong to this one, so it stays at the top level.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result!.gradeCategories.map((c) => (c.id, c.parentId)), [
      ('sonstige-mitarbeit', null),
      ('klassenarbeit', null),
      ('praesentation', 'sonstige-mitarbeit'),
    ]);
    expect(gradableCategories(result!.gradeCategories).map((c) => c.id), [
      'klassenarbeit',
      'praesentation',
    ]);
  });
}
