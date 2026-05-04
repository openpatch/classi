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
    'lock sets status to locked immediately before async cleanup',
    () async {
      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();

      expect(controller.status, AppSessionStatus.ready);

      // Start locking but do not await – the status should change synchronously.
      final lockFuture = controller.lock();
      expect(
        controller.status,
        AppSessionStatus.locked,
        reason: 'status must be locked before async cleanup completes',
      );
      await lockFuture;
      expect(controller.status, AppSessionStatus.locked);
    },
  );

  test('auto-export creates a backup file when the app is locked', () async {
    final backupDirectory = Directory('${tempDirectory.path}/backups');
    await backupDirectory.create();

    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();

    await controller.setAutoExportFolderPath(backupDirectory.path);
    await controller.setAutoExportEnabled(true);

    await controller.lock();

    expect(controller.status, AppSessionStatus.locked);
    expect(controller.lastBackupMessageCode, 'backup_exported');
    expect(controller.lastBackupMessageIsError, isFalse);

    final backupFiles = backupDirectory.listSync();
    expect(
      backupFiles.whereType<File>().any(
        (f) => f.path.endsWith('.classi-backup'),
      ),
      isTrue,
      reason: 'a .classi-backup file must be written to the backup folder',
    );
  });

  test(
    'auto-export is skipped when disabled, leaving no backup file',
    () async {
      final backupDirectory = Directory('${tempDirectory.path}/backups');
      await backupDirectory.create();

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();

      await controller.setAutoExportFolderPath(backupDirectory.path);
      await controller.setAutoExportEnabled(false);

      await controller.lock();

      expect(controller.status, AppSessionStatus.locked);
      expect(controller.lastBackupMessageCode, isNull);

      final backupFiles = backupDirectory.listSync();
      expect(
        backupFiles.whereType<File>().any(
          (f) => f.path.endsWith('.classi-backup'),
        ),
        isFalse,
        reason: 'no backup file should be created when auto-export is disabled',
      );
    },
  );

  test(
    'auto-export creates backup via handleAppBackgrounded when lock-on-background is enabled',
    () async {
      final backupDirectory = Directory('${tempDirectory.path}/backups');
      await backupDirectory.create();

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();

      await controller.setAutoExportFolderPath(backupDirectory.path);
      await controller.setAutoExportEnabled(true);
      await controller.setLockOnBackground(true);

      await controller.handleAppBackgrounded();

      expect(controller.status, AppSessionStatus.locked);
      expect(controller.lastBackupMessageCode, 'backup_exported');

      final backupFiles = backupDirectory.listSync();
      expect(
        backupFiles.whereType<File>().any(
          (f) => f.path.endsWith('.classi-backup'),
        ),
        isTrue,
        reason: 'backup must be created when app is locked on background',
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
