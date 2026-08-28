import 'dart:collection';
import 'dart:convert';

import 'package:avatar_maker/avatar_maker.dart';

import 'avatar_maker_config.dart';

/// Why an avatar code could not be decoded.
enum AvatarCodeErrorKind {
  /// The input was empty or whitespace only.
  empty,

  /// The code does not start with a recognized prefix.
  unknownPrefix,

  /// The code is a future/older format this build cannot read.
  unsupportedVersion,

  /// The code was produced against a different `avatar_maker` option set.
  schemaMismatch,

  /// The checksum character does not match — almost certainly a typo.
  checksumFailed,

  /// The code is structurally broken (wrong length, junk payload).
  malformed,
}

/// Thrown by [AvatarCode.decode] (and [AvatarCode.encode] for empty input).
class AvatarCodeException implements Exception {
  const AvatarCodeException(this.kind, this.message);

  final AvatarCodeErrorKind kind;
  final String message;

  @override
  String toString() => 'AvatarCodeException($kind): $message';
}

/// Converts an avatar option payload to a short human-transferable code and
/// back.
///
/// The code looks like `AV1-XXXX-XXXX-XX`: a 3-char format prefix, a 2-char
/// schema fingerprint, a packed data section and a 1-char checksum, uppercased
/// and regrouped into dash-separated blocks of four. Dashes, spaces and case
/// are cosmetic; `O`/`I`/`L` are accepted as `0`/`1`/`1`.
///
/// Each of the 11 student-editable categories is encoded as the index of the
/// chosen option within that category's option list (read at runtime from the
/// pinned `avatar_maker` version), mixed-radix packed into one integer, then
/// Crockford base32. `Nose` and `Background` are never encoded — students
/// cannot change them — and are restored to their defaults on decode.
class AvatarCode {
  AvatarCode._();

  static const String _prefix = 'AV1';
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const int _schemaChars = 2;

  /// Categories encoded in the code, in a fixed order. Do not reorder — that
  /// would silently invalidate every previously issued code.
  static const List<PropertyCategoryIds> _order = [
    PropertyCategoryIds.HairStyle,
    PropertyCategoryIds.HairColor,
    PropertyCategoryIds.FacialHairType,
    PropertyCategoryIds.FacialHairColor,
    PropertyCategoryIds.EyeType,
    PropertyCategoryIds.EyebrowType,
    PropertyCategoryIds.MouthType,
    PropertyCategoryIds.SkinColor,
    PropertyCategoryIds.OutfitType,
    PropertyCategoryIds.OutfitColor,
    PropertyCategoryIds.Accessory,
  ];

  /// Categories restored to their default value on decode.
  static const List<PropertyCategoryIds> _defaulted = [
    PropertyCategoryIds.Nose,
    PropertyCategoryIds.Background,
  ];

  static PropertyCategory _category(PropertyCategoryIds id) =>
      defaultPropertyCategories.firstWhere((c) => c.id == id);

  static List<int> get _radices =>
      _order.map((id) => _category(id).properties.length).toList();

  /// Number of significant characters in a code (dashes excluded).
  static int get codeLength {
    final bits = _combinations.bitLength;
    final dataChars = (bits + 4) ~/ 5; // ceil(bits / 5)
    return _prefix.length + _schemaChars + dataChars + 1;
  }

  static BigInt get _combinations {
    var product = BigInt.one;
    for (final r in _radices) {
      product *= BigInt.from(r);
    }
    return product;
  }

  static int get _dataChars => (_combinations.bitLength + 4) ~/ 5;

  /// Small web-safe rolling hash of the current option-set shape. Guards
  /// against an `avatar_maker` upgrade that changes an option list without a
  /// matching `AV1` -> `AV2` bump.
  static String _schemaFingerprint() {
    final shape = [
      for (final id in _order) '${id.name}:${_category(id).properties.length}',
    ].join(',');
    var h = 0;
    for (final unit in shape.codeUnits) {
      h = (h * 31 + unit) % 1024; // 10 bits -> 2 base32 chars
    }
    return _alphabet[h ~/ 32] + _alphabet[h % 32];
  }

  static String _checksum(String body) {
    var sum = 0;
    for (var i = 0; i < body.length; i++) {
      sum = (sum + (i + 1) * _alphabet.indexOf(body[i])) % 32;
    }
    return _alphabet[sum];
  }

  static String _group(String raw) {
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i += 4) {
      if (i > 0) buf.write('-');
      buf.write(raw.substring(i, i + 4 > raw.length ? raw.length : i + 4));
    }
    return buf.toString();
  }

  /// Encodes an avatar option payload (as stored in `students.avatarJson`).
  ///
  /// Lenient: missing, unknown or cosmetic keys fall back to the category
  /// default rather than throwing. Throws [AvatarCodeException] only when
  /// [avatarJson] is not a JSON object.
  static String encode(String avatarJson) {
    final Map<String, dynamic> map;
    try {
      map = (jsonDecode(normalizeAvatarJson(avatarJson)) as Map)
          .cast<String, dynamic>();
    } on FormatException catch (e) {
      throw AvatarCodeException(AvatarCodeErrorKind.malformed, e.message);
    }

    final radices = _radices;
    var n = BigInt.zero;
    for (var i = 0; i < _order.length; i++) {
      final category = _category(_order[i]);
      final label = map[_order[i].name];
      var idx = category.properties.indexWhere((p) => p.label == label);
      if (idx < 0) {
        idx = category.properties.indexWhere(
          (p) => p.label == category.defaultValue.label,
        );
      }
      if (idx < 0) idx = 0;
      n = n * BigInt.from(radices[i]) + BigInt.from(idx);
    }

    final data = _toBase32(n, _dataChars);
    final schema = _schemaFingerprint();
    final check = _checksum(schema + data);
    return _group(_prefix + schema + data + check);
  }

  /// Decodes a code to an avatar option payload (a compact 13-key JSON object
  /// string). Throws [AvatarCodeException] on any problem.
  static String decode(String code) {
    final result = tryDecode(code);
    if (result.error != null) {
      throw AvatarCodeException(result.error!, _messageFor(result.error!));
    }
    return result.avatarJson!;
  }

  /// Non-throwing variant of [decode].
  static ({String? avatarJson, AvatarCodeErrorKind? error}) tryDecode(
    String code,
  ) {
    final cleaned = _clean(code);
    if (cleaned.isEmpty) {
      return (avatarJson: null, error: AvatarCodeErrorKind.empty);
    }

    if (!cleaned.startsWith(_prefix)) {
      final looksVersioned =
          cleaned.length >= 3 &&
          cleaned.startsWith('AV') &&
          _isDigit(cleaned[2]);
      return (
        avatarJson: null,
        error: looksVersioned
            ? AvatarCodeErrorKind.unsupportedVersion
            : AvatarCodeErrorKind.unknownPrefix,
      );
    }

    final body = cleaned.substring(_prefix.length);
    final dataChars = _dataChars;
    if (body.length != _schemaChars + dataChars + 1) {
      return (avatarJson: null, error: AvatarCodeErrorKind.malformed);
    }

    final schema = body.substring(0, _schemaChars);
    final data = body.substring(_schemaChars, _schemaChars + dataChars);
    final check = body.substring(_schemaChars + dataChars);

    if (_checksum(schema + data) != check) {
      return (avatarJson: null, error: AvatarCodeErrorKind.checksumFailed);
    }
    if (schema != _schemaFingerprint()) {
      return (avatarJson: null, error: AvatarCodeErrorKind.schemaMismatch);
    }

    final decoded = _fromBase32(data);
    if (decoded == null) {
      return (avatarJson: null, error: AvatarCodeErrorKind.malformed);
    }

    final radices = _radices;
    final indices = List<int>.filled(_order.length, 0);
    var n = decoded;
    for (var i = _order.length - 1; i >= 0; i--) {
      final radix = BigInt.from(radices[i]);
      indices[i] = (n % radix).toInt();
      n = n ~/ radix;
    }
    if (n != BigInt.zero) {
      return (avatarJson: null, error: AvatarCodeErrorKind.malformed);
    }

    final map = SplayTreeMap<String, String>();
    for (var i = 0; i < _order.length; i++) {
      map[_order[i].name] = _category(_order[i]).properties[indices[i]].label;
    }
    for (final id in _defaulted) {
      map[id.name] = _category(id).defaultValue.label;
    }
    return (avatarJson: jsonEncode(map), error: null);
  }

  static String _messageFor(AvatarCodeErrorKind kind) => switch (kind) {
    AvatarCodeErrorKind.empty => 'No code was entered.',
    AvatarCodeErrorKind.unknownPrefix => 'Not an avatar code.',
    AvatarCodeErrorKind.unsupportedVersion =>
      'This avatar code uses an unsupported format version.',
    AvatarCodeErrorKind.schemaMismatch =>
      'This avatar code was made with a different app version.',
    AvatarCodeErrorKind.checksumFailed => 'This avatar code looks mistyped.',
    AvatarCodeErrorKind.malformed => 'This avatar code is not valid.',
  };

  static String _clean(String code) {
    final buf = StringBuffer();
    for (final ch in code.toUpperCase().split('')) {
      final mapped = switch (ch) {
        'O' => '0',
        'I' || 'L' => '1',
        _ => ch,
      };
      if (_alphabet.contains(mapped)) buf.write(mapped);
    }
    return buf.toString();
  }

  static bool _isDigit(String ch) =>
      ch.length == 1 && '0123456789'.contains(ch);

  static String _toBase32(BigInt value, int width) {
    final chars = <String>[];
    var v = value;
    final base = BigInt.from(32);
    while (v > BigInt.zero) {
      chars.add(_alphabet[(v % base).toInt()]);
      v = v ~/ base;
    }
    while (chars.length < width) {
      chars.add('0');
    }
    return chars.reversed.join();
  }

  static BigInt? _fromBase32(String data) {
    var n = BigInt.zero;
    final base = BigInt.from(32);
    for (final ch in data.split('')) {
      final digit = _alphabet.indexOf(ch);
      if (digit < 0) return null;
      n = n * base + BigInt.from(digit);
    }
    return n;
  }
}
