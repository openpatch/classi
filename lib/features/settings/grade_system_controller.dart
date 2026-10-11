import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/project_settings_store.dart';
import '../../shared/utils/formatting.dart';

class GradeSystemDefinition {
  const GradeSystemDefinition({
    required this.id,
    required this.name,
    required this.entries,
    this.gradesPerRow,
  });

  final String id;
  final String name;
  final List<GradeScaleEntry> entries;

  /// How many grades the grade picker shows side-by-side per row before
  /// starting a new one. `null` lets the picker wrap automatically.
  final int? gradesPerRow;

  GradeSystemDefinition copyWith({
    String? id,
    String? name,
    List<GradeScaleEntry>? entries,
    int? gradesPerRow,
  }) {
    return GradeSystemDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      entries: entries ?? this.entries,
      gradesPerRow: gradesPerRow ?? this.gradesPerRow,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'entries': [for (final entry in entries) entry.toJson()],
    if (gradesPerRow != null) 'gradesPerRow': gradesPerRow as Object,
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

    final gradesPerRowRaw = raw['gradesPerRow'];
    final gradesPerRow = gradesPerRowRaw is num
        ? gradesPerRowRaw.toInt()
        : int.tryParse(gradesPerRowRaw?.toString() ?? '');

    return GradeSystemDefinition(
      id: id,
      name: name,
      entries: entries,
      gradesPerRow: gradesPerRow != null && gradesPerRow > 0
          ? gradesPerRow
          : null,
    );
  }
}

class GradeSystemController extends ChangeNotifier {
  static const _storageKey = 'grade-systems-json';
  static const _storagePath = ['grades', 'systems'];

  GradeSystemController({ProjectSettingsStore? projectSettingsStore})
    : _projectSettingsStore = projectSettingsStore ?? ProjectSettingsStore();

  final ProjectSettingsStore _projectSettingsStore;

  List<GradeSystemDefinition> _systems = const [];
  bool _initialized = false;

  List<GradeSystemDefinition> get systems => _systems;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final settings = await _projectSettingsStore.read();
    final storedJson = _storedJsonFromProjectSettings(settings);
    if (storedJson == null || storedJson.trim().isEmpty) {
      final preferences = await SharedPreferences.getInstance();
      final legacyJson = preferences.getString(_storageKey);
      if (legacyJson != null && legacyJson.trim().isNotEmpty) {
        await _loadFromStoredJson(legacyJson);
        if (await _projectSettingsStore.hasProjectContainer()) {
          await preferences.remove(_storageKey);
        }
        return;
      }
      _systems = _defaultSystems;
      if (await _projectSettingsStore.hasProjectContainer()) {
        await _persist();
      } else {
        _initialized = true;
        notifyListeners();
      }
      return;
    }

    await _loadFromStoredJson(storedJson);
  }

  Future<void> _loadFromStoredJson(String storedJson) async {
    final decoded = jsonDecode(storedJson);
    if (decoded is! List) {
      _systems = _defaultSystems;
      if (await _projectSettingsStore.hasProjectContainer()) {
        await _persist();
      }
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
    if (parsed.isEmpty && await _projectSettingsStore.hasProjectContainer()) {
      await _persist();
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

  /// The number of grades the picker shows side-by-side for groups using
  /// [entries], from the matching grade system. `null` when no system matches
  /// or the system leaves the value unset.
  int? gradesPerRowFor(List<GradeScaleEntry> entries) {
    return matchingSystem(entries)?.gradesPerRow;
  }

  Future<void> addSystem({
    required String name,
    required List<GradeScaleEntry> entries,
    int? gradesPerRow,
  }) async {
    _systems = [
      ..._systems,
      GradeSystemDefinition(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
        entries: entries,
        gradesPerRow: gradesPerRow,
      ),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> updateSystem({
    required String id,
    required String name,
    required List<GradeScaleEntry> entries,
    int? gradesPerRow,
  }) async {
    _systems = [
      for (final system in _systems)
        if (system.id == id)
          GradeSystemDefinition(
            id: system.id,
            name: name.trim(),
            entries: entries,
            gradesPerRow: gradesPerRow,
          )
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

  Future<void> _persist() async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, _storagePath, [
        for (final system in _systems) system.toJson(),
      ]);
      return settings;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  String? _storedJsonFromProjectSettings(Map<String, dynamic> settings) {
    final storedList = ProjectSettingsStore.listAt(settings, _storagePath);
    if (storedList == null) {
      return null;
    }
    return jsonEncode(storedList);
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
      gradesPerRow: 3,
    ),
  ];
}
