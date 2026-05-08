import 'package:flutter/foundation.dart';
import 'package:updat/updat.dart';

enum AppUpdateStatus {
  idle('app_update_status_idle'),
  checking('app_update_status_checking'),
  upToDate('app_update_status_current'),
  available('app_update_status_available'),
  downloading('app_update_status_downloading'),
  readyToInstall('app_update_status_ready'),
  error('app_update_status_error');

  const AppUpdateStatus(this.translationKey);

  final String translationKey;
}

/// Stores the current app-update status and exposes manual update checks.
class AppUpdateController extends ChangeNotifier {
  AppUpdateStatus _status = AppUpdateStatus.idle;
  String? _currentVersion;
  String? _latestVersion;
  VoidCallback? _checkForUpdate;
  VoidCallback? _openDialog;

  AppUpdateStatus get status => _status;
  String? get currentVersion => _currentVersion;
  String? get latestVersion => _latestVersion;
  bool get canCheckForUpdates => _checkForUpdate != null;

  void bindUpdatActions({
    required String appVersion,
    required String? latestVersion,
    required VoidCallback checkForUpdate,
    required VoidCallback openDialog,
  }) {
    final hasChanged =
        _currentVersion != appVersion ||
        _latestVersion != latestVersion ||
        _checkForUpdate != checkForUpdate ||
        _openDialog != openDialog;
    if (!hasChanged) return;

    _currentVersion = appVersion;
    _latestVersion = latestVersion;
    _checkForUpdate = checkForUpdate;
    _openDialog = openDialog;
    notifyListeners();
  }

  void updateStatus(
    UpdatStatus updatStatus, {
    String? latestVersion,
    String? currentVersion,
  }) {
    final mappedStatus = switch (updatStatus) {
      UpdatStatus.idle => AppUpdateStatus.idle,
      UpdatStatus.checking => AppUpdateStatus.checking,
      UpdatStatus.upToDate => AppUpdateStatus.upToDate,
      UpdatStatus.available ||
      UpdatStatus.availableWithChangelog => AppUpdateStatus.available,
      UpdatStatus.downloading => AppUpdateStatus.downloading,
      UpdatStatus.readyToInstall ||
      UpdatStatus.dismissed => AppUpdateStatus.readyToInstall,
      UpdatStatus.error => AppUpdateStatus.error,
    };

    final hasChanged =
        _status != mappedStatus ||
        (latestVersion != null && _latestVersion != latestVersion) ||
        (currentVersion != null && _currentVersion != currentVersion);
    if (!hasChanged) return;

    _status = mappedStatus;
    if (latestVersion != null) _latestVersion = latestVersion;
    if (currentVersion != null) _currentVersion = currentVersion;
    notifyListeners();
  }

  Future<void> checkForUpdates() async {
    final check = _checkForUpdate;
    if (check == null) return;
    if (_status != AppUpdateStatus.checking) {
      _status = AppUpdateStatus.checking;
      notifyListeners();
    }
    check();
  }

  void openUpdateDialog() {
    _openDialog?.call();
  }
}
