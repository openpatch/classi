import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/core/security/biometric_service.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/security/security_preferences_service.dart';
import 'package:classi/core/session/app_session_controller.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/core/storage/library_backup_preferences_service.dart';
import 'package:classi/core/storage/library_backup_service.dart';
import 'package:classi/features/setup/webdav_restore_flow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'restore from WebDAV prompts for credentials when none are saved',
    (tester) async {
      final session = _FakeRestoreSessionController();

      await tester.pumpWidget(_buildTestApp(session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open-database-picker')));
      await tester.pumpAndSettle();

      expect(find.text('WebDAV URL'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        'https://example.invalid/remote.php/dav/files/test',
      );
      await tester.pump();

      final saveButtonFinder = find.widgetWithText(FilledButton, 'Save');
      final saveButton = tester.widget<FilledButton>(saveButtonFinder);
      expect(saveButton.onPressed, isNotNull);
      saveButton.onPressed!();
      await tester.pumpAndSettle();

      expect(
        session.savedUrl,
        'https://example.invalid/remote.php/dav/files/test',
      );
      expect(find.text('Choose a WebDAV backup'), findsOneWidget);
      expect(find.text('Class 8A'), findsOneWidget);
    },
  );
}

Widget _buildTestApp(AppSessionController session) {
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
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return Center(
                  child: FilledButton(
                    key: const Key('open-database-picker'),
                    onPressed: () =>
                        showWebDavBackupPicker(context: context, ref: ref),
                    child: const Text('Open picker'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _FakeRestoreSessionController extends AppSessionController {
  _FakeRestoreSessionController()
    : super(
        keyService: KeyService(),
        databasePathService: DatabasePathService(),
        securityPreferencesService: SecurityPreferencesService(),
        libraryBackupPreferencesService: LibraryBackupPreferencesService(),
        libraryBackupService: LibraryBackupService(),
        biometricService: BiometricService(),
      );

  String? savedUrl;
  String? savedUsername;
  String? savedPassword;
  String? savedServerPath;

  @override
  bool get isWebDavConfigured => savedUrl != null && savedUrl!.isNotEmpty;

  @override
  String? get webDavUrl => savedUrl;

  @override
  String? get webDavUsername => savedUsername;

  @override
  String? get webDavServerPath => savedServerPath;

  @override
  Future<String> currentDatabasePath() async => '/tmp/current.classi';

  @override
  Future<void> setWebDavUrl(String? url) async {
    savedUrl = url;
    notifyListeners();
  }

  @override
  Future<void> setWebDavUsername(String? username) async {
    savedUsername = username;
    notifyListeners();
  }

  @override
  Future<void> setWebDavPassword(String? password) async {
    savedPassword = password;
  }

  @override
  Future<void> setWebDavServerPath(String? path) async {
    savedServerPath = path;
    notifyListeners();
  }

  @override
  Future<List<WebDavBackupEntry>> listWebDavBackups() async {
    return const [
      WebDavBackupEntry(
        fileName: 'class-8a.classi-backup',
        libraryName: 'Class 8A',
        remotePath: '/backups/class-8a.classi-backup',
      ),
    ];
  }
}
