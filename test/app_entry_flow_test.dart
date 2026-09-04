import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/core/security/biometric_service.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/security/security_preferences_service.dart';
import 'package:classi/core/session/app_session_controller.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/core/storage/library_backup_preferences_service.dart';
import 'package:classi/core/storage/library_backup_service.dart';
import 'package:classi/features/setup/recovery_key_screen.dart';
import 'package:classi/features/setup/setup_screen.dart';
import 'package:classi/features/setup/unlock_screen.dart';
import 'package:classi/shared/widgets/startup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'entry screens render localized setup, unlock, recovery, and error states',
    (tester) async {
      await tester.pumpWidget(
        _buildTestScreen(
          session: _FakeAppSessionController(
            statusValue: AppSessionStatus.needsSetup,
          ),
          child: const SetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Classi'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _buildTestScreen(
          session: _FakeAppSessionController(
            statusValue: AppSessionStatus.locked,
            errorCodeValue: AppSessionErrorCode.invalidPassphrase,
            supportsRecoveryValue: true,
            currentDatabasePathValue: '/tmp/classi/test.classi',
          ),
          child: const UnlockScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unlock Classi'), findsOneWidget);
      expect(find.text('/tmp/classi/test.classi'), findsOneWidget);
      expect(find.text('Use recovery key'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _buildTestScreen(
          session: _FakeAppSessionController(
            statusValue: AppSessionStatus.ready,
            pendingRecoveryKeyValue: 'ABCD-EFGH-IJKL',
          ),
          child: const RecoveryKeyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save your recovery key'), findsOneWidget);
      expect(find.text('ABCD-EFGH-IJKL'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _buildTestScreen(
          session: _FakeAppSessionController(
            statusValue: AppSessionStatus.error,
            errorCodeValue: AppSessionErrorCode.errorLoadingDatabase,
          ),
          child: const StartupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Classi could not open the encrypted library.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Report error'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _buildTestScreen(
          session: _FakeAppSessionController(
            statusValue: AppSessionStatus.error,
            errorCodeValue: AppSessionErrorCode.errorLoadingDatabase,
            errorDetailsValue: AppSessionErrorDetails(
              operation: 'initialize session',
              error: StateError('library missing'),
              stackTrace: StackTrace.fromString('#0 frame (file.dart:1:2)'),
              occurredAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
            ),
          ),
          child: const StartupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report error'), findsOneWidget);
      expect(find.text('Copy details'), findsOneWidget);

      await tester.tap(find.text('Technical details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('library missing'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // A conflict cannot be resolved from the unlock screen — keeping this
      // device's version exports the live database, which needs the library
      // open — so the status must not repeat the app shell's "tap to
      // resolve", which is only true where the same status is a button.
      await tester.pumpWidget(
        _buildTestScreen(
          session: _FakeAppSessionController(
            statusValue: AppSessionStatus.locked,
            currentDatabasePathValue: '/tmp/classi/test.classi',
            isWebDavConfiguredValue: true,
            webDavSyncStatusValue: WebDavSyncStatus.conflict,
          ),
          child: const UnlockScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Sync conflict — two devices changed this library. '
          'Unlock it to resolve.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Sync conflict — two devices changed this library. Tap to resolve.',
        ),
        findsNothing,
        reason: 'nothing on the unlock screen resolves a conflict',
      );
    },
  );
}


Widget _buildTestScreen({
  required AppSessionController session,
  required Widget child,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('de')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    child: ProviderScope(
      overrides: [appSessionProvider.overrideWith((ref) => session)],
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: child,
        ),
      ),
    ),
  );
}

class _FakeAppSessionController extends AppSessionController {
  _FakeAppSessionController({
    required this.statusValue,
    this.errorCodeValue,
    this.errorDetailsValue,
    this.pendingRecoveryKeyValue,
    this.supportsRecoveryValue = false,
    this.currentDatabasePathValue = '/tmp/classi/test.classi',
    this.webDavSyncStatusValue = WebDavSyncStatus.notConfigured,
    this.isWebDavConfiguredValue = false,
  }) : super(
         keyService: KeyService(),
         databasePathService: DatabasePathService(),
         securityPreferencesService: SecurityPreferencesService(),
         libraryBackupPreferencesService: LibraryBackupPreferencesService(),
         libraryBackupService: LibraryBackupService(),
         biometricService: BiometricService(),
       );

  final AppSessionStatus statusValue;
  final AppSessionErrorCode? errorCodeValue;
  final AppSessionErrorDetails? errorDetailsValue;
  final String? pendingRecoveryKeyValue;
  final bool supportsRecoveryValue;
  final String currentDatabasePathValue;
  final WebDavSyncStatus webDavSyncStatusValue;
  final bool isWebDavConfiguredValue;

  @override
  WebDavSyncStatus get webDavSyncStatus => webDavSyncStatusValue;

  @override
  bool get isWebDavConfigured => isWebDavConfiguredValue;

  @override
  AppSessionStatus get status => statusValue;

  @override
  AppSessionErrorCode? get errorCode => errorCodeValue;

  @override
  AppSessionErrorDetails? get errorDetails => errorDetailsValue;

  @override
  String? get errorMessage => errorCodeValue?.translationKey;

  @override
  String? get pendingRecoveryKey => pendingRecoveryKeyValue;

  @override
  bool get hasPendingRecoveryKey => pendingRecoveryKeyValue != null;

  @override
  Future<String> currentDatabasePath() async => currentDatabasePathValue;

  @override
  Future<bool> supportsRecovery() async => supportsRecoveryValue;
}
