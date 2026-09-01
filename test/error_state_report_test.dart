import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/shared/widgets/app_error_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('error states offer a report only when the failure is known', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppErrorState()));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.text('Report error'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _wrap(
        AppErrorState(
          error: StateError('group load failed'),
          stackTrace: StackTrace.fromString('#0 frame (file.dart:1:2)'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report error'), findsOneWidget);
    expect(find.text('Copy details'), findsOneWidget);
    // Inline states stay compact: no expandable stack trace.
    expect(find.text('Technical details'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _wrap(
        AppErrorScaffold(
          error: StateError('group load failed'),
          stackTrace: StackTrace.fromString('#0 frame (file.dart:1:2)'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Technical details'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _wrap(
        AppErrorText(
          error: StateError('list load failed'),
          stackTrace: StackTrace.fromString('#0 frame (file.dart:1:2)'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Report error'), findsOneWidget);
  });
}

Widget _wrap(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('de')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: Scaffold(body: child),
      ),
    ),
  );
}
