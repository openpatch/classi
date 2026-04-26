import 'package:clari/shared/utils/avatar_preview.dart';
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
}
