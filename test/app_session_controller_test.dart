import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/security/biometric_service.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/security/security_preferences_service.dart';
import 'package:classi/core/session/app_session_controller.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/core/storage/library_backup_preferences_service.dart';
import 'package:classi/core/storage/library_backup_service.dart';
import 'package:classi/core/storage/project_settings_store.dart';

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

class _TestKeyService extends KeyService {
  @override
  Future<String?> getWebDavPassword(File dbFile) async => '';
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
    );
  }
}
