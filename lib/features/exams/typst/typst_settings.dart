import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'exam_typst_workflow.dart';

/// Typst settings that belong to this device, not to the library: the path
/// of the `typst` binary and where each exam's document lives. Paths mean
/// nothing on another computer, so none of this is synced.
class TypstSettingsStore {
  static const _binaryKey = 'typst.binary_path';
  static const _linksKey = 'typst.exam_links';

  Future<String?> binaryPath() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_binaryKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setBinaryPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(_binaryKey);
    } else {
      await prefs.setString(_binaryKey, path.trim());
    }
  }

  /// Links are keyed by library and exam: exam ids repeat across libraries.
  static String linkKey(String databasePath, int examId) =>
      '$databasePath#$examId';

  Future<TypstLink?> link(String databasePath, int examId) async {
    return TypstLink.fromJson((await _links())[linkKey(databasePath, examId)]);
  }

  Future<void> setLink(String databasePath, int examId, TypstLink? link) async {
    final links = await _links();
    final key = linkKey(databasePath, examId);
    if (link == null) {
      links.remove(key);
    } else {
      links[key] = link.toJson();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_linksKey, jsonEncode(links));
  }

  Future<Map<String, Object?>> _links() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_linksKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, Object?>.from(decoded) : {};
    } on FormatException {
      return {};
    }
  }
}
