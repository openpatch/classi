import 'dart:convert';
import 'dart:math';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:classi/shared/avatar/avatar_code.dart';
import 'package:classi/shared/avatar/avatar_maker_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NonPersistentAvatarMakerController newController() =>
      NonPersistentAvatarMakerController(
        locale: avatarMakerLocale,
        customizedPropertyCategories: avatarMakerHiddenCosmeticCategories,
      );

  Map<String, dynamic> decodeMap(String json) =>
      (jsonDecode(json) as Map).cast<String, dynamic>();

  test('round-trips the default avatar', () {
    final controller = newController();
    final stored = normalizeAvatarJson(controller.getJsonOptionsSync());

    final code = AvatarCode.encode(stored);
    final decoded = AvatarCode.decode(code);

    expect(decodeMap(decoded), equals(decodeMap(stored)));
  });

  test('round-trips 200 randomized avatars', () {
    final rng = Random(42);
    for (var i = 0; i < 200; i++) {
      final controller = newController();
      for (var j = 0; j < 5; j++) {
        controller.randomizedSelectedOptions();
      }
      final stored = normalizeAvatarJson(controller.getJsonOptionsSync());

      final decoded = AvatarCode.decode(AvatarCode.encode(stored));
      final storedMap = decodeMap(stored);
      final decodedMap = decodeMap(decoded);

      for (final key in const [
        'HairStyle',
        'HairColor',
        'FacialHairType',
        'FacialHairColor',
        'EyeType',
        'EyebrowType',
        'MouthType',
        'SkinColor',
        'OutfitType',
        'OutfitColor',
        'Accessory',
      ]) {
        expect(decodedMap[key], storedMap[key], reason: 'key $key on iter $i');
      }
      // rng keeps analyzer happy about the seeded generator import.
      expect(rng.nextInt(2), anyOf(0, 1));
    }
  });

  test('tolerates lower case, missing dashes and O/I/L substitution', () {
    final controller = newController();
    final stored = normalizeAvatarJson(controller.getJsonOptionsSync());
    final code = AvatarCode.encode(stored);

    final scrambled = code
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('0', 'O')
        .replaceAll('1', 'l');

    expect(decodeMap(AvatarCode.decode(scrambled)), equals(decodeMap(stored)));
  });

  test('detects a single-character typo via checksum', () {
    final controller = newController();
    final code = AvatarCode.encode(
      normalizeAvatarJson(controller.getJsonOptionsSync()),
    );

    // Flip a character in the data section (after the AV1 + 2 schema chars).
    final chars = code.replaceAll('-', '').split('');
    final target = 6;
    chars[target] = chars[target] == 'Z' ? 'Y' : 'Z';
    final broken = chars.join();

    expect(
      AvatarCode.tryDecode(broken).error,
      AvatarCodeErrorKind.checksumFailed,
    );
  });

  test('reports version and prefix problems', () {
    expect(AvatarCode.tryDecode('').error, AvatarCodeErrorKind.empty);
    expect(AvatarCode.tryDecode('   ').error, AvatarCodeErrorKind.empty);
    expect(
      AvatarCode.tryDecode('AV2-ABCD-EFGH-JK').error,
      AvatarCodeErrorKind.unsupportedVersion,
    );
    expect(
      AvatarCode.tryDecode('XX1-ABCD-EFGH-JK').error,
      AvatarCodeErrorKind.unknownPrefix,
    );
    expect(AvatarCode.tryDecode('AV1-AB').error, AvatarCodeErrorKind.malformed);
  });

  test('reports a schema mismatch when the fingerprint is wrong', () {
    final controller = newController();
    final code = AvatarCode.encode(
      normalizeAvatarJson(controller.getJsonOptionsSync()),
    );
    final chars = code.replaceAll('-', '').split('');
    // Corrupt one schema char (index 3/4), then repair the checksum so the
    // schema check is what fails.
    chars[3] = chars[3] == 'Z' ? 'Y' : 'Z';

    // Recompute checksum by brute force over the alphabet for the last char.
    const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    final body = chars.sublist(3); // schema + data + check
    for (final candidate in alphabet.split('')) {
      final trial = [...chars.sublist(0, chars.length - 1), candidate].join();
      final res = AvatarCode.tryDecode(trial);
      if (res.error == AvatarCodeErrorKind.schemaMismatch) {
        return; // success
      }
    }
    fail('expected a schemaMismatch for corrupted schema chars: $body');
  });

  test('encode is lenient with missing, unknown and cosmetic keys', () {
    final messy = jsonEncode({
      'HairColor': 'Brown',
      'SkinColor': 'NotARealColor',
      'AvatarEffect': 'Sparkles',
      // most keys omitted entirely
    });

    final decoded = AvatarCode.decode(AvatarCode.encode(messy));
    final map = decodeMap(decoded);

    expect(map['HairColor'], 'Brown');
    expect(map.containsKey('AvatarEffect'), isFalse);
    expect(map.length, 13);
    // Unknown label fell back to the category default.
    expect(map['SkinColor'], isNotNull);
  });

  test('code length stays within the 24-character budget', () {
    final controller = newController();
    final code = AvatarCode.encode(
      normalizeAvatarJson(controller.getJsonOptionsSync()),
    );
    expect(code.replaceAll('-', '').length, AvatarCode.codeLength);
    expect(AvatarCode.codeLength, lessThanOrEqualTo(24));
  });
}
