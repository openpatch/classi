import 'dart:io';

import 'package:local_auth/local_auth.dart';

/// Wraps [LocalAuthentication] to provide biometric availability checks and
/// authentication on Android, iOS, and macOS.
///
/// On platforms that do not support biometrics (e.g. Windows, Linux) all
/// methods return safe defaults without throwing.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns `true` when the current platform potentially supports biometrics.
  bool get _platformSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  /// Returns `true` when the device supports biometric authentication and at
  /// least one biometric credential is enrolled.
  Future<bool> isAvailable() async {
    if (!_platformSupported) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Presents the system biometric prompt with [localizedReason] as the
  /// explanatory text.
  ///
  /// Returns `true` when the user has been successfully authenticated,
  /// `false` otherwise (user cancelled, not enrolled, hardware error, etc.).
  Future<bool> authenticate({required String localizedReason}) async {
    if (!_platformSupported) return false;
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
