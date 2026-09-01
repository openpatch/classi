import 'package:flutter_test/flutter_test.dart';

import 'package:classi/shared/widgets/app_error_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an error report carries the message, exception and stack trace',
      () async {
    final report = ErrorReport(
      message: 'Something went wrong.',
      operation: 'open the library',
      error: StateError('boom'),
      stackTrace: StackTrace.fromString('#0 someFrame (file.dart:1:2)'),
      occurredAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    );

    final text = await buildErrorReportText(report);

    expect(text, contains('Something went wrong.'));
    expect(text, contains('Operation: open the library'));
    expect(text, contains('boom'));
    expect(text, contains('#0 someFrame (file.dart:1:2)'));
    expect(text, contains('2026-01-02T03:04:05'));
    expect(text, contains('App: classi'));
    expect(text, contains('Platform: '));
  });

  test('a report without an exception still describes the environment',
      () async {
    final text = await buildErrorReportText(
      const ErrorReport(message: 'Something went wrong.'),
    );

    expect(text, contains('Something went wrong.'));
    expect(text, isNot(contains('Exception:')));
    expect(text, isNot(contains('Stack trace:')));
    expect(text, contains('App: classi'));
  });
}
