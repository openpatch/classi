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
  }) async {
    if (!started.isCompleted) {
      started.complete();
    }
    await finish.future;
    return DateTime.now().toUtc();
  }
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
}
