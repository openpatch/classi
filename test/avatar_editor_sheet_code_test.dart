import 'dart:convert';

import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/avatar/avatar_editor_sheet.dart';
import 'package:classi/shared/avatar/avatar_code.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('rejects a bad code, then applies and saves a good one', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(1200, 2600);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    String? saved;
    final code = AvatarCode.encode(
      '{"HairColor":"Blonde","SkinColor":"Black"}',
    );

    await tester.pumpWidget(
      _harness(
        onOpen: (context) => showAvatarEditorSheet(
          context: context,
          student: Student(
            id: 1,
            firstName: 'Grace',
            lastName: 'Hopper',
            groupId: 1,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
          onSave: (avatarJson) async => saved = avatarJson,
        ),
      ),
    );
    await _openSheet(tester);

    // Open the code dialog and reject an invalid code.
    await tester.tap(find.byTooltip('Enter code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'NOT-A-CODE');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('This code is not valid.'), findsOneWidget);
    expect(saved, isNull);

    // Replace it with a valid code.
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Avatar loaded from code'), findsAtLeastNWidgets(1));

    // Let the SnackBar clear so it no longer covers the Save button.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    final map = (jsonDecode(saved!) as Map).cast<String, dynamic>();
    expect(map['HairColor'], 'Blonde');
    expect(map['SkinColor'], 'Black');
    expect(map.length, 13);
  });
}

Future<void> _openSheet(WidgetTester tester) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('open').evaluate().isNotEmpty) break;
  }
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Widget _harness({required Future<void> Function(BuildContext) onOpen}) {
  return ProviderScope(
    child: EasyLocalization(
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
    ),
  );
}
