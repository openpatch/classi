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
    this.pendingRecoveryKeyValue,
    this.supportsRecoveryValue = false,
    this.currentDatabasePathValue = '/tmp/classi/test.classi',
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
  final String? pendingRecoveryKeyValue;
  final bool supportsRecoveryValue;
  final String currentDatabasePathValue;

  @override
  AppSessionStatus get status => statusValue;

  @override
  AppSessionErrorCode? get errorCode => errorCodeValue;

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
