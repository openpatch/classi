import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/theme/chips/floating_with_silent_download.dart';
import 'package:updat/updat.dart';
import 'package:updat/updat_window_manager.dart';

import '../../core/providers/app_providers.dart';
import '../../core/update/app_update_controller.dart';

const _owner = 'openpatch';
const _repo = 'classi';
const _apiBase = 'https://api.github.com/repos/$_owner/$_repo/releases';

/// Whether the current platform supports desktop auto-updates.
bool get isDesktopPlatform =>
    Platform.isLinux || Platform.isMacOS || Platform.isWindows;

/// Wraps [child] with [UpdatWindowManager] on desktop platforms
/// (Linux, macOS, Windows) to provide automatic update notifications.
///
/// On non-desktop platforms the child is returned as-is.
class AppUpdater extends ConsumerStatefulWidget {
  const AppUpdater({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppUpdater> createState() => _AppUpdaterState();
}

class _AppUpdaterState extends ConsumerState<AppUpdater> {
  String? _currentVersion;

  /// Cached latest-release payload. Shared between [_getLatestVersion] and
  /// [_getChangelog] to avoid a duplicate network request per update check.
  Future<Map<String, dynamic>?>? _latestReleaseFuture;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      _scheduleControllerWrite(
        (controller) => controller.updateStatus(
          UpdatStatus.idle,
          currentVersion: info.version,
        ),
      );
      if (mounted) {
        setState(() => _currentVersion = info.version);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = _currentVersion;
    if (version == null) {
      return widget.child;
    }

    return UpdatWindowManager(
      currentVersion: version,
      getLatestVersion: _getLatestVersion,
      getBinaryUrl: _getBinaryUrl,
      appName: 'Classi',
      getChangelog: (version, changelog) => _getChangelog(),
      closeOnInstall: true,
      callback: (status) => _scheduleControllerWrite(
        (controller) =>
            controller.updateStatus(status, currentVersion: version),
      ),
      updateChipBuilder:
          ({
            required BuildContext context,
            required String? latestVersion,
            required String appVersion,
            required UpdatStatus status,
            required void Function() checkForUpdate,
            required void Function() openDialog,
            required void Function() startUpdate,
            required Future<void> Function() launchInstaller,
            required void Function() dismissUpdate,
          }) {
            _scheduleControllerWrite((controller) {
              controller.bindUpdatActions(
                appVersion: appVersion,
                latestVersion: latestVersion,
                checkForUpdate: checkForUpdate,
                openDialog: openDialog,
              );
              controller.updateStatus(
                status,
                latestVersion: latestVersion,
                currentVersion: appVersion,
              );
            });
            return floatingExtendedChipWithSilentDownload(
              context: context,
              latestVersion: latestVersion,
              appVersion: appVersion,
              status: status,
              checkForUpdate: checkForUpdate,
              openDialog: openDialog,
              startUpdate: startUpdate,
              launchInstaller: launchInstaller,
              dismissUpdate: dismissUpdate,
            );
          },
      child: widget.child,
    );
  }

  void _scheduleControllerWrite(void Function(AppUpdateController) action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action(ref.read(appUpdateControllerProvider));
    });
  }

  Future<String?> _getLatestVersion() async {
    try {
      // Reset cache on each periodic version check so a new release is
      // eventually detected without restarting the app.
      _latestReleaseFuture = null;
      final data = await _fetchLatestRelease();
      if (data == null) return null;

      final tagName = data['tag_name'] as String;

      // Strip the leading 'v' so comparison with PackageInfo.version works.
      return tagName.startsWith('v') ? tagName.substring(1) : tagName;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getBinaryUrl(String? version) async {
    if (version == null) {
      throw StateError('Cannot determine binary URL: latestVersion is null');
    }
    try {
      final response = await http.get(Uri.parse('$_apiBase/tags/v$version'));
      if (response.statusCode != 200) {
        throw StateError(
          'Failed to fetch release assets for v$version '
          '(HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final assets = data['assets'] as List<dynamic>;

      final suffix = _platformAssetSuffix;
      for (final asset in assets) {
        final name = asset['name'] as String;
        if (name.endsWith(suffix)) {
          return asset['browser_download_url'] as String;
        }
      }
      throw StateError(
        'No release asset found for platform "$suffix" in release v$version',
      );
    } catch (e) {
      if (e is StateError) rethrow;
      throw StateError('Failed to get binary URL for v$version: $e');
    }
  }

  Future<String?> _getChangelog() async {
    try {
      final data = await _fetchLatestRelease();
      return data?['body'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetches the latest GitHub release payload, caching the result so that
  /// [_getLatestVersion] and [_getChangelog] share a single network request.
  Future<Map<String, dynamic>?> _fetchLatestRelease() {
    return _latestReleaseFuture ??= _doFetchLatestRelease();
  }

  Future<Map<String, dynamic>?> _doFetchLatestRelease() async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/latest'));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Clear cache on failure so the next call can retry.
      _latestReleaseFuture = null;
      return null;
    }
  }

  /// Returns the platform-specific asset file suffix for the current desktop
  /// platform.
  String get _platformAssetSuffix {
    if (Platform.isLinux) return '-linux.AppImage';
    if (Platform.isMacOS) return '-macos.dmg';
    if (Platform.isWindows) return '-windows-setup.exe';
    throw UnsupportedError(
      'AppUpdater is not supported on platform: ${Platform.operatingSystem}',
    );
  }
}
