import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// One-time password generation for the WebUntis mobile API.
///
/// WebUntis does not hand out a session cookie for the mobile endpoint. It
/// hands out an *app shared secret* once (in exchange for the password) and
/// then expects every request to carry a time-based one-time password derived
/// from it. Storing the secret instead of the password means a stolen library
/// never leaks a teacher's WebUntis login, and the school can revoke access by
/// resetting the secret.
///
/// The scheme is plain RFC 6238 TOTP: HMAC-SHA1, a 30 second time step and six
/// digits, with the counter taken from the client's own clock. WebUntis
/// rejects a request whose `clientTime` drifts too far from the server, which
/// surfaces as [WebUntisErrorCode.invalidClientTime].
const int _timeStepMillis = 30000;

/// Decodes an RFC 4648 Base32 string (the format WebUntis returns the app
/// shared secret in) into its raw bytes.
///
/// Characters outside the alphabet — padding, spaces, dashes — are skipped,
/// so a secret copied out of a QR code or an e-mail still works.
Uint8List decodeBase32(String input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  var buffer = 0;
  var bitsInBuffer = 0;
  final bytes = <int>[];

  for (final rune in input.toUpperCase().runes) {
    final value = alphabet.indexOf(String.fromCharCode(rune));
    if (value < 0) {
      continue;
    }
    buffer = (buffer << 5) | value;
    bitsInBuffer += 5;
    if (bitsInBuffer >= 8) {
      bitsInBuffer -= 8;
      bytes.add((buffer >> bitsInBuffer) & 0xFF);
    }
  }

  return Uint8List.fromList(bytes);
}

/// The six digit one-time password WebUntis expects alongside [clientTimeMillis].
///
/// [secret] is the Base32 app shared secret returned by `getAppSharedSecret`.
/// An empty secret yields `0`, which is what the anonymous WebUntis user sends.
int webUntisOtp({required String secret, required int clientTimeMillis}) {
  if (secret.isEmpty) {
    return 0;
  }

  final key = decodeBase32(secret);
  if (key.isEmpty) {
    return 0;
  }

  final counter = clientTimeMillis ~/ _timeStepMillis;
  final counterBytes = Uint8List(8);
  var remaining = counter;
  for (var i = 7; i >= 0; i--) {
    counterBytes[i] = remaining & 0xFF;
    remaining >>= 8;
  }

  final digest = Hmac(sha1, key).convert(counterBytes).bytes;

  // RFC 4226 dynamic truncation: the low nibble of the last byte picks the
  // four byte window that carries the code.
  final offset = digest[digest.length - 1] & 0x0F;
  final binary =
      ((digest[offset] & 0x7F) << 24) |
      ((digest[offset + 1] & 0xFF) << 16) |
      ((digest[offset + 2] & 0xFF) << 8) |
      (digest[offset + 3] & 0xFF);

  return binary % 1000000;
}
