import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/utils/formatting.dart';

class GradeSystemDefinition {
  const GradeSystemDefinition({
    required this.id,
    required this.name,
    required this.entries,
  });

  final String id;
  final String name;
  final List<GradeScaleEntry> entries;

  GradeSystemDefinition copyWith({
    String? id,
    String? name,
    List<GradeScaleEntry>? entries,
  }) {
    return GradeSystemDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      entries: entries ?? this.entries,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'entries': [for (final entry in entries) entry.toJson()],
  };

  static GradeSystemDefinition? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final id = raw['id']?.toString().trim();
    final name = raw['name']?.toString().trim();
    final entriesRaw = raw['entries'];
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    if (entriesRaw is! List) {
      return null;
    }

    final entries = <GradeScaleEntry>[];
    for (final entry in entriesRaw) {
      if (entry is! Map) {
        continue;
      }
      final label = entry['label']?.toString().trim();
      final numericValue = entry['numericValue'];
      final parsedNumericValue = numericValue is num
          ? numericValue.toDouble()
          : double.tryParse(numericValue?.toString() ?? '');
      if (label == null || label.isEmpty || parsedNumericValue == null) {
        continue;
      }
      entries.add(
        GradeScaleEntry(label: label, numericValue: parsedNumericValue),
      );
    }

    if (entries.isEmpty) {
      return null;
    }

    return GradeSystemDefinition(id: id, name: name, entries: entries);
  }
}

class GradeSystemController extends ChangeNotifier {
  static const _storageKey = 'grade-systems-json';

  List<GradeSystemDefinition> _systems = const [];
  bool _initialized = false;

  List<GradeSystemDefinition> get systems => _systems;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final storedJson = preferences.getString(_storageKey);
    if (storedJson == null || storedJson.trim().isEmpty) {
      _systems = _defaultSystems;
      await _persist(preferences);
      _initialized = true;
      notifyListeners();
      return;
    }

    final decoded = jsonDecode(storedJson);
    if (decoded is! List) {
      _systems = _defaultSystems;
      await _persist(preferences);
      _initialized = true;
      notifyListeners();
      return;
    }

    final parsed = <GradeSystemDefinition>[];
    for (final entry in decoded) {
      final system = GradeSystemDefinition.fromJson(entry);
      if (system != null) {
        parsed.add(system);
      }
    }

    _systems = parsed.isEmpty ? _defaultSystems : parsed;
    if (parsed.isEmpty) {
      await _persist(preferences);
    }
    _initialized = true;
    notifyListeners();
  }

  GradeSystemDefinition? findById(String id) {
    for (final system in _systems) {
      if (system.id == id) {
        return system;
      }
    }
    return null;
  }

  GradeSystemDefinition? matchingSystem(List<GradeScaleEntry> entries) {
    for (final system in _systems) {
      if (sameGradeScaleEntries(system.entries, entries)) {
        return system;
      }
    }
    return null;
  }

  Future<void> addSystem({
    required String name,
    required List<GradeScaleEntry> entries,
  }) async {
    _systems = [
      ..._systems,
      GradeSystemDefinition(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
        entries: entries,
      ),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> updateSystem({
    required String id,
    required String name,
    required List<GradeScaleEntry> entries,
  }) async {
    _systems = [
      for (final system in _systems)
        if (system.id == id)
          system.copyWith(name: name.trim(), entries: entries)
        else
          system,
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> deleteSystem(String id) async {
    _systems = [
      for (final system in _systems)
        if (system.id != id) system,
    ];
    if (_systems.isEmpty) {
      _systems = _defaultSystems;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist([SharedPreferences? preferences]) async {
    final resolvedPreferences =
        preferences ?? await SharedPreferences.getInstance();
    await resolvedPreferences.setString(
      _storageKey,
      jsonEncode([for (final system in _systems) system.toJson()]),
    );
  }

  List<GradeSystemDefinition> get _defaultSystems => const [
    GradeSystemDefinition(
      id: 'default-1-6',
      name: '1-6',
      entries: defaultGradeScaleEntries,
    ),
    GradeSystemDefinition(
      id: 'default-extended',
      name: '1+/1/1-/.../6',
      entries: defaultExtendedGradeScaleEntries,
    ),
    GradeSystemDefinition(
      id: 'default-points',
      name: '15-0',
      entries: defaultPointGradeScaleEntries,
    ),
  ];
}
