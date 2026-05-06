import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:webdav_client/webdav_client.dart' as webdav;

import '../database/app_database.dart';
import '../security/biometric_service.dart';
import '../security/key_service.dart';
import '../security/security_preferences_service.dart';
import '../storage/database_path_service.dart';
import '../storage/library_backup_preferences_service.dart';
import '../storage/library_backup_service.dart';

enum AppSessionStatus { loading, needsSetup, locked, ready, error }

enum AppSessionErrorCode {
  generic('generic_error'),
  errorLoadingDatabase('error_loading_database'),
  invalidPassphrase('invalid_passphrase'),
  integrityCheckFailed('integrity_check_failed'),
  invalidRecoveryKey('invalid_recovery_key'),
  recoveryNotAvailable('recovery_not_available');

  const AppSessionErrorCode(this.translationKey);

  final String translationKey;
}

class AppSessionController extends ChangeNotifier {
  AppSessionController({
    required KeyService keyService,
    required DatabasePathService databasePathService,
    required SecurityPreferencesService securityPreferencesService,
    required LibraryBackupPreferencesService libraryBackupPreferencesService,
    required LibraryBackupService libraryBackupService,
    required BiometricService biometricService,
  }) : _keyService = keyService,
       _databasePathService = databasePathService,
       _securityPreferencesService = securityPreferencesService,
       _libraryBackupPreferencesService = libraryBackupPreferencesService,
       _libraryBackupService = libraryBackupService,
       _biometricService = biometricService;

  final KeyService _keyService;
  final DatabasePathService _databasePathService;
  final SecurityPreferencesService _securityPreferencesService;
  final LibraryBackupPreferencesService _libraryBackupPreferencesService;
  final LibraryBackupService _libraryBackupService;
  final BiometricService _biometricService;

  AppDatabase? _database;
  AppSessionStatus _status = AppSessionStatus.loading;
  AppSessionErrorCode? _errorCode;
  DateTime? _openedAt;
  bool _isBusy = false;
  bool _lockOnBackground = true;
  int _backgroundLockSuspendCount = 0;
  bool _biometricEnabled = false;
  Duration _inactivityTimeout =
      SecurityPreferencesService.defaultInactivityTimeout;
  Timer? _inactivityTimer;
  String? _currentPassphrase;
  String? _pendingRecoveryKey;
  bool _webDavAutoExportEnabled = false;
  bool _webDavAutoImportEnabled = false;
  String? _webDavUrl;
  String? _webDavUsername;
  String? _webDavServerPath;
  int _webDavMaxVersions = LibraryBackupPreferencesService.defaultMaxVersions;
  bool _pendingWebDavImport = false;
  DateTime? _pendingImportRemoteModifiedAt;
  DateTime? _lastExportedAt;
  DateTime? _lastImportedAt;
  bool _isExporting = false;
  Future<void>? _pendingLockCleanup;
  String? _lastBackupMessageCode;
  bool _lastBackupMessageIsError = false;

  AppSessionStatus get status => _status;
  AppDatabase? get database => _database;
  AppSessionErrorCode? get errorCode => _errorCode;
  String? get errorMessage => _errorCode?.translationKey;
  bool get lockOnBackground => _lockOnBackground;
  bool get biometricEnabled => _biometricEnabled;
  Duration get inactivityTimeout => _inactivityTimeout;
  String? get pendingRecoveryKey => _pendingRecoveryKey;
  bool get webDavAutoExportEnabled => _webDavAutoExportEnabled;
  bool get webDavAutoImportEnabled => _webDavAutoImportEnabled;
  String? get webDavUrl => _webDavUrl;
  String? get webDavUsername => _webDavUsername;
  String? get webDavServerPath => _webDavServerPath;
  int get webDavMaxVersions => _webDavMaxVersions;
  bool get isWebDavConfigured => _webDavUrl != null && _webDavUrl!.isNotEmpty;
  bool get hasPendingAutoImport => _pendingWebDavImport;

  /// The server mTime of the remote backup that triggered the pending import
  /// prompt, or `null` when no import is pending.
  DateTime? get pendingImportRemoteModifiedAt => _pendingImportRemoteModifiedAt;

  DateTime? get lastExportedAt => _lastExportedAt;
  DateTime? get lastImportedAt => _lastImportedAt;
  bool get isExporting => _isExporting;
  String? get lastBackupMessageCode => _lastBackupMessageCode;
  bool get lastBackupMessageIsError => _lastBackupMessageIsError;
  bool get hasPendingRecoveryKey => _pendingRecoveryKey != null;
  bool get isRecoveryKeyHandoffActive =>
      _status == AppSessionStatus.ready && hasPendingRecoveryKey;

  Future<void> initialize() async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    _beginLoading();

    try {
      await _loadSecurityPreferences();
      await _loadBackupPreferences();
      await _resolveCurrentDatabaseState();
    } catch (error, stackTrace) {
      await _handleFatalError(
        operation: 'initialize session',
        error: error,
        stackTrace: stackTrace,
        errorCode: AppSessionErrorCode.errorLoadingDatabase,
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<String?> createDatabase(String passphrase) async {
    final dbFile = await _databasePathService.getDatabaseFile();
    final bootstrapResult = await _keyService.bootstrapSecurity(
      dbFile: dbFile,
      passphrase: passphrase,
    );
    await _openDatabase(passphrase);
    if (_biometricEnabled) {
      await _keyService.saveBiometricPassphrase(dbFile, passphrase);
    }
    _pendingRecoveryKey = bootstrapResult.recoveryKey;
    _pendingWebDavImport = false;
    _errorCode = null;
    _status = AppSessionStatus.ready;
    notifyListeners();
    return bootstrapResult.recoveryKey;
  }

  Future<bool> unlock(String passphrase) async {
    await _waitForPendingLockCleanup();
    if (_isBusy) {
      return false;
    }

    _isBusy = true;
    _status = AppSessionStatus.loading;
    _errorCode = null;
    notifyListeners();

    try {
      final dbFile = await _databasePathService.getDatabaseFile();
      final validPassphrase = await _keyService.verifyPassphrase(
        dbFile: dbFile,
        passphrase: passphrase,
      );
      if (!validPassphrase) {
        _setLockedError(AppSessionErrorCode.invalidPassphrase);
        return false;
      }

      final allowRepair = await _securityPreferencesService.wasSessionDirty();
      final integrityValid = await _keyService.validateIntegrity(
        dbFile: dbFile,
        passphrase: passphrase,
        allowRepair: allowRepair,
      );
      if (!integrityValid) {
        final repaired = await _repairIntegrityAfterOpen(
          dbFile: dbFile,
          passphrase: passphrase,
        );
        if (!repaired) {
          await _closeDatabase();
          _setLockedError(AppSessionErrorCode.integrityCheckFailed);
          return false;
        }
      }

      if (_database == null) {
        await _openDatabase(passphrase);
      }
      await _keyService.writeIntegrityManifest(
        dbFile: dbFile,
        passphrase: passphrase,
      );
      await _securityPreferencesService.setSessionDirty(true);
      if (_biometricEnabled) {
        await _keyService.saveBiometricPassphrase(dbFile, passphrase);
      }
      _status = AppSessionStatus.ready;
      _resetInactivityTimer();
      return true;
    } catch (error, stackTrace) {
      await _handleFatalError(
        operation: 'unlock database',
        error: error,
        stackTrace: stackTrace,
        errorCode: AppSessionErrorCode.errorLoadingDatabase,
      );
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> _repairIntegrityAfterOpen({
    required File dbFile,
    required String passphrase,
  }) async {
    try {
      await _openDatabase(passphrase);
      await _keyService.writeIntegrityManifest(
        dbFile: dbFile,
        passphrase: passphrase,
      );
      return true;
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'repair integrity after open',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> lock() async {
    if (isRecoveryKeyHandoffActive) {
      return;
    }
    if (_status != AppSessionStatus.ready || _isExporting || _isBusy) {
      return;
    }

    _cancelInactivityTimer();
    _isBusy = true;
    _errorCode = null;
    _isExporting = true;
    notifyListeners();
    try {
      await _persistOpenDatabaseState(
        markSessionClean: true,
        closeDatabaseAfterSnapshot: false,
      );
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'persist database state on lock',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      final databaseToClose = _detachDatabase();
      _status = AppSessionStatus.locked;
      _isExporting = false;
      final cleanupFuture = _runPendingLockCleanup(databaseToClose);
      _pendingLockCleanup = cleanupFuture;
      _isBusy = false;
      notifyListeners();
      await cleanupFuture;
    }
  }

  Future<void> handleAppResumed() async {
    if (_status == AppSessionStatus.ready) {
      await refreshIfChanged();
      _resetInactivityTimer();
    }
  }

  /// Temporarily prevents the app from locking when it goes to the background.
  ///
  /// Call this before opening a system dialog (e.g. file picker) that causes
  /// the Flutter app to transition to the paused lifecycle state. Always pair
  /// with [resumeBackgroundLock] in a try/finally block.
  ///
  /// Calls are reference-counted, so nested suspend/resume pairs are safe.
  void suspendBackgroundLock() {
    _backgroundLockSuspendCount++;
  }

  /// Re-enables background locking after a call to [suspendBackgroundLock].
  void resumeBackgroundLock() {
    if (_backgroundLockSuspendCount > 0) {
      _backgroundLockSuspendCount--;
    }
  }

  Future<void> handleAppBackgrounded() async {
    if (_status != AppSessionStatus.ready || _isExporting) {
      return;
    }

    if (hasPendingRecoveryKey || _backgroundLockSuspendCount > 0) {
      _cancelInactivityTimer();
      return;
    }

    if (_lockOnBackground) {
      await lock();
      return;
    }

    _cancelInactivityTimer();
    await _flushAndAutoExport();
  }

  void registerActivity() {
    if (_status != AppSessionStatus.ready) {
      return;
    }
    _resetInactivityTimer();
  }

  Future<void> refreshIfChanged() async {
    if (_database == null || _status != AppSessionStatus.ready) {
      return;
    }

    final file = File(_database!.databasePath);
    if (!await file.exists()) {
      return;
    }

    final modified = await file.lastModified();
    final previous = _openedAt;
    if (previous != null && modified.isAtSameMomentAs(previous)) {
      return;
    }

    final passphrase = _currentPassphrase;
    if (passphrase == null) {
      return;
    }

    await _openDatabase(passphrase);
  }

  Future<void> moveDatabaseTo(String folderPath) async {
    final passphrase = _currentPassphrase;
    if (passphrase == null || _database == null) {
      return;
    }

    _status = AppSessionStatus.loading;
    notifyListeners();

    await _persistOpenDatabaseState(markSessionClean: true);
    await _databasePathService.moveTo(folderPath);
    await _openDatabase(passphrase);
    _status = AppSessionStatus.ready;
    notifyListeners();
  }

  Future<bool> changePassphrase(
    String currentPassphrase,
    String newPassphrase,
  ) async {
    final database = _database;
    if (database == null) {
      return false;
    }

    final dbFile = await _databasePathService.getDatabaseFile();
    final validPassphrase = await _keyService.verifyPassphrase(
      dbFile: dbFile,
      passphrase: currentPassphrase,
    );
    if (!validPassphrase) {
      return false;
    }

    final newDatabaseKey = await _keyService.rotateSecurity(
      dbFile: dbFile,
      currentPassphrase: currentPassphrase,
      newPassphrase: newPassphrase,
    );
    final escapedDatabaseKey = newDatabaseKey.replaceAll("'", "''");
    await database.customStatement("PRAGMA rekey = '$escapedDatabaseKey';");
    _currentPassphrase = newPassphrase;
    await database.checkpointAndTruncate();
    await _keyService.writeIntegrityManifest(
      dbFile: dbFile,
      passphrase: newPassphrase,
    );
    await _securityPreferencesService.setSessionDirty(true);
    if (_biometricEnabled) {
      await _keyService.saveBiometricPassphrase(dbFile, newPassphrase);
    }
    return true;
  }

  Future<String> currentFolderPath() =>
      _databasePathService.getCurrentFolderPath();

  Future<String> currentDatabasePath() =>
      _databasePathService.getCurrentDatabasePath();

  /// Updates the stored database path without opening or creating the database.
  ///
  /// Call this before [createDatabase] to change where the new database will
  /// be written.
  Future<void> setNewDatabasePath(String path) async {
    await _databasePathService.setDatabaseFilePath(path);
    notifyListeners();
  }

  Future<bool> supportsRecovery() async {
    final dbFile = await _databasePathService.getDatabaseFile();
    return _keyService.hasRecoveryKey(dbFile);
  }

  Future<List<String>> sidecarPaths() async {
    final dbFile = await _databasePathService.getDatabaseFile();
    return _keyService.securityArtifactPaths(dbFile);
  }

  Future<String?> selectDatabase(
    String databasePath, {
    required bool createNew,
  }) async {
    if (_isBusy) {
      return 'database_busy';
    }

    final targetExists = await _databasePathService.databasePathExists(
      databasePath,
    );
    if (createNew && targetExists) {
      return 'database_already_exists';
    }
    if (!createNew && !targetExists) {
      return 'database_not_found';
    }

    _isBusy = true;
    _beginLoading();

    try {
      await _loadSecurityPreferences();
      await _loadBackupPreferences();
      await _persistOpenDatabaseState(markSessionClean: true);
      await _databasePathService.setDatabaseFilePath(databasePath);
      await _resolveCurrentDatabaseState();
      return null;
    } catch (error, stackTrace) {
      await _handleFatalError(
        operation: 'select database',
        error: error,
        stackTrace: stackTrace,
        errorCode: AppSessionErrorCode.errorLoadingDatabase,
      );
      return AppSessionErrorCode.errorLoadingDatabase.translationKey;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> setLockOnBackground(bool value) async {
    _lockOnBackground = value;
    await _securityPreferencesService.setLockOnBackground(value);
    notifyListeners();
  }

  Future<void> setInactivityTimeout(Duration value) async {
    _inactivityTimeout = value;
    await _securityPreferencesService.setInactivityTimeout(value);
    _resetInactivityTimer();
    notifyListeners();
  }

  /// Returns `true` when biometric hardware is present and at least one
  /// credential is enrolled on this device.
  Future<bool> isBiometricAvailable() => _biometricService.isAvailable();

  /// Enables or disables biometric unlock.
  ///
  /// When disabling, the stored biometric passphrase is erased from secure
  /// storage.  When enabling, the passphrase is saved the next time the user
  /// unlocks successfully with their passphrase.
  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    await _securityPreferencesService.setBiometricEnabled(value);
    if (!value) {
      final dbFile = await _databasePathService.getDatabaseFile();
      await _keyService.clearBiometricPassphrase(dbFile);
    }
    notifyListeners();
  }

  /// Presents the system biometric prompt and, on success, retrieves the
  /// stored passphrase and unlocks the database.
  ///
  /// Returns `true` on success, `false` when authentication failed or the
  /// biometric passphrase has not been stored yet.
  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    if (!_biometricEnabled) return false;

    final authenticated = await _biometricService.authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) return false;

    final dbFile = await _databasePathService.getDatabaseFile();
    final passphrase = await _keyService.getBiometricPassphrase(dbFile);
    if (passphrase == null) return false;

    return unlock(passphrase);
  }

  Future<void> setWebDavUrl(String? url) async {
    _webDavUrl = (url == null || url.trim().isEmpty) ? null : url.trim();
    await _libraryBackupPreferencesService.setWebDavUrl(_webDavUrl);
    notifyListeners();
  }

  Future<void> setWebDavUsername(String? username) async {
    _webDavUsername = (username == null || username.trim().isEmpty)
        ? null
        : username.trim();
    await _libraryBackupPreferencesService.setWebDavUsername(_webDavUsername);
    notifyListeners();
  }

  Future<void> setWebDavPassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _keyService.clearWebDavPassword();
    } else {
      await _keyService.setWebDavPassword(password);
    }
  }

  Future<void> setWebDavServerPath(String? path) async {
    _webDavServerPath = (path == null || path.trim().isEmpty)
        ? null
        : path.trim();
    await _libraryBackupPreferencesService.setWebDavServerPath(
      _webDavServerPath,
    );
    notifyListeners();
  }

  Future<void> setWebDavAutoExportEnabled(bool value) async {
    _webDavAutoExportEnabled = value;
    await _libraryBackupPreferencesService.setAutoExportEnabled(value);
    notifyListeners();
  }

  Future<void> setWebDavAutoImportEnabled(bool value) async {
    _webDavAutoImportEnabled = value;
    await _libraryBackupPreferencesService.setAutoImportEnabled(value);
    await _updatePendingAutoImportAvailability();
    notifyListeners();
  }

  Future<void> setWebDavMaxVersions(int value) async {
    _webDavMaxVersions = value;
    await _libraryBackupPreferencesService.setMaxVersions(value);
    notifyListeners();
  }

  /// Dismisses the pending import prompt for the current remote backup version.
  ///
  /// The prompt will reappear if the remote backup is replaced by a newer one.
  Future<void> dismissPendingImport() async {
    final remoteModifiedAt = _pendingImportRemoteModifiedAt;
    if (remoteModifiedAt == null) return;
    await _libraryBackupPreferencesService.setPendingImportDismissedAt(
      remoteModifiedAt,
    );
    _pendingWebDavImport = false;
    _pendingImportRemoteModifiedAt = null;
    notifyListeners();
  }

  /// Immediately checkpoints the database and uploads a backup to WebDAV.
  ///
  /// Only available when the session is [AppSessionStatus.ready] and WebDAV
  /// auto-export is configured. Returns a translation key on error or `null`
  /// on success.
  Future<String?> exportNow() async {
    if (_isBusy || _isExporting) return 'database_busy';
    if (_database == null || _currentPassphrase == null) return 'database_busy';
    if (!_webDavAutoExportEnabled || !isWebDavConfigured) {
      return 'webdav_not_configured';
    }

    _isExporting = true;
    notifyListeners();
    try {
      await _flushAndAutoExport();
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  /// Returns `true` if the WebDAV connection test succeeded.
  Future<bool> testWebDavConnection({
    String? url,
    String? username,
    String? password,
  }) async {
    final effectiveUrl = url ?? _webDavUrl;
    if (effectiveUrl == null || effectiveUrl.isEmpty) return false;
    final effectiveUsername = username ?? _webDavUsername ?? '';
    final effectivePassword =
        password ?? await _keyService.getWebDavPassword() ?? '';
    final client = webdav.newClient(
      effectiveUrl,
      user: effectiveUsername,
      password: effectivePassword,
    );
    try {
      await client.ping();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> restorePendingAutoImport() async {
    if (_isBusy) return 'database_busy';
    if (!_pendingWebDavImport) return 'no_newer_backup_available';
    final destinationPath = await _databasePathService.getCurrentDatabasePath();
    final remotePath = LibraryBackupService.remoteBackupPath(
      _webDavServerPath ?? '/',
      destinationPath,
    );
    return _restoreWebDavBackupInternal(
      destinationPath: destinationPath,
      remotePath: remotePath,
      persistDestinationPath: false,
      operation: 'restore pending WebDAV auto import',
    );
  }

  Future<List<WebDavBackupEntry>> listWebDavBackups() async {
    await _loadBackupPreferences();
    final client = await createWebDavClient();
    if (client == null) return const [];
    return _libraryBackupService.listRemoteBackups(
      client: client,
      serverPath: _webDavServerPath ?? '/',
    );
  }

  Future<String?> restoreWebDavBackup({
    required String remotePath,
    required String destinationPath,
    bool createNew = true,
  }) async {
    if (_isBusy) return 'database_busy';

    if (createNew &&
        await _databasePathService.databasePathExists(destinationPath)) {
      return 'database_already_exists';
    }

    return _restoreWebDavBackupInternal(
      destinationPath: destinationPath,
      remotePath: remotePath,
      persistDestinationPath: true,
      operation: 'restore WebDAV backup',
    );
  }

  Future<bool> recoverAccess({
    required String recoveryKey,
    required String newPassphrase,
  }) async {
    if (_isBusy) {
      return false;
    }

    _isBusy = true;
    _beginLoading();

    try {
      final dbFile = await _databasePathService.getDatabaseFile();
      final validRecoveryKey = await _keyService.verifyRecoveryKey(
        dbFile: dbFile,
        recoveryKey: recoveryKey,
      );
      if (!validRecoveryKey) {
        _setLockedError(AppSessionErrorCode.invalidRecoveryKey);
        return false;
      }

      final allowRepair = await _securityPreferencesService.wasSessionDirty();
      final integrityValid = await _keyService.validateIntegrity(
        dbFile: dbFile,
        recoveryKey: recoveryKey,
        allowRepair: allowRepair,
      );
      if (!integrityValid) {
        _setLockedError(AppSessionErrorCode.integrityCheckFailed);
        return false;
      }

      final recoveredDatabaseKey = await _keyService.recoverPassphrase(
        dbFile: dbFile,
        recoveryKey: recoveryKey,
        newPassphrase: newPassphrase,
      );
      if (recoveredDatabaseKey == null) {
        _setLockedError(AppSessionErrorCode.recoveryNotAvailable);
        return false;
      }

      await _openDatabase(newPassphrase);
      await _keyService.writeIntegrityManifest(
        dbFile: dbFile,
        passphrase: newPassphrase,
      );
      await _securityPreferencesService.setSessionDirty(true);
      _pendingRecoveryKey = null;
      _status = AppSessionStatus.ready;
      _resetInactivityTimer();
      return true;
    } catch (error, stackTrace) {
      await _handleFatalError(
        operation: 'recover access',
        error: error,
        stackTrace: stackTrace,
        errorCode: AppSessionErrorCode.errorLoadingDatabase,
      );
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _openDatabase(String passphrase) async {
    await _closeDatabase();
    final file = await _databasePathService.getDatabaseFile();
    final databaseKey = await _keyService.deriveDatabaseKey(
      dbFile: file,
      passphrase: passphrase,
    );
    final database = AppDatabase.open(dbFile: file, databaseKey: databaseKey);
    await database.customSelect('SELECT 1').getSingle();
    await database.checkpointAndTruncate();
    _openedAt = await database.lastModified();
    _database = database;
    _currentPassphrase = passphrase;
  }

  Future<void> _closeDatabase() async {
    final database = _detachDatabase();
    if (database != null) {
      await database.close();
    }
  }

  AppDatabase? _detachDatabase() {
    _cancelInactivityTimer();
    final database = _database;
    _database = null;
    _currentPassphrase = null;
    return database;
  }

  @protected
  Future<void> closeDatabaseAfterLockTransition(AppDatabase? database) async {
    // Let the locked route replace the database-backed UI before closing the
    // database so active stream listeners can dispose cleanly. Use a short
    // event-loop delay instead of SchedulerBinding.endOfFrame so this also
    // completes in controller tests without a pumped frame.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (database != null) {
      await database.close();
    }
  }

  Future<void> _waitForPendingLockCleanup() async {
    final pendingLockCleanup = _pendingLockCleanup;
    if (pendingLockCleanup != null) {
      await pendingLockCleanup;
    }
  }

  Future<void> _runPendingLockCleanup(AppDatabase? database) async {
    try {
      await closeDatabaseAfterLockTransition(database);
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'close database on lock',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _pendingLockCleanup = null;
      notifyListeners();
    }
  }

  Future<void> _loadSecurityPreferences() async {
    _lockOnBackground = await _securityPreferencesService.lockOnBackground();
    _inactivityTimeout = await _securityPreferencesService.inactivityTimeout();
    _biometricEnabled = await _securityPreferencesService.biometricEnabled();
  }

  Future<void> _loadBackupPreferences() async {
    _webDavAutoExportEnabled = await _libraryBackupPreferencesService
        .autoExportEnabled();
    _webDavAutoImportEnabled = await _libraryBackupPreferencesService
        .autoImportEnabled();
    _webDavUrl = await _libraryBackupPreferencesService.webDavUrl();
    _webDavUsername = await _libraryBackupPreferencesService.webDavUsername();
    _webDavServerPath = await _libraryBackupPreferencesService
        .webDavServerPath();
    _webDavMaxVersions = await _libraryBackupPreferencesService.maxVersions();
    _lastExportedAt = await _libraryBackupPreferencesService.lastExportedAt();
    _lastImportedAt = await _libraryBackupPreferencesService.lastImportedAt();
  }

  Future<void> _resolveCurrentDatabaseState() async {
    final dbFile = await _databasePathService.getDatabaseFile();
    final hasSecuritySetup = await _keyService.hasSecuritySetup(dbFile);
    if (!hasSecuritySetup) {
      await _closeDatabase();
      _pendingRecoveryKey = null;
      _status = AppSessionStatus.needsSetup;
      await _updatePendingAutoImportAvailability();
      return;
    }

    await _closeDatabase();
    _pendingRecoveryKey = null;
    _status = AppSessionStatus.locked;
    await _updatePendingAutoImportAvailability();
  }

  Future<void> _persistOpenDatabaseState({
    required bool markSessionClean,
    bool closeDatabaseAfterSnapshot = true,
  }) async {
    if (_database == null || _currentPassphrase == null) {
      developer.log(
        'persistOpenDatabaseState: skipped (no open database)',
        name: 'classi.backup',
      );
      return;
    }

    await _prepareDatabaseSnapshot(
      closeDatabaseAfterSnapshot: closeDatabaseAfterSnapshot,
    );
    await _runAutoExportIfConfigured();
    await _securityPreferencesService.setSessionDirty(!markSessionClean);
    await _updatePendingAutoImportAvailability();
  }

  Future<void> _prepareDatabaseSnapshot({
    required bool closeDatabaseAfterSnapshot,
  }) async {
    final database = _database;
    final passphrase = _currentPassphrase;
    if (database == null || passphrase == null) {
      throw StateError('Database is not ready.');
    }

    final dbFile = await _databasePathService.getDatabaseFile();
    await database.checkpointAndTruncate();
    if (closeDatabaseAfterSnapshot) {
      await _closeDatabase();
    }
    await _keyService.writeIntegrityManifest(
      dbFile: dbFile,
      passphrase: passphrase,
    );
  }

  /// Checkpoints the WAL and runs auto-export without locking the app.
  ///
  /// Used when the app is backgrounded with lock-on-background disabled.
  /// The database remains open so the user can resume seamlessly.
  Future<void> _flushAndAutoExport() async {
    final database = _database;
    if (database == null || _currentPassphrase == null) return;

    try {
      await database.checkpointAndTruncate();
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'checkpoint before background auto export',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    _isExporting = true;
    notifyListeners();
    try {
      await _runAutoExportIfConfigured();
      await _updatePendingAutoImportAvailability();
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> _runAutoExportIfConfigured() async {
    developer.log(
      'auto export check: enabled=$_webDavAutoExportEnabled '
      'configured=$isWebDavConfigured url=$_webDavUrl',
      name: 'classi.backup',
    );
    if (!_webDavAutoExportEnabled || !isWebDavConfigured) return;

    final client = await createWebDavClient();
    if (client == null) return;

    developer.log(
      'starting WebDAV export to $_webDavUrl '
      'serverPath=${_webDavServerPath ?? "/"}',
      name: 'classi.backup',
    );
    try {
      final exportedAt = await _libraryBackupService.exportBackupToWebDav(
        client: client,
        sourceDatabasePath: await _databasePathService.getCurrentDatabasePath(),
        serverPath: _webDavServerPath ?? '/',
        maxVersions: _webDavMaxVersions,
      );
      _lastExportedAt = exportedAt;
      await _libraryBackupPreferencesService.setLastExportedAt(exportedAt);
      developer.log('WebDAV export succeeded', name: 'classi.backup');
      _setBackupMessage('backup_exported');
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'run auto WebDAV export',
        error: error,
        stackTrace: stackTrace,
      );
      _setBackupMessage('backup_export_failed', isError: true);
    }
  }

  Future<void> _updatePendingAutoImportAvailability() async {
    if (!_webDavAutoImportEnabled || !isWebDavConfigured) {
      _pendingWebDavImport = false;
      _pendingImportRemoteModifiedAt = null;
      return;
    }

    final client = await createWebDavClient();
    if (client == null) {
      _pendingWebDavImport = false;
      _pendingImportRemoteModifiedAt = null;
      return;
    }

    try {
      final currentDatabasePath = await _databasePathService
          .getCurrentDatabasePath();
      final backupFileName = LibraryBackupService.backupFileNameForDatabasePath(
        currentDatabasePath,
      );
      final backupModified = await _libraryBackupService
          .getRemoteBackupModifiedAt(
            client: client,
            serverPath: _webDavServerPath ?? '/',
            backupFileName: backupFileName,
          );

      if (backupModified == null) {
        _pendingWebDavImport = false;
        _pendingImportRemoteModifiedAt = null;
        return;
      }

      // Check if the user already dismissed this exact remote version.
      final dismissedAt = await _libraryBackupPreferencesService
          .pendingImportDismissedAt();
      if (dismissedAt != null &&
          !backupModified.isAfter(dismissedAt)) {
        _pendingWebDavImport = false;
        _pendingImportRemoteModifiedAt = null;
        return;
      }

      // Prefer comparing against our own last-exported timestamp (clock-safe).
      // Fall back to local file mTime for devices that have never exported.
      final lastExported = _lastExportedAt;
      final bool isNewer;
      if (lastExported != null) {
        isNewer = backupModified.isAfter(lastExported);
      } else {
        DateTime? latestLocalModified;
        for (final artifactPath in DatabasePathService.artifactPathsFor(
          currentDatabasePath,
        )) {
          final artifactFile = File(artifactPath);
          if (!await artifactFile.exists()) continue;
          final modifiedAt = await artifactFile.lastModified();
          if (latestLocalModified == null ||
              modifiedAt.isAfter(latestLocalModified)) {
            latestLocalModified = modifiedAt;
          }
        }
        isNewer =
            latestLocalModified == null ||
            backupModified.isAfter(latestLocalModified);
      }

      _pendingWebDavImport = isNewer;
      _pendingImportRemoteModifiedAt = isNewer ? backupModified : null;
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'check WebDAV backup availability',
        error: error,
        stackTrace: stackTrace,
      );
      _pendingWebDavImport = false;
      _pendingImportRemoteModifiedAt = null;
    }
  }

  @protected
  Future<webdav.Client?> createWebDavClient() async {
    final url = _webDavUrl;
    if (url == null || url.isEmpty) return null;
    final username = _webDavUsername ?? '';
    final password = await _keyService.getWebDavPassword() ?? '';
    return webdav.newClient(url, user: username, password: password);
  }

  Future<String?> _restoreWebDavBackupInternal({
    required String destinationPath,
    required String remotePath,
    required bool persistDestinationPath,
    required String operation,
  }) async {
    _isBusy = true;
    _beginLoading();

    try {
      await _loadSecurityPreferences();
      await _loadBackupPreferences();
      await _persistOpenDatabaseState(markSessionClean: true);

      final client = await createWebDavClient();
      if (client == null) throw StateError('WebDAV is not configured.');

      final bytes = await _libraryBackupService.downloadBackupFromWebDav(
        client: client,
        remotePath: remotePath,
      );
      if (persistDestinationPath) {
        await _databasePathService.setDatabaseFilePath(destinationPath);
      }
      await _libraryBackupService.restoreBackupFromBytes(
        bytes: bytes,
        destinationDatabasePath: destinationPath,
      );

      final importedAt = DateTime.now().toUtc();
      _lastImportedAt = importedAt;
      await _libraryBackupPreferencesService.setLastImportedAt(importedAt);
      await _libraryBackupPreferencesService.setPendingImportDismissedAt(null);

      await _resolveCurrentDatabaseState();
      _setBackupMessage('backup_restored');
      return null;
    } catch (error, stackTrace) {
      await _handleFatalError(
        operation: operation,
        error: error,
        stackTrace: stackTrace,
        errorCode: AppSessionErrorCode.errorLoadingDatabase,
      );
      _setBackupMessage('backup_import_failed', isError: true);
      return 'backup_import_failed';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _beginLoading() {
    _status = AppSessionStatus.loading;
    _errorCode = null;
    notifyListeners();
  }

  void _setLockedError(AppSessionErrorCode errorCode) {
    _status = AppSessionStatus.locked;
    _errorCode = errorCode;
  }

  Future<void> _handleFatalError({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
    required AppSessionErrorCode errorCode,
  }) async {
    _logUnexpectedError(
      operation: operation,
      error: error,
      stackTrace: stackTrace,
    );
    _errorCode = errorCode;
    await _closeDatabase();
    _status = AppSessionStatus.error;
  }

  void _logUnexpectedError({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      'Failed to $operation.',
      name: 'classi.session',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void clearPendingRecoveryKey() {
    if (_pendingRecoveryKey == null) {
      return;
    }
    _pendingRecoveryKey = null;
    notifyListeners();
  }

  void _resetInactivityTimer() {
    _cancelInactivityTimer();
    if (_status != AppSessionStatus.ready || hasPendingRecoveryKey) {
      return;
    }

    _inactivityTimer = Timer(_inactivityTimeout, () {
      unawaited(lock());
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _setBackupMessage(String code, {bool isError = false}) {
    _lastBackupMessageCode = code;
    _lastBackupMessageIsError = isError;
  }

  @override
  void dispose() {
    _cancelInactivityTimer();
    unawaited(_closeDatabase());
    super.dispose();
  }
}
