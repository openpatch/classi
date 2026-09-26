import 'dart:convert';

import 'package:classi/features/webuntis/webuntis_otp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeBase32', () {
    test('decodes the RFC 4648 test vectors', () {
      expect(utf8.decode(decodeBase32('MY======')), 'f');
      expect(utf8.decode(decodeBase32('MZXQ====')), 'fo');
      expect(utf8.decode(decodeBase32('MZXW6===')), 'foo');
      expect(utf8.decode(decodeBase32('MZXW6YTBOI======')), 'foobar');
    });

    test('is case insensitive and ignores separators', () {
      expect(decodeBase32('mzxw6==='), decodeBase32('MZXW6==='));
      expect(decodeBase32('MZXW 6-YTB-OI'), decodeBase32('MZXW6YTBOI'));
    });

    test('returns nothing for a secret with no Base32 characters', () {
      expect(decodeBase32('!!!'), isEmpty);
    });
  });

  group('webUntisOtp', () {
    // RFC 6238 appendix B, SHA-1 flavour. The shared secret is the ASCII
    // string "12345678901234567890", i.e. this Base32 value.
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    test('matches the RFC 6238 reference values', () {
      // WebUntis passes milliseconds where the RFC passes seconds.
      expect(webUntisOtp(secret: secret, clientTimeMillis: 59 * 1000), 287082);
      expect(
        webUntisOtp(secret: secret, clientTimeMillis: 1111111109 * 1000),
        81804,
      );
      expect(
        webUntisOtp(secret: secret, clientTimeMillis: 1234567890 * 1000),
        5924,
      );
      expect(
        webUntisOtp(secret: secret, clientTimeMillis: 2000000000 * 1000),
        279037,
      );
    });

    test('is stable inside a 30 second step and changes across one', () {
      const stepStart = 1234567890000;
      expect(
        webUntisOtp(secret: secret, clientTimeMillis: stepStart),
        webUntisOtp(secret: secret, clientTimeMillis: stepStart + 29000),
      );
      expect(
        webUntisOtp(secret: secret, clientTimeMillis: stepStart),
        isNot(webUntisOtp(secret: secret, clientTimeMillis: stepStart + 30000)),
      );
    });

    test('falls back to the anonymous code when there is no secret', () {
      expect(webUntisOtp(secret: '', clientTimeMillis: 1234567890000), 0);
      expect(webUntisOtp(secret: '!!!', clientTimeMillis: 1234567890000), 0);
    });
  });
}
