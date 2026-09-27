import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `'key'.tr()` written out in full in [directory].
///
/// Keys built at runtime — an error code, a navigation label — cannot be found
/// this way and are not the ones that go missing unnoticed.
Set<String> _literalKeysUsedIn(Directory directory) {
  final pattern = RegExp(r"'([a-z0-9_]+)'\s*\.tr\(");
  return {
    for (final file in directory.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart'))
        ...pattern
            .allMatches(file.readAsStringSync())
            .map((match) => match.group(1)!),
  };
}

Map<String, dynamic> _translations(String locale) {
  return json.decode(
        File('assets/translations/$locale.json').readAsStringSync(),
      )
      as Map<String, dynamic>;
}

void main() {
  late Map<String, dynamic> english;
  late Map<String, dynamic> german;

  setUpAll(() {
    english = _translations('en');
    german = _translations('de');
  });

  test('every key the app asks for is translated', () {
    // A missing key reaches a teacher as the key itself printed on a button,
    // and the only warning is a line in the console nobody is reading.
    final used = _literalKeysUsedIn(Directory('lib'));

    expect(used.where((key) => !english.containsKey(key)), isEmpty);
    expect(used.where((key) => !german.containsKey(key)), isEmpty);
  });

  test('both languages carry the same keys', () {
    expect(english.keys.toSet().difference(german.keys.toSet()), isEmpty);
    expect(german.keys.toSet().difference(english.keys.toSet()), isEmpty);
  });

  test('no key is listed twice', () {
    // A JSON object may repeat a key and the last one silently wins, so a
    // stray copy further down overrides the text everyone reviewed.
    for (final locale in ['en', 'de']) {
      final keys = RegExp(r'^  "([^"]+)":', multiLine: true)
          .allMatches(
            File('assets/translations/$locale.json').readAsStringSync(),
          )
          .map((match) => match.group(1)!)
          .toList();
      final seen = <String>{};
      expect(
        keys.where((key) => !seen.add(key)),
        isEmpty,
        reason: '$locale.json repeats these keys',
      );
    }
  });

  test('no translation is left empty', () {
    for (final entry in {...english, ...german}.entries) {
      expect(
        '${entry.value}'.trim(),
        isNotEmpty,
        reason: '${entry.key} has nothing to show',
      );
    }
  });
}
