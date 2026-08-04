import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Identifies this installation of Classi to other devices syncing the same
/// WebDAV backup, so a remote backup or a pending-import prompt can say
/// which device it came from.
///
/// The identity is device-scoped (stored via [SharedPreferences], not the
/// per-library project settings) since it should stay the same across every
/// `.classi` library opened on this device.
class DeviceIdentityService {
  static const String _deviceIdKey = 'device.id';
  static const String _deviceNameKey = 'device.name';
  static const String _idAlphabet = '0123456789abcdef';
  static const int _idLength = 16;

  /// Returns the stable random identifier for this device, generating and
  /// persisting one on first use.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateDeviceId();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  /// The user-chosen device label, or `null` if none has been set.
  Future<String?> storedDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_deviceNameKey);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  /// The device label to embed in exported backups: the user's chosen name,
  /// falling back to a generic platform-based label.
  Future<String> deviceName() async {
    return await storedDeviceName() ?? defaultDeviceName();
  }

  Future<void> setDeviceName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await prefs.remove(_deviceNameKey);
      return;
    }
    await prefs.setString(_deviceNameKey, trimmed);
  }

  /// A generic, non-identifying label derived from the current platform.
  ///
  /// Deliberately avoids the OS hostname, which often contains the owner's
  /// real name (e.g. "Alice's MacBook") and would otherwise be baked into
  /// every backup uploaded to a third-party WebDAV server.
  static String defaultDeviceName() {
    if (Platform.isIOS) return 'iPhone/iPad';
    if (Platform.isAndroid) return 'Android device';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isWindows) return 'Windows PC';
    if (Platform.isLinux) return 'Linux PC';
    return 'Device';
  }

  String _generateDeviceId() {
    final random = Random.secure();
    return List<String>.generate(
      _idLength,
      (_) => _idAlphabet[random.nextInt(_idAlphabet.length)],
    ).join();
  }
}
