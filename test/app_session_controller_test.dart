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

  test('lock is idempotent: calling lock twice does not double-lock', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();

    expect(controller.status, AppSessionStatus.ready);

    // Simulate concurrent background events by calling handleAppBackgrounded
    // twice without awaiting the first call.
    final first = controller.handleAppBackgrounded();
    final second = controller.handleAppBackgrounded();
    await Future.wait([first, second]);

    // The app must be locked exactly once; status should be locked.
    expect(controller.status, AppSessionStatus.locked);

    // After locking, the app can still be unlocked normally.
    final unlocked = await controller.unlock('test');
    expect(unlocked, isTrue);
    expect(controller.status, AppSessionStatus.ready);
  });

  test(
    'lock exports before transitioning to locked status',
    () async {
      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();

      expect(controller.status, AppSessionStatus.ready);

      // Start locking without awaiting – export starts synchronously.
      final lockFuture = controller.lock();
      expect(
        controller.isExporting,
        isTrue,
        reason: 'isExporting must be true while upload is in progress',
      );
      expect(
        controller.status,
        AppSessionStatus.ready,
        reason: 'status stays ready until upload completes',
      );
      await lockFuture;
      expect(controller.isExporting, isFalse);
      expect(controller.status, AppSessionStatus.locked);
    },
  );

  test('auto-export is skipped when WebDAV is not configured', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();

    await controller.lock();

    expect(controller.status, AppSessionStatus.locked);
    expect(
      controller.lastBackupMessageCode,
      isNull,
      reason: 'no backup message when WebDAV is not configured',
    );
  });

  test(
    'auto-export via handleAppBackgrounded is skipped when WebDAV is not configured',
    () async {
      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();

      await controller.setLockOnBackground(true);
      await controller.handleAppBackgrounded();

      expect(controller.status, AppSessionStatus.locked);
      expect(
        controller.lastBackupMessageCode,
        isNull,
        reason: 'no backup message when WebDAV is not configured',
      );
    },
  );

  test(
    'handleAppBackgrounded without lock flushes without error when WebDAV not configured',
    () async {
      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();

      await controller.setLockOnBackground(false);
      await controller.handleAppBackgrounded();

      expect(controller.status, AppSessionStatus.ready);
      expect(
        controller.lastBackupMessageCode,
        isNull,
        reason: 'no backup message when WebDAV is not configured',
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
