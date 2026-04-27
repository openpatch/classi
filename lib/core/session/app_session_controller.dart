import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

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
  bool _biometricEnabled = false;
  Duration _inactivityTimeout =
      SecurityPreferencesService.defaultInactivityTimeout;
  Timer? _inactivityTimer;
  String? _currentPassphrase;
  String? _pendingRecoveryKey;
  bool _autoExportEnabled = false;
  String? _autoExportFolderPath;
  bool _autoImportEnabled = false;
  String? _autoImportBackupPath;
  String? _pendingAutoImportBackupPath;
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
  bool get autoExportEnabled => _autoExportEnabled;
  String? get autoExportFolderPath => _autoExportFolderPath;
  bool get autoImportEnabled => _autoImportEnabled;
  String? get autoImportBackupPath => _autoImportBackupPath;
  bool get hasPendingAutoImport => _pendingAutoImportBackupPath != null;
  String? get pendingAutoImportBackupPath => _pendingAutoImportBackupPath;
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
    _pendingAutoImportBackupPath = null;
    _errorCode = null;
    _status = AppSessionStatus.ready;
    notifyListeners();
    return bootstrapResult.recoveryKey;
  }

  Future<bool> unlock(String passphrase) async {
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

    _cancelInactivityTimer();
    await _persistOpenDatabaseState(markSessionClean: true);
    _status = AppSessionStatus.locked;
    _errorCode = null;
    notifyListeners();
  }

  Future<void> handleAppResumed() async {
    if (_status == AppSessionStatus.ready) {
      await refreshIfChanged();
      _resetInactivityTimer();
    }
  }

  Future<void> handleAppBackgrounded() async {
    if (_status != AppSessionStatus.ready) {
      return;
    }

    if (hasPendingRecoveryKey) {
      _cancelInactivityTimer();
      return;
    }

    if (_lockOnBackground) {
      await lock();
      return;
    }

    _cancelInactivityTimer();
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

  Future<void> setAutoExportEnabled(bool value) async {
    _autoExportEnabled = value;
    await _libraryBackupPreferencesService.setAutoExportEnabled(value);
    notifyListeners();
  }

  Future<void> setAutoExportFolderPath(String? folderPath) async {
    _autoExportFolderPath = folderPath;
    await _libraryBackupPreferencesService.setAutoExportFolderPath(folderPath);
    notifyListeners();
  }

  Future<void> setAutoImportEnabled(bool value) async {
    _autoImportEnabled = value;
    await _libraryBackupPreferencesService.setAutoImportEnabled(value);
    await _updatePendingAutoImportAvailability();
    notifyListeners();
  }

  Future<void> setAutoImportBackupPath(String? backupPath) async {
    _autoImportBackupPath = backupPath;
    await _libraryBackupPreferencesService.setAutoImportBackupPath(backupPath);
    await _updatePendingAutoImportAvailability();
    notifyListeners();
  }

  Future<String?> exportBackupToFolder(String folderPath) async {
    final passphrase = _currentPassphrase;
    if (_database == null || passphrase == null) {
      return 'backup_export_failed';
    }

    try {
      await _prepareDatabaseSnapshot();
      await _libraryBackupService.exportBackup(
        sourceDatabasePath: await _databasePathService.getCurrentDatabasePath(),
        destinationFolderPath: folderPath,
      );
      await _openDatabase(passphrase);
      _resetInactivityTimer();
      _setBackupMessage('backup_exported');
      notifyListeners();
      return null;
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'export backup to folder',
        error: error,
        stackTrace: stackTrace,
      );
      if (_database == null) {
        await _openDatabase(passphrase);
        _resetInactivityTimer();
      }
      _setBackupMessage('backup_export_failed', isError: true);
      notifyListeners();
      return 'backup_export_failed';
    }
  }

  Future<String?> importBackup(String backupFilePath) async {
    if (_isBusy) {
      return 'database_busy';
    }
    if (!await File(backupFilePath).exists()) {
      return 'backup_file_not_found';
    }

    _isBusy = true;
    _beginLoading();

    try {
      await _loadSecurityPreferences();
      await _loadBackupPreferences();
      await _persistOpenDatabaseState(markSessionClean: true);

      final destinationPath = await _databasePathService
          .createUniqueImportedDatabasePath(
            LibraryBackupService.libraryNameForBackupFile(backupFilePath),
          );
      await _libraryBackupService.importBackup(
        backupFilePath: backupFilePath,
        destinationDatabasePath: destinationPath,
      );
      await _databasePathService.setDatabaseFilePath(destinationPath);
      await _resolveCurrentDatabaseState();
      _setBackupMessage('backup_imported');
      return null;
    } catch (error, stackTrace) {
      await _handleFatalError(
        operation: 'import backup',
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

  Future<String?> restorePendingAutoImport() async {
    final backupPath = _pendingAutoImportBackupPath;
    if (_isBusy) {
      return 'database_busy';
    }
    if (backupPath == null) {
      return 'no_newer_backup_available';
    }
    if (!await File(backupPath).exists()) {
      await _updatePendingAutoImportAvailability();
      return 'backup_file_not_found';
    }

    _isBusy = true;
    _beginLoading();

    try {
      await _loadSecurityPreferences();
      await _loadBackupPreferences();
      await _persistOpenDatabaseState(markSessionClean: true);

      final destinationPath = await _databasePathService
          .getCurrentDatabasePath();
      await _libraryBackupService.importBackup(
        backupFilePath: backupPath,
        destinationDatabasePath: destinationPath,
      );
      await _resolveCurrentDatabaseState();
      _setBackupMessage('backup_restored');
      return null;
    } catch (error, stackTrace) {
      await _handleFatalError(
        operation: 'restore pending auto import',
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
    _cancelInactivityTimer();
    final database = _database;
    _database = null;
    _currentPassphrase = null;
    if (database != null) {
      await database.close();
    }
  }

  Future<void> _loadSecurityPreferences() async {
    _lockOnBackground = await _securityPreferencesService.lockOnBackground();
    _inactivityTimeout = await _securityPreferencesService.inactivityTimeout();
    _biometricEnabled = await _securityPreferencesService.biometricEnabled();
  }

  Future<void> _loadBackupPreferences() async {
    _autoExportEnabled = await _libraryBackupPreferencesService
        .autoExportEnabled();
    _autoExportFolderPath = await _libraryBackupPreferencesService
        .autoExportFolderPath();
    _autoImportEnabled = await _libraryBackupPreferencesService
        .autoImportEnabled();
    _autoImportBackupPath = await _libraryBackupPreferencesService
        .autoImportBackupPath();
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
  }) async {
    if (_database == null || _currentPassphrase == null) {
      return;
    }

    await _prepareDatabaseSnapshot();
    await _runAutoExportIfConfigured();
    await _securityPreferencesService.setSessionDirty(!markSessionClean);
    await _updatePendingAutoImportAvailability();
  }

  Future<void> _prepareDatabaseSnapshot() async {
    final database = _database;
    final passphrase = _currentPassphrase;
    if (database == null || passphrase == null) {
      throw StateError('Database is not ready.');
    }

    final dbFile = await _databasePathService.getDatabaseFile();
    await database.checkpointAndTruncate();
    await _closeDatabase();
    await _keyService.writeIntegrityManifest(
      dbFile: dbFile,
      passphrase: passphrase,
    );
  }

  Future<void> _runAutoExportIfConfigured() async {
    final folderPath = _autoExportFolderPath;
    if (!_autoExportEnabled ||
        folderPath == null ||
        folderPath.trim().isEmpty) {
      return;
    }

    try {
      await _libraryBackupService.exportBackup(
        sourceDatabasePath: await _databasePathService.getCurrentDatabasePath(),
        destinationFolderPath: folderPath,
      );
    } catch (error, stackTrace) {
      _logUnexpectedError(
        operation: 'run auto export',
        error: error,
        stackTrace: stackTrace,
      );
      _setBackupMessage('backup_export_failed', isError: true);
    }
  }

  Future<void> _updatePendingAutoImportAvailability() async {
    final backupPath = _autoImportBackupPath;
    if (!_autoImportEnabled ||
        backupPath == null ||
        backupPath.trim().isEmpty ||
        !LibraryBackupService.isBackupFilePath(backupPath)) {
      _pendingAutoImportBackupPath = null;
      return;
    }

    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      _pendingAutoImportBackupPath = null;
      return;
    }

    final backupModified = await backupFile.lastModified();
    final currentDatabasePath = await _databasePathService
        .getCurrentDatabasePath();
    DateTime? latestLocalModified;
    for (final artifactPath in DatabasePathService.artifactPathsFor(
      currentDatabasePath,
    )) {
      final artifactFile = File(artifactPath);
      if (!await artifactFile.exists()) {
        continue;
      }
      final modifiedAt = await artifactFile.lastModified();
      if (latestLocalModified == null ||
          modifiedAt.isAfter(latestLocalModified)) {
        latestLocalModified = modifiedAt;
      }
    }

    _pendingAutoImportBackupPath =
        latestLocalModified == null ||
            backupModified.isAfter(latestLocalModified)
        ? backupPath
        : null;
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
