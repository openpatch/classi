import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/core/security/biometric_service.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/security/security_preferences_service.dart';
import 'package:classi/core/session/app_session_controller.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/core/storage/library_backup_preferences_service.dart';
import 'package:classi/core/storage/library_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late AppSessionController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp(
      'classi-session-controller',
    );
    controller = AppSessionController(
      keyService: KeyService(),
      databasePathService: _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      ),
      securityPreferencesService: SecurityPreferencesService(),
      libraryBackupPreferencesService: LibraryBackupPreferencesService(),
      libraryBackupService: LibraryBackupService(),
      biometricService: BiometricService(),
    );
  });

  tearDown(() async {
    controller.dispose();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('database can be unlocked again after locking', () async {
    await controller.initialize();

    expect(controller.status, AppSessionStatus.needsSetup);

    await controller.createDatabase('test');
    expect(controller.status, AppSessionStatus.ready);

    controller.clearPendingRecoveryKey();
    await controller.lock();
    expect(controller.status, AppSessionStatus.locked);

    final unlocked = await controller.unlock('test');

    expect(unlocked, isTrue);
    expect(controller.status, AppSessionStatus.ready);
    expect(controller.errorCode, isNull);
    expect(controller.errorMessage, isNull);
  });

  test(
    'invalid passphrase keeps the session locked with a typed error',
    () async {
      await controller.initialize();
      await controller.createDatabase('test');

      controller.clearPendingRecoveryKey();
      await controller.lock();

      final unlocked = await controller.unlock('wrong-passphrase');

      expect(unlocked, isFalse);
      expect(controller.status, AppSessionStatus.locked);
      expect(controller.errorCode, AppSessionErrorCode.invalidPassphrase);
      expect(
        controller.errorMessage,
        AppSessionErrorCode.invalidPassphrase.translationKey,
      );
    },
  );
}

class _TestDatabasePathService extends DatabasePathService {
  _TestDatabasePathService(this._databasePath);

  String _databasePath;

  @override
  Future<String> getCurrentDatabasePath() async => _databasePath;

  @override
  Future<void> setDatabaseFilePath(String databasePath) async {
    _databasePath = databasePath;
  }

  @override
  Future<String> defaultLibrariesDirectory() async =>
      Directory(_databasePath).parent.path;
}
