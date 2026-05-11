import 'dart:convert';
import 'dart:io';

import 'database_path_service.dart';

class ProjectSettingsStore {
  ProjectSettingsStore({DatabasePathService? databasePathService})
    : _databasePathService = databasePathService ?? DatabasePathService();

  final DatabasePathService _databasePathService;

  Future<Map<String, dynamic>> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  Future<void> write(Map<String, dynamic> settings) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings), flush: true);
  }

  Future<void> update(
    Map<String, dynamic> Function(Map<String, dynamic> current) transform,
  ) async {
    final current = await read();
    await write(transform(current));
  }

  Future<bool> hasProjectContainer() async {
    final databasePath = await _databasePathService.getCurrentDatabasePath();
    return _databasePathService.databasePathExists(databasePath);
  }

  Future<File> settingsFileForCurrentProject() => _settingsFile();

  Future<File> _settingsFile() async {
    final databasePath = await _databasePathService.getCurrentDatabasePath();
    return File(DatabasePathService.projectSettingsPathFor(databasePath));
  }

  static Object? valueAt(Map<String, dynamic> settings, List<String> path) {
    Object? current = settings;
    for (final segment in path) {
      if (current is! Map) {
        return null;
      }
      current = current[segment];
    }
    return current;
  }

  static String? stringAt(Map<String, dynamic> settings, List<String> path) {
    final value = valueAt(settings, path);
    return value is String ? value : null;
  }

  static bool? boolAt(Map<String, dynamic> settings, List<String> path) {
    final value = valueAt(settings, path);
    return value is bool ? value : null;
  }

  static int? intAt(Map<String, dynamic> settings, List<String> path) {
    final value = valueAt(settings, path);
    return value is int ? value : null;
  }

  static List<dynamic>? listAt(
    Map<String, dynamic> settings,
    List<String> path,
  ) {
    final value = valueAt(settings, path);
    return value is List ? List<dynamic>.from(value) : null;
  }

  static void setPath(
    Map<String, dynamic> settings,
    List<String> path,
    Object? value,
  ) {
    if (path.isEmpty) {
      return;
    }

    Map<String, dynamic> current = settings;
    for (var i = 0; i < path.length - 1; i++) {
      final segment = path[i];
      final next = current[segment];
      if (next is Map<String, dynamic>) {
        current = next;
        continue;
      }
      final replacement = <String, dynamic>{};
      current[segment] = replacement;
      current = replacement;
    }
    current[path.last] = value;
  }

  static void removePath(Map<String, dynamic> settings, List<String> path) {
    if (path.isEmpty) {
      return;
    }

    final parents = <Map<String, dynamic>>[];
    final segments = <String>[];
    Map<String, dynamic> current = settings;
    for (var i = 0; i < path.length - 1; i++) {
      final segment = path[i];
      final next = current[segment];
      if (next is! Map<String, dynamic>) {
        return;
      }
      parents.add(current);
      segments.add(segment);
      current = next;
    }

    current.remove(path.last);
    for (var i = parents.length - 1; i >= 0; i--) {
      final child = parents[i][segments[i]];
      if (child is Map<String, dynamic> && child.isEmpty) {
        parents[i].remove(segments[i]);
        continue;
      }
      break;
    }
  }
}
