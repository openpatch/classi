import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat_window_manager.dart';

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
class AppUpdater extends StatefulWidget {
  const AppUpdater({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdater> createState() => _AppUpdaterState();
}

class _AppUpdaterState extends State<AppUpdater> {
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
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
      getChangelog: (_, __) => _getChangelog(),
      child: widget.child,
    );
  }

  Future<String?> _getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/latest'),
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String;

      // Strip the leading 'v' so comparison with PackageInfo.version works.
      return tagName.startsWith('v') ? tagName.substring(1) : tagName;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getBinaryUrl(String? version) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/tags/v$version'),
      );
      if (response.statusCode != 200) {
        throw StateError(
          'Failed to fetch release assets for v$version: ${response.statusCode}',
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
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError('Failed to get binary URL for v$version: $e');
    }
  }

  Future<String?> _getChangelog() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/latest'),
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['body'] as String?;
    } catch (_) {
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
