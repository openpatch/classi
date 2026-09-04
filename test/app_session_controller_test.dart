import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/core/security/biometric_service.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/security/security_preferences_service.dart';
import 'package:classi/core/session/app_session_controller.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/core/storage/library_backup_preferences_service.dart';
import 'package:classi/core/storage/library_backup_service.dart';
import 'package:classi/core/storage/project_settings_store.dart';
import 'package:classi/shared/utils/formatting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late AppSessionController controller;
  late LibraryBackupService backupService;
  late KeyService keyService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp(
      'classi-session-controller',
    );
    backupService = LibraryBackupService();
    keyService = _TestKeyService();
    final databasePathService = _TestDatabasePathService(
      '${tempDirectory.path}/test.classi',
    );
    controller = AppSessionController(
      keyService: keyService,
      databasePathService: databasePathService,
      securityPreferencesService: _securityPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupService: backupService,
      biometricService: BiometricService(),
    );
  });

  tearDown(() async {
    controller.dispose();
    if (await tempDirectory.exists()) {
      try {
        await tempDirectory.delete(recursive: true);
      } on PathNotFoundException {
        // Another async cleanup already removed the temp directory.
      }
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

  test(
    'a fatal startup failure keeps the underlying error for a report',
    () async {
      final failing = AppSessionController(
        keyService: keyService,
        databasePathService: _FailingDatabasePathService(),
        securityPreferencesService: _securityPreferencesServiceFor(
          _TestDatabasePathService('${tempDirectory.path}/unused.classi'),
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          _TestDatabasePathService('${tempDirectory.path}/unused.classi'),
        ),
        libraryBackupService: backupService,
        biometricService: BiometricService(),
      );
      addTearDown(failing.dispose);

      await failing.initialize();

      expect(failing.status, AppSessionStatus.error);
      expect(failing.errorCode, AppSessionErrorCode.errorLoadingDatabase);

      final details = failing.errorDetails;
      expect(details, isNotNull);
      expect(details!.operation, 'initialize session');
      expect('${details.error}', contains('no library path'));
      expect(details.stackTrace, isNotNull);
    },
  );

  test('lock is idempotent: calling lock twice does not double-lock', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();
    // No grace: this is about the lock itself, not about when it starts.
    await controller.setBackgroundLockGrace(Duration.zero);

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

  /// Rebuilds the session on a backup service that hangs mid-upload, so a
  /// test can look at the app while an export is in flight.
  Future<_DelayingLibraryBackupService> withHangingExport() async {
    final delayingBackupService = _DelayingLibraryBackupService();
    controller.dispose();
    final databasePathService = _TestDatabasePathService(
      '${tempDirectory.path}/test.classi',
    );
    controller = AppSessionController(
      keyService: keyService,
      databasePathService: databasePathService,
      securityPreferencesService: _securityPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupService: delayingBackupService,
      biometricService: BiometricService(),
    );
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();
    await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
    await controller.setWebDavAutoExportEnabled(true);
    return delayingBackupService;
  }

  test('a save the app starts by itself keeps the app usable', () async {
    final backup = await withHangingExport();
    await controller.setLockOnBackground(false);

    final backgrounded = controller.handleAppBackgrounded();
    await backup.started.future;

    expect(controller.isExporting, isTrue);
    expect(
      controller.isBlockingExport,
      isFalse,
      reason: 'a backup running on its own must not take the app away',
    );

    backup.finish.complete();
    await backgrounded;
    expect(controller.isExporting, isFalse);
  });

  test('an export the user asked for holds the app still', () async {
    final backup = await withHangingExport();

    final exporting = controller.exportNow();
    await backup.started.future;

    expect(controller.isBlockingExport, isTrue);

    backup.finish.complete();
    await exporting;
    expect(controller.isBlockingExport, isFalse);
  });

  test('a quick switch away does not lock the app', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();
    await controller.setLockOnBackground(true);
    await controller.setBackgroundLockGrace(const Duration(seconds: 30));

    await controller.handleAppBackgrounded();
    expect(
      controller.status,
      AppSessionStatus.ready,
      reason: 'looking something up in another app is not putting the phone '
          'down',
    );

    await controller.handleAppResumed();
    expect(controller.status, AppSessionStatus.ready);
  });

  test('staying away past the grace locks the app', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();
    await controller.setLockOnBackground(true);
    await controller.setBackgroundLockGrace(const Duration(hours: 1));

    await controller.handleAppBackgrounded();
    expect(controller.status, AppSessionStatus.ready);

    // A phone freezes the app while it is away, so the timer that would lock
    // it never runs: shortening the grace stands in for the hour passing, and
    // what has to catch it is the check on the way back in.
    await controller.setBackgroundLockGrace(Duration.zero);
    await controller.handleAppResumed();

    expect(controller.status, AppSessionStatus.locked);
  });

  test('without a grace the app locks the moment it goes away', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();
    await controller.setLockOnBackground(true);
    await controller.setBackgroundLockGrace(Duration.zero);

    await controller.handleAppBackgrounded();

    expect(controller.status, AppSessionStatus.locked);
  });

  test('lock keeps the database available until export finishes', () async {
    final delayingBackupService = _DelayingLibraryBackupService();
    controller.dispose();
    final databasePathService = _TestDatabasePathService(
      '${tempDirectory.path}/test.classi',
    );
    controller = AppSessionController(
      keyService: keyService,
      databasePathService: databasePathService,
      securityPreferencesService: _securityPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupService: delayingBackupService,
      biometricService: BiometricService(),
    );
    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();
    await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
    await controller.setWebDavAutoExportEnabled(true);

    expect(controller.status, AppSessionStatus.ready);

    final lockFuture = controller.lock();
    await delayingBackupService.started.future;

    expect(controller.isExporting, isTrue);
    expect(
      controller.status,
      AppSessionStatus.ready,
      reason: 'status stays ready until upload completes',
    );
    expect(
      controller.database,
      isNotNull,
      reason: 'the unlocked UI still depends on the current database',
    );

    delayingBackupService.finish.complete();
    await lockFuture;
    expect(controller.isExporting, isFalse);
    expect(controller.status, AppSessionStatus.locked);
    expect(controller.database, isNull);
  });

  test('lock switches to locked before database close completes', () async {
    controller.dispose();
    final databasePathService = _TestDatabasePathService(
      '${tempDirectory.path}/test.classi',
    );
    final delayedCloseController = _CloseDelayingAppSessionController(
      keyService: keyService,
      databasePathService: databasePathService,
      securityPreferencesService: _securityPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupService: backupService,
      biometricService: BiometricService(),
    );
    controller = delayedCloseController;

    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();

    var completed = false;
    final lockFuture = controller.lock().then((_) => completed = true);

    await delayedCloseController.closeStarted.future;

    expect(controller.status, AppSessionStatus.locked);
    expect(controller.isExporting, isFalse);
    expect(controller.database, isNull);
    expect(completed, isFalse);

    delayedCloseController.finishClose.complete();
    await lockFuture;

    expect(completed, isTrue);
    expect(controller.database, isNull);
  });

  test('unlock waits for pending post-lock cleanup', () async {
    controller.dispose();
    final databasePathService = _TestDatabasePathService(
      '${tempDirectory.path}/test.classi',
    );
    final delayedCloseController = _CloseDelayingAppSessionController(
      keyService: keyService,
      databasePathService: databasePathService,
      securityPreferencesService: _securityPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupService: backupService,
      biometricService: BiometricService(),
    );
    controller = delayedCloseController;

    await controller.initialize();
    await controller.createDatabase('test');
    controller.clearPendingRecoveryKey();

    final lockFuture = controller.lock();
    await delayedCloseController.closeStarted.future;

    var unlockCompleted = false;
    final unlockFuture = controller.unlock('test').then((value) {
      unlockCompleted = true;
      return value;
    });

    await Future<void>.delayed(Duration.zero);
    expect(unlockCompleted, isFalse);

    delayedCloseController.finishClose.complete();

    expect(await unlockFuture, isTrue);
    await lockFuture;
    expect(controller.status, AppSessionStatus.ready);
  });

  test(
    'restoreWebDavBackup restores a remote backup into a new library',
    () async {
      final sourceLibraryDirectory = Directory(
        '${tempDirectory.path}/source.classi',
      );
      await sourceLibraryDirectory.create(recursive: true);
      await File('${sourceLibraryDirectory.path}/data.db').writeAsString('db');
      await File(
        '${sourceLibraryDirectory.path}/data.db-wal',
      ).writeAsString('wal');
      await File(
        '${sourceLibraryDirectory.path}/data.db-shm',
      ).writeAsString('shm');
      await File(
        '${sourceLibraryDirectory.path}/data.db.security.json',
      ).writeAsString('security');
      await File(
        '${sourceLibraryDirectory.path}/data.db.integrity.json',
      ).writeAsString('integrity');

      final archiveBytes = await LibraryBackupService().buildBackupArchive(
        sourceLibraryDirectory.path,
      );
      final restoreService = _RestoringLibraryBackupService(archiveBytes);
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/blank.classi',
      );
      controller = _RestoringAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: restoreService,
        biometricService: BiometricService(),
      );

      await controller.initialize();

      final destinationPath = '${tempDirectory.path}/restored.classi';
      final errorCode = await controller.restoreWebDavBackup(
        remotePath: '/backups/remote.classi-backup',
        destinationPath: destinationPath,
      );

      expect(errorCode, isNull);
      expect(restoreService.lastRemotePath, '/backups/remote.classi-backup');
      expect(controller.status, AppSessionStatus.locked);
      expect(await controller.currentDatabasePath(), destinationPath);
      expect(await File('$destinationPath/data.db').readAsString(), 'db');
      expect(
        await File('$destinationPath/data.db.security.json').readAsString(),
        'security',
      );
    },
  );

  test(
    'restoring a backup adopts its revision as the local sync baseline',
    () async {
      final sourceLibraryDirectory = Directory(
        '${tempDirectory.path}/revision-source.classi',
      );
      await sourceLibraryDirectory.create(recursive: true);
      await File('${sourceLibraryDirectory.path}/data.db').writeAsString('db');
      await File(
        '${sourceLibraryDirectory.path}/data.db.security.json',
      ).writeAsString('security');

      final archiveBytes = await LibraryBackupService().buildBackupArchive(
        sourceLibraryDirectory.path,
        revision: 'remote-revision-42',
      );
      final restoreService = _RestoringLibraryBackupService(archiveBytes);
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/blank2.classi',
      );
      controller = _RestoringAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: restoreService,
        biometricService: BiometricService(),
      );

      await controller.initialize();

      final destinationPath = '${tempDirectory.path}/revision-restored.classi';
      final errorCode = await controller.restoreWebDavBackup(
        remotePath: '/backups/remote.classi-backup',
        destinationPath: destinationPath,
      );

      expect(errorCode, isNull);
      expect(controller.lastKnownRevision, 'remote-revision-42');
    },
  );

  test(
    'restoring into the currently open library does not let a pre-restore '
    'auto-export clobber the remote backup being restored',
    () async {
      final remoteLibraryDirectory = Directory(
        '${tempDirectory.path}/remote-source.classi',
      );
      await remoteLibraryDirectory.create(recursive: true);
      await File(
        '${remoteLibraryDirectory.path}/data.db',
      ).writeAsString('remote-db');
      await File(
        '${remoteLibraryDirectory.path}/data.db.security.json',
      ).writeAsString('remote-security');
      await File(
        '${remoteLibraryDirectory.path}/data.db.integrity.json',
      ).writeAsString('remote-integrity');

      final archiveBytes = await LibraryBackupService().buildBackupArchive(
        remoteLibraryDirectory.path,
      );
      final restoreService = _RestoringSelfLibraryBackupService(archiveBytes);
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _RestoringAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: restoreService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      final currentPath = await controller.currentDatabasePath();
      final errorCode = await controller.restoreWebDavBackup(
        remotePath: '/backups/test.classi-backup',
        destinationPath: currentPath,
        createNew: false,
      );

      expect(errorCode, isNull);
      expect(
        restoreService.exportCalled,
        isFalse,
        reason:
            'auto-export must not run before restoring into the currently '
            'open library, or it uploads stale local state over the exact '
            'remote backup being restored',
      );
      expect(
        await File('$currentPath/data.db').readAsString(),
        'remote-db',
        reason:
            'the restored data must be the remote backup, not a '
            're-uploaded local copy',
      );
    },
  );

  test(
    'taking the server version archives the conflict copy in the same call',
    () async {
      final remoteLibraryDirectory = Directory(
        '${tempDirectory.path}/remote-conflict.classi',
      );
      await remoteLibraryDirectory.create(recursive: true);
      await File(
        '${remoteLibraryDirectory.path}/data.db',
      ).writeAsString('server-db');
      await File(
        '${remoteLibraryDirectory.path}/data.db.security.json',
      ).writeAsString('server-security');
      await File(
        '${remoteLibraryDirectory.path}/data.db.integrity.json',
      ).writeAsString('server-integrity');

      final archiveBytes = await LibraryBackupService().buildBackupArchive(
        remoteLibraryDirectory.path,
      );
      final restoreService = _RestoringSelfLibraryBackupService(archiveBytes);
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _RestoringAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: restoreService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      final currentPath = await controller.currentDatabasePath();
      final errorCode = await controller.useServerVersionAfterConflict(
        canonicalRemotePath: '/backups/test.classi-backup',
        conflictFileName: 'test_CONFLICT_device-a.classi-backup',
      );

      expect(errorCode, isNull);
      expect(
        await File('$currentPath/data.db').readAsString(),
        'server-db',
      );
      // Restoring the open library locks the session, which tears down the
      // conflict screen. If archiving the copy were left to the caller it
      // would never happen, and every device would keep reporting the
      // conflict the teacher just resolved.
      expect(
        restoreService.archivedConflictName,
        'test_CONFLICT_device-a.classi-backup',
      );
      expect(controller.hasPendingSyncConflict, isFalse);
      expect(controller.webDavSyncStatus, isNot(WebDavSyncStatus.conflict));
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
      // Straight to the lock, so the export this test is about runs here
      // rather than after a grace period.
      await controller.setBackgroundLockGrace(Duration.zero);
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

  test(
    'manual export does not flag the same remote backup as newer on restart',
    () async {
      final exportService = _ExportingLibraryBackupService(
        exportedAt: DateTime.utc(2026, 5, 7, 8, 0),
        remoteModifiedAt: DateTime.utc(2026, 5, 7, 8, 1),
      );
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);
      await controller.setWebDavAutoImportEnabled(true);

      expect(await controller.exportNow(), isNull);
      expect(controller.hasPendingAutoImport, isFalse);

      controller.dispose();
      final reloadedPathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: reloadedPathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          reloadedPathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          reloadedPathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
      );

      await controller.initialize();

      expect(controller.hasPendingAutoImport, isFalse);
      expect(controller.pendingImportRemoteModifiedAt, isNull);
    },
  );

  test('auto-export uploads this device\'s identity with the backup', () async {
    final exportService = _DeviceCapturingLibraryBackupService();
    controller.dispose();
    final databasePathService = _TestDatabasePathService(
      '${tempDirectory.path}/test.classi',
    );
    controller = _WebDavAppSessionController(
      keyService: keyService,
      databasePathService: databasePathService,
      securityPreferencesService: _securityPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
        databasePathService,
      ),
      libraryBackupService: exportService,
      biometricService: BiometricService(),
    );

    await controller.initialize();
    await controller.createDatabase('test');
    await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
    await controller.setWebDavAutoExportEnabled(true);

    expect(await controller.exportNow(), isNull);

    expect(exportService.lastDeviceId, isNotNull);
    expect(exportService.lastDeviceId, isNotEmpty);
    expect(exportService.lastDeviceName, isNotEmpty);
  });

  test(
    'a pending auto-import surfaces the uploading device\'s name',
    () async {
      final backupService = _PendingImportDeviceLibraryBackupService(
        remoteModifiedAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        deviceName: 'Kitchen iPad',
      );
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: backupService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoImportEnabled(true);

      expect(controller.hasPendingAutoImport, isTrue);
      expect(controller.pendingImportDeviceName, 'Kitchen iPad');
    },
  );

  test(
    'a remote revision matching the device\'s last known revision reports '
    'current even when the server mTime is newer',
    () async {
      // First, export to establish a lastKnownRevision on the device.
      final exportService = _ExportingLibraryBackupService(
        exportedAt: DateTime.utc(2026, 5, 7, 8, 0),
        remoteModifiedAt: DateTime.utc(2026, 5, 7, 8, 0),
      );
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);
      await controller.setWebDavAutoImportEnabled(true);

      expect(await controller.exportNow(), isNull);
      // The export set lastKnownRevision to 'revision-1'. The fake also
      // returns 'revision-1' for the remote, so the device is current.
      expect(controller.hasPendingAutoImport, isFalse);
      expect(controller.webDavSyncStatus, WebDavSyncStatus.current);
    },
  );

  test(
    'a remote revision differing from the device\'s last known revision '
    'reports behind',
    () async {
      // First, export to establish a lastKnownRevision of 'revision-1'.
      final exportService = _ExportingLibraryBackupService(
        exportedAt: DateTime.utc(2026, 5, 7, 8, 0),
        remoteModifiedAt: DateTime.utc(2026, 5, 7, 8, 0),
      );
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);
      await controller.setWebDavAutoImportEnabled(true);

      expect(await controller.exportNow(), isNull);
      expect(controller.lastKnownRevision, 'revision-1');

      // Now switch to a fake that returns a different remote revision.
      final behindService = _RevisionBehindLibraryBackupService(
        remoteRevision: 'revision-2',
        remoteModifiedAt: DateTime.utc(2026, 5, 7, 9, 0),
        deviceName: 'Classroom iPad',
      );
      controller.dispose();
      final reloadPathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: reloadPathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          reloadPathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          reloadPathService,
        ),
        libraryBackupService: behindService,
        biometricService: BiometricService(),
      );

      await controller.initialize();

      expect(controller.hasPendingAutoImport, isTrue);
      expect(controller.webDavSyncStatus, WebDavSyncStatus.behind);
      expect(controller.pendingImportDeviceName, 'Classroom iPad');
    },
  );

  test(
    'dismissing a pending import suppresses the prompt until a newer '
    'revision appears',
    () async {
      // First, export to establish a lastKnownRevision of 'revision-1'.
      final exportService = _ExportingLibraryBackupService(
        exportedAt: DateTime.utc(2026, 5, 7, 8, 0),
        remoteModifiedAt: DateTime.utc(2026, 5, 7, 8, 0),
      );
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);
      await controller.setWebDavAutoImportEnabled(true);

      expect(await controller.exportNow(), isNull);

      // Switch to a fake with a different remote revision.
      final behindService = _RevisionBehindLibraryBackupService(
        remoteRevision: 'revision-2',
        remoteModifiedAt: DateTime.utc(2026, 5, 7, 9, 0),
      );
      controller.dispose();
      final behindPathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: behindPathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          behindPathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          behindPathService,
        ),
        libraryBackupService: behindService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      expect(controller.hasPendingAutoImport, isTrue);

      await controller.dismissPendingImport();
      expect(controller.hasPendingAutoImport, isFalse);

      // Refresh: the same revision should stay dismissed.
      await controller.refreshWebDavSyncStatus();
      expect(
        controller.hasPendingAutoImport,
        isFalse,
        reason: 'the dismissed revision should suppress the prompt',
      );
      expect(controller.webDavSyncStatus, WebDavSyncStatus.current);

      // Now switch to a newer revision — the prompt should reappear.
      final newerService = _RevisionBehindLibraryBackupService(
        remoteRevision: 'revision-3',
        remoteModifiedAt: DateTime.utc(2026, 5, 7, 10, 0),
      );
      controller.dispose();
      final newerPathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: newerPathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          newerPathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          newerPathService,
        ),
        libraryBackupService: newerService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      expect(
        controller.hasPendingAutoImport,
        isTrue,
        reason: 'a newer revision should clear the dismissal',
      );
    },
  );

  test(
    'a transient export failure triggers a retry that succeeds',
    () async {
      final exportService = _RetryThenSucceedLibraryBackupService(
        failCount: 1,
      );
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
        periodicExportInterval: const Duration(minutes: 30),
        syncRetryDelays: const [Duration(milliseconds: 50)],
      );

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      // The first export fails with a busy exception.
      expect(await controller.exportNow(), isNull);
      expect(exportService.exportCalls, 1);
      expect(controller.lastBackupMessageCode, 'backup_export_busy');
      expect(controller.lastBackupMessageIsError, isTrue);

      // Wait for the retry timer to fire and the retry to succeed.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        exportService.exportCalls,
        2,
        reason: 'the retry should have triggered a second export attempt',
      );
      expect(
        controller.lastBackupMessageCode,
        'backup_exported',
        reason: 'the retry should have succeeded',
      );
    },
  );

  test(
    'exhausting the retry ladder does not switch retries off for good',
    () async {
      // Four failures in a row used to leave the attempt counter pinned at
      // its ceiling, so every later failure — however long afterwards —
      // reported "exhausted" and scheduled nothing at all.
      final exportService = _RetryThenSucceedLibraryBackupService(
        failCount: 2,
      );
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
        periodicExportInterval: const Duration(minutes: 30),
        // A single-rung ladder is exhausted after one retry.
        syncRetryDelays: const [Duration(milliseconds: 50)],
      );

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      // First failure schedules the only retry; that retry fails too and
      // exhausts the ladder.
      expect(await controller.exportNow(), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(exportService.exportCalls, 2);
      expect(controller.lastBackupMessageCode, 'backup_export_busy');

      // A later failure has to get its own retry, which now succeeds.
      exportService.failCount = 3;
      expect(await controller.exportNow(), isNull);
      expect(exportService.exportCalls, 3);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        exportService.exportCalls,
        4,
        reason: 'a failure after the ladder ran out should still be retried',
      );
      expect(controller.lastBackupMessageCode, 'backup_exported');
    },
  );

  test(
    'a periodic timer re-exports while the app stays open, independent of '
    'backgrounding',
    () async {
      final exportService = _DeviceCapturingLibraryBackupService();
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
        periodicExportInterval: const Duration(milliseconds: 20),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      expect(exportService.exportCount, 0);

      // Give the periodic timer a chance to fire at least once, without
      // backgrounding or locking the app.
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(
        exportService.exportCount,
        greaterThan(0),
        reason:
            'the periodic timer should trigger an export on its own, not '
            'just on background/lock',
      );
    },
  );

  test(
    'the periodic export timer stops once auto-export is disabled',
    () async {
      final exportService = _DeviceCapturingLibraryBackupService();
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
        periodicExportInterval: const Duration(milliseconds: 20),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      controller.clearPendingRecoveryKey();
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);
      await controller.setWebDavAutoExportEnabled(false);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(
        exportService.exportCount,
        0,
        reason: 'disabling auto-export must stop the periodic timer too',
      );
    },
  );

  test(
    'each export is based on the revision this device last saw',
    () async {
      final exportService = _DeviceCapturingLibraryBackupService();
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: exportService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      expect(await controller.exportNow(), isNull);
      expect(
        exportService.lastParentRevision,
        isNull,
        reason: 'first export for this device has nothing to build on',
      );

      expect(await controller.exportNow(), isNull);
      expect(
        exportService.lastParentRevision,
        'revision-1',
        reason:
            'the second export should be based on the revision recorded '
            'after the first export succeeded',
      );
    },
  );

  test(
    'a sync conflict is surfaced distinctly and does not update the local '
    'export bookkeeping',
    () async {
      final conflictService = _ConflictingLibraryBackupService();
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: conflictService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      final errorCode = await controller.exportNow();

      // exportNow() only returns non-null for a pre-flight check (e.g. not
      // configured); a failure during the export itself surfaces through
      // lastBackupMessageCode instead.
      expect(errorCode, isNull);
      expect(controller.lastBackupMessageCode, 'backup_export_conflict');
      expect(controller.lastBackupMessageIsError, isTrue);
      expect(controller.lastExportedAt, isNull);
    },
  );

  test(
    'the device that raised a conflict keeps reporting it instead of only '
    'flashing an error',
    () async {
      final conflictService = _ConflictingLibraryBackupService();
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: conflictService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      await controller.exportNow();

      // A conflict does not clear itself. Reporting it only through the
      // transient backup message left the teacher with an error that looked
      // like a failed upload, and nothing pointing at the resolution screen.
      expect(controller.hasPendingSyncConflict, isTrue);
      expect(controller.webDavSyncStatus, WebDavSyncStatus.conflict);
      expect(controller.pendingConflictDeviceName, 'Other Device');
    },
  );

  test(
    'the other device sees a conflict even though the canonical backup is '
    'still its own',
    () async {
      final parkedService = _ParkedConflictLibraryBackupService();
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: _libraryBackupPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupService: parkedService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoImportEnabled(true);

      await controller.refreshWebDavSyncStatus();

      // The canonical backup is old and unchanged, so every timestamp
      // comparison says "up to date" — the newer work is in the conflict
      // copy, which only this lookup can see.
      expect(parkedService.conflictLookups, greaterThan(0));
      expect(controller.webDavSyncStatus, WebDavSyncStatus.conflict);
      expect(controller.hasPendingSyncConflict, isTrue);
      expect(controller.pendingConflictDeviceName, 'Other Device');
      expect(
        controller.hasPendingAutoImport,
        isFalse,
        reason: 'a conflict needs resolving, not a blind import of one side',
      );
    },
  );

  test(
    'a failed keep-this-device resolution reports the failure and does not '
    'leave the remote revision adopted',
    () async {
      final conflictService = _ConflictingLibraryBackupService();
      controller.dispose();
      final databasePathService = _TestDatabasePathService(
        '${tempDirectory.path}/test.classi',
      );
      final backupPreferences = _libraryBackupPreferencesServiceFor(
        databasePathService,
      );
      controller = _WebDavAppSessionController(
        keyService: keyService,
        databasePathService: databasePathService,
        securityPreferencesService: _securityPreferencesServiceFor(
          databasePathService,
        ),
        libraryBackupPreferencesService: backupPreferences,
        libraryBackupService: conflictService,
        biometricService: BiometricService(),
      );

      await controller.initialize();
      await controller.createDatabase('test');
      await controller.setWebDavUrl('https://example.invalid/remote.php/dav');
      await controller.setWebDavAutoExportEnabled(true);

      final revisionBefore = controller.lastKnownRevision;

      final errorCode = await controller.keepThisDeviceVersionAfterConflict(
        canonicalRevision: 'server-revision',
      );

      // The upload never landed, so the caller has to hear about it —
      // otherwise the conflict screen tells the teacher it was resolved.
      expect(errorCode, isNotNull);
      expect(controller.lastExportedAt, isNull);

      // Adopting the server's revision is only licensed by a successful
      // export. Left in place after a failure, the next auto-export would
      // overwrite the server copy without ever prompting again.
      expect(controller.lastKnownRevision, revisionBefore);
      expect(await backupPreferences.lastKnownRevision(), revisionBefore);
    },
  );

  test('a seating plan still updates after a resume reopened the library', () async {
    await controller.initialize();
    await controller.createDatabase('test');

    // Not disposed here: the container owns the controller it is handed and
    // would dispose it a second time under the shared tearDown.
    final container = ProviderContainer(
      overrides: [appSessionProvider.overrideWith((ref) => controller)],
    );

    final groupId = await container
        .read(groupRepositoryProvider)
        .createGroup(name: '8A', gradeScale: defaultGradeScaleEntries);
    final studentId = await container
        .read(studentRepositoryProvider)
        .addStudent(groupId: groupId, firstName: 'Ada', lastName: 'Lovelace');
    final planId = await container
        .read(seatingPlanRepositoryProvider)
        .createPlan(groupId: groupId, name: 'Main');
    await container
        .read(seatingPlanRepositoryProvider)
        .upsertPosition(planId: planId, studentId: studentId, col: 0, row: 0);

    // Stands in for the seating plan screen: it watches the positions and
    // redraws from whatever the stream hands it.
    final seen = <Map<int, ({int col, int row})>>[];
    final subscription = container.listen(
      seatingPlanPositionsProvider(planId),
      (_, next) {
        final positions = next.value;
        if (positions != null) seen.add(positions);
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await pumpEventQueue();
    expect(seen.last, {studentId: (col: 0, row: 0)});

    // Coming back to the app reopens the library, because the app's own edits
    // moved its timestamp.
    final file = File(controller.database!.databasePath);
    await file.setLastModified(
      (await file.lastModified()).add(const Duration(seconds: 5)),
    );
    await controller.handleAppResumed();
    await pumpEventQueue();

    // Moving a student, the way the grid does it.
    await container
        .read(seatingPlanRepositoryProvider)
        .moveStudent(planId: planId, studentId: studentId, col: 2, row: 1);
    await pumpEventQueue();

    expect(
      seen.last,
      {studentId: (col: 2, row: 1)},
      reason: 'the plan stopped following the library after the resume',
    );
  });

  test('a resume re-runs the queries the screens are watching', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    await controller.setLockOnBackground(false);

    final container = ProviderContainer(
      overrides: [appSessionProvider.overrideWith((ref) => controller)],
    );
    final groupId = await container
        .read(groupRepositoryProvider)
        .createGroup(name: '8A', gradeScale: defaultGradeScaleEntries);
    final studentId = await container
        .read(studentRepositoryProvider)
        .addStudent(groupId: groupId, firstName: 'Ada', lastName: 'Lovelace');
    final planId = await container
        .read(seatingPlanRepositoryProvider)
        .createPlan(groupId: groupId, name: 'Main');
    await container
        .read(seatingPlanRepositoryProvider)
        .upsertPosition(planId: planId, studentId: studentId, col: 0, row: 0);

    var emissions = 0;
    final subscription = container.listen(
      seatingPlanPositionsProvider(planId),
      (_, next) {
        if (next.value != null) emissions++;
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await pumpEventQueue();
    final before = emissions;

    // An update notification lost while the app was away leaves the screen
    // showing what it drew before, with no way to tell. Coming back has to
    // put the plan back in step with the library either way.
    await controller.handleAppBackgrounded();
    await controller.handleAppResumed();
    await pumpEventQueue();

    expect(
      emissions,
      greaterThan(before),
      reason: 'the watched plan was never re-read after the resume',
    );
  });

  test('a resume keeps the library the app itself last wrote to', () async {
    await controller.initialize();
    await controller.createDatabase('test');
    await controller.setLockOnBackground(false);

    final openedDatabase = controller.database;
    final container = ProviderContainer(
      overrides: [appSessionProvider.overrideWith((ref) => controller)],
    );
    await container
        .read(groupRepositoryProvider)
        .createGroup(name: '8A', gradeScale: defaultGradeScaleEntries);

    // Switching away checkpoints the library, which moves its timestamp. That
    // is the app's own doing and no reason to throw the open handle — and
    // every screen hanging off it — away.
    await controller.handleAppBackgrounded();
    await controller.handleAppResumed();

    expect(controller.database, same(openedDatabase));
  });

  test('a resume reopens a library that stopped answering', () async {
    await controller.initialize();
    await controller.createDatabase('test');

    await controller.setLockOnBackground(false);
    // Leaves the session's record of the library's timestamp matching the file
    // on disk, so the reopen below cannot be put down to an outside change.
    await controller.handleAppBackgrounded();

    final openedDatabase = controller.database;
    var notifications = 0;
    controller.addListener(() => notifications++);

    // Nothing changed on disk, so only the handle itself gives the trouble
    // away: closed underneath the app, its query streams go quiet instead of
    // failing and the screen freezes on what it last drew.
    final file = File(openedDatabase!.databasePath);
    final untouched = await file.lastModified();
    await openedDatabase.close();
    await file.setLastModified(untouched);

    await controller.handleAppResumed();

    expect(controller.database, isNot(same(openedDatabase)));
    expect(
      notifications,
      greaterThan(0),
      reason: 'the replacement database was never announced',
    );
  });

  test('a library that cannot be reopened falls back to the lock screen', () async {
    await controller.initialize();
    await controller.createDatabase('test');

    var notifications = 0;
    controller.addListener(() => notifications++);

    // Whatever the reason a reopen fails — a half-written sync, a library on a
    // volume that went away — the session must not stay "ready" with nothing
    // behind it.
    (keyService as _TestKeyService).failNextOpen = true;
    final file = File(controller.database!.databasePath);
    await file.setLastModified(
      (await file.lastModified()).add(const Duration(seconds: 5)),
    );

    await controller.handleAppResumed();

    expect(controller.status, AppSessionStatus.locked);
    expect(controller.database, isNull);
    expect(notifications, greaterThan(0));
  });

  test(
    'resuming onto a changed library announces the reopened database',
    () async {
      await controller.initialize();
      await controller.createDatabase('test');

      final openedDatabase = controller.database;
      expect(openedDatabase, isNotNull);

      var notifications = 0;
      controller.addListener(() => notifications++);

      // Every edit moves the library's timestamp past the one the session
      // recorded when it opened it, which is what makes a resume reopen it.
      final file = File(openedDatabase!.databasePath);
      await file.setLastModified(
        (await file.lastModified()).add(const Duration(seconds: 5)),
      );

      // Not disposed here: the container owns the controller it is handed and
      // would dispose it a second time under the shared tearDown.
      final container = ProviderContainer(
        overrides: [appSessionProvider.overrideWith((ref) => controller)],
      );
      expect(container.read(databaseProvider), same(openedDatabase));

      await controller.handleAppResumed();

      // The old handle is gone, so anything still holding it is talking to a
      // closed database: whoever watches the session has to be told.
      expect(controller.database, isNot(same(openedDatabase)));
      expect(
        notifications,
        greaterThan(0),
        reason: 'the swapped database was never announced',
      );

      // What the announcement is for: the repositories and query streams the
      // screens hang off resolve to the database that is actually open.
      expect(container.read(databaseProvider), same(controller.database));
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

class _FailingDatabasePathService extends DatabasePathService {
  @override
  Future<String> getCurrentDatabasePath() async =>
      throw StateError('no library path');
}

class _TestKeyService extends KeyService {
  /// Makes the next attempt to open the library fail, standing in for the
  /// many ways a reopen can go wrong outside the app's control.
  bool failNextOpen = false;

  @override
  Future<String?> getWebDavPassword(File dbFile) async => '';

  @override
  Future<String> deriveDatabaseKey({
    required File dbFile,
    required String passphrase,
  }) {
    if (failNextOpen) {
      failNextOpen = false;
      return Future.error(StateError('the library is not reachable'));
    }
    return super.deriveDatabaseKey(dbFile: dbFile, passphrase: passphrase);
  }
}

SecurityPreferencesService _securityPreferencesServiceFor(
  DatabasePathService databasePathService,
) {
  return SecurityPreferencesService(
    projectSettingsStore: ProjectSettingsStore(
      databasePathService: databasePathService,
    ),
  );
}

LibraryBackupPreferencesService _libraryBackupPreferencesServiceFor(
  DatabasePathService databasePathService,
) {
  return LibraryBackupPreferencesService(
    projectSettingsStore: ProjectSettingsStore(
      databasePathService: databasePathService,
    ),
  );
}

class _DelayingLibraryBackupService extends LibraryBackupService {
  final Completer<void> started = Completer<void>();
  final Completer<void> finish = Completer<void>();

  @override
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
    String? parentRevision,
  }) async {
    if (!started.isCompleted) {
      started.complete();
    }
    await finish.future;
    return DateTime.now().toUtc();
  }

  // Avoid real network round-trips for the post-export bookkeeping calls;
  // the fake client points at a non-existent host.
  @override
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async => DateTime.now().toUtc();

  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async => const WebDavBackupDeviceInfo(revision: 'revision-1');
}

class _CloseDelayingAppSessionController extends AppSessionController {
  _CloseDelayingAppSessionController({
    required super.keyService,
    required super.databasePathService,
    required super.securityPreferencesService,
    required super.libraryBackupPreferencesService,
    required super.libraryBackupService,
    required super.biometricService,
  });

  final Completer<void> closeStarted = Completer<void>();
  final Completer<void> finishClose = Completer<void>();

  @override
  Future<void> closeDatabaseAfterLockTransition(AppDatabase? database) async {
    if (!closeStarted.isCompleted) {
      closeStarted.complete();
    }
    await finishClose.future;
    await super.closeDatabaseAfterLockTransition(database);
  }
}

class _RestoringLibraryBackupService extends LibraryBackupService {
  _RestoringLibraryBackupService(this.archiveBytes);

  final Uint8List archiveBytes;
  String? lastRemotePath;

  @override
  Future<Uint8List> downloadBackupFromWebDav({
    required webdav.Client client,
    required String remotePath,
  }) async {
    lastRemotePath = remotePath;
    return archiveBytes;
  }
}

class _RestoringSelfLibraryBackupService extends LibraryBackupService {
  _RestoringSelfLibraryBackupService(this.archiveBytes);

  final Uint8List archiveBytes;
  bool exportCalled = false;
  String? lastRemotePath;
  String? archivedConflictName;

  @override
  Future<void> archiveResolvedConflictCopy({
    required webdav.Client client,
    required String serverPath,
    required String conflictFileName,
    DateTime? resolvedAt,
  }) async {
    archivedConflictName = conflictFileName;
  }

  @override
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
    String? parentRevision,
  }) async {
    exportCalled = true;
    return DateTime.now().toUtc();
  }

  @override
  Future<Uint8List> downloadBackupFromWebDav({
    required webdav.Client client,
    required String remotePath,
  }) async {
    lastRemotePath = remotePath;
    return archiveBytes;
  }
}

class _RestoringAppSessionController extends AppSessionController {
  _RestoringAppSessionController({
    required super.keyService,
    required super.databasePathService,
    required super.securityPreferencesService,
    required super.libraryBackupPreferencesService,
    required super.libraryBackupService,
    required super.biometricService,
  });

  @override
  Future<webdav.Client?> createWebDavClient() async =>
      webdav.newClient('https://example.invalid');
}

class _WebDavAppSessionController extends AppSessionController {
  _WebDavAppSessionController({
    required super.keyService,
    required super.databasePathService,
    required super.securityPreferencesService,
    required super.libraryBackupPreferencesService,
    required super.libraryBackupService,
    required super.biometricService,
    super.periodicExportInterval,
    super.syncRetryDelays,
  });

  @override
  Future<webdav.Client?> createWebDavClient() async =>
      webdav.newClient('https://example.invalid');
}

class _ExportingLibraryBackupService extends LibraryBackupService {
  _ExportingLibraryBackupService({
    required this.exportedAt,
    required this.remoteModifiedAt,
  });

  final DateTime exportedAt;
  final DateTime remoteModifiedAt;

  @override
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
    String? parentRevision,
  }) async {
    return exportedAt;
  }

  @override
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async {
    return remoteModifiedAt;
  }

  // Avoid a real network round-trip for the post-export revision lookup;
  // the fake client points at a non-existent host.
  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async => const WebDavBackupDeviceInfo(revision: 'revision-1');
}

class _DeviceCapturingLibraryBackupService extends LibraryBackupService {
  String? lastDeviceId;
  String? lastDeviceName;
  String? lastParentRevision;
  int exportCount = 0;

  @override
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
    String? parentRevision,
  }) async {
    lastDeviceId = deviceId;
    lastDeviceName = deviceName;
    lastParentRevision = parentRevision;
    exportCount++;
    return DateTime.now().toUtc();
  }

  // Avoid a real network round-trip: _runAutoExportIfConfigured calls these
  // right after exportBackupToWebDav (to timestamp the pending-import
  // dismissal, and to record the newly uploaded revision), and the fake
  // client points at a non-existent host.
  @override
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async => DateTime.now().toUtc();

  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async =>
      WebDavBackupDeviceInfo(deviceId: lastDeviceId, revision: 'revision-1');
}

class _PendingImportDeviceLibraryBackupService extends LibraryBackupService {
  _PendingImportDeviceLibraryBackupService({
    required this.remoteModifiedAt,
    required this.deviceName,
  });

  final DateTime remoteModifiedAt;
  final String deviceName;

  @override
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async {
    return remoteModifiedAt;
  }

  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async {
    return WebDavBackupDeviceInfo(
      deviceId: 'remote-device',
      deviceName: deviceName,
    );
  }
}

class _ConflictingLibraryBackupService extends LibraryBackupService {
  @override
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
    String? parentRevision,
  }) async {
    throw const WebDavSyncConflictException(
      message: 'Another device changed this library.',
      conflictingDeviceName: 'Other Device',
      conflictRemotePath: '/test_CONFLICT_device-a.classi-backup',
      canonicalRevision: 'server-revision',
    );
  }

  // A conflicting export leaves the copy on the server, so the sync-status
  // check that runs straight afterwards finds it there.
  @override
  Future<List<String>?> listConflictCopyNames({
    required webdav.Client client,
    required String serverPath,
    required String libraryName,
  }) async => ['${libraryName}_CONFLICT_device-a$classiBackupExtension'];

  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async => const WebDavBackupDeviceInfo(
    deviceId: 'device-a',
    deviceName: 'Other Device',
  );
}

/// A server where another device has already parked its changes in a
/// `_CONFLICT_` copy, but the canonical backup is untouched and older than
/// this device's own last export — the situation in which this device would
/// otherwise report itself up to date.
class _ParkedConflictLibraryBackupService extends LibraryBackupService {
  int conflictLookups = 0;

  @override
  Future<List<String>?> listConflictCopyNames({
    required webdav.Client client,
    required String serverPath,
    required String libraryName,
  }) async {
    conflictLookups++;
    return ['${libraryName}_CONFLICT_other-device$classiBackupExtension'];
  }

  @override
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async => DateTime.utc(2020);

  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async => const WebDavBackupDeviceInfo(
    deviceId: 'other-device',
    deviceName: 'Other Device',
    revision: 'revision-1',
  );
}

/// A remote backup whose revision differs from the device's last known
/// revision, exercising the revision-based "behind" detection.
class _RevisionBehindLibraryBackupService extends LibraryBackupService {
  _RevisionBehindLibraryBackupService({
    required this.remoteRevision,
    required this.remoteModifiedAt,
    this.deviceName = 'Other Device',
  });

  final String remoteRevision;
  final DateTime remoteModifiedAt;
  final String deviceName;

  @override
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async => remoteModifiedAt;

  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async => WebDavBackupDeviceInfo(
    deviceId: 'other-device',
    deviceName: deviceName,
    revision: remoteRevision,
  );
}

/// Fails the first [failCount] export attempts with a busy lock, then
/// succeeds. Used to exercise the sync-retry backoff.
class _RetryThenSucceedLibraryBackupService extends LibraryBackupService {
  _RetryThenSucceedLibraryBackupService({this.failCount = 1});

  int failCount;
  int exportCalls = 0;

  @override
  Future<DateTime> exportBackupToWebDav({
    required webdav.Client client,
    required String sourceDatabasePath,
    required String serverPath,
    int maxVersions = 3,
    String? deviceId,
    String? deviceName,
    String? parentRevision,
  }) async {
    exportCalls++;
    if (exportCalls <= failCount) {
      throw const WebDavSyncBusyException(
        'Another device is syncing this library right now.',
      );
    }
    return DateTime.now().toUtc();
  }

  @override
  Future<DateTime?> getRemoteBackupModifiedAt({
    required webdav.Client client,
    required String serverPath,
    required String backupFileName,
  }) async => DateTime.now().toUtc();

  @override
  Future<WebDavBackupDeviceInfo> getRemoteBackupDeviceInfo({
    required webdav.Client client,
    required String remotePath,
  }) async => const WebDavBackupDeviceInfo(revision: 'revision-1');
}
