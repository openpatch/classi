import 'dart:convert';

import 'package:classi/shared/avatar/avatar_code.dart';
import 'package:classi/shared/utils/avatar_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanitizeAvatarSvg removes unsupported filters', () {
    const rawSvg = '''
<svg>
  <defs>
    <filter id="react-filter-1">
      <feOffset dx="1" dy="1" />
    </filter>
    <circle id="path-1" cx="10" cy="10" r="10" />
  </defs>
  <g filter="url(#react-filter-1)">
    <use xlink:href="#path-1" />
  </g>
</svg>
''';

    final sanitized = sanitizeAvatarSvg(rawSvg);

    expect(sanitized, isNot(contains('<filter')));
    expect(sanitized, isNot(contains('filter="url(#react-filter-1)"')));
    expect(sanitized, contains('<circle id="path-1"'));
  });

  test('avatarSvgFromJson renders a legacy 13-key payload', () {
    const legacy =
        '{"HairStyle":"ShortFlat","HairColor":"Brown","FacialHairType":"Nothing",'
        '"FacialHairColor":"Black","EyeType":"Default","EyebrowType":"Default",'
        '"Nose":"Default","MouthType":"Smile","SkinColor":"Brown",'
        '"OutfitType":"Hoodie","OutfitColor":"PastelBlue","Accessory":"Nothing",'
        '"Background":"Transparent"}';

    final svg = avatarSvgFromJson(legacy);
    expect(svg, isNotNull);
    expect(svg, contains('<svg'));
  });

  test('avatarSvgFromJson tolerates a 16-key payload with cosmetic keys', () {
    final map = <String, String>{
      ...jsonDecode(
        '{"HairStyle":"ShortFlat","HairColor":"Brown","FacialHairType":"Nothing",'
        '"FacialHairColor":"Black","EyeType":"Default","EyebrowType":"Default",'
        '"Nose":"Default","MouthType":"Smile","SkinColor":"Brown",'
        '"OutfitType":"Hoodie","OutfitColor":"PastelBlue","Accessory":"Nothing",'
        '"Background":"Transparent"}',
      ).cast<String, String>(),
      'AvatarBackground': 'None',
      'AvatarEffect': 'None',
      'AvatarEffectColor': 'None',
    };

    final svg = avatarSvgFromJson(jsonEncode(map));
    expect(svg, isNotNull);
    expect(svg, isNotEmpty);
  });

  test('avatarSvgFromJson renders an avatar decoded from a designer code', () {
    final json = AvatarCode.decode(
      AvatarCode.encode('{"HairColor":"Blue","OutfitColor":"Red"}'),
    );
    expect(avatarSvgFromJson(json), isNotNull);
  });
}
