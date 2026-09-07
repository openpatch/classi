import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/storage/project_settings_store.dart';
import '../lesson_support.dart';

/// How long the wheel remembers which students were already picked.
enum StudentPickerMemoryMode {
  /// No memory — every student is always eligible.
  off,

  /// Remember within a single lesson (per group and date).
  lesson,

  /// Remember across the entire school year (per group).
  schoolYear,
}

class StudentPickerController extends ChangeNotifier {
  StudentPickerController({
    required ProjectSettingsStore projectSettingsStore,
    required int groupId,
    required DateTime lessonDate,
  }) : _projectSettingsStore = projectSettingsStore,
       _groupId = groupId,
       _lessonDateKey = encodeLessonDate(lessonDate);

  final ProjectSettingsStore _projectSettingsStore;
  final int _groupId;
  final String _lessonDateKey;

  StudentPickerMemoryMode _memoryMode = StudentPickerMemoryMode.off;
  Set<int> _pickedStudentIds = const {};
  bool _isLoaded = false;

  // Settings writes are read-modify-write over one shared file, so they run
  // one after another instead of racing each other.
  Future<void> _pendingWrite = Future<void>.value();

  StudentPickerMemoryMode get memoryMode => _memoryMode;
  Set<int> get pickedStudentIds => UnmodifiableSetView(_pickedStudentIds);
  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    final settings = await _projectSettingsStore.read();
    _memoryMode = _parseMode(
      ProjectSettingsStore.stringAt(settings, _modePath),
    );
    _pickedStudentIds = _readPickedIds(settings, _memoryMode);
    _isLoaded = true;
    notifyListeners();
  }

  /// Switches the memory scope and adopts whatever that scope has stored.
  ///
  /// Switching never discards a scope's history — use [resetMemory] for that —
  /// so turning the memory off for one lesson does not lose the school year.
  Future<void> setMemoryMode(StudentPickerMemoryMode mode) async {
    if (mode == _memoryMode) return;
    _memoryMode = mode;
    notifyListeners();
    await _write((settings) {
      ProjectSettingsStore.setPath(settings, _modePath, _serializeMode(mode));
      _pickedStudentIds = _readPickedIds(settings, mode);
    });
    notifyListeners();
  }

  Future<void> markPicked(int studentId) async {
    if (_memoryMode == StudentPickerMemoryMode.off) return;
    if (_pickedStudentIds.contains(studentId)) return;
    _pickedStudentIds = {..._pickedStudentIds, studentId};
    notifyListeners();
    await _write((settings) => _writePickedIds(settings, _memoryMode));
  }

  /// Clears the memory once every student in [rosterIds] has had a turn, so
  /// the next spin starts a fresh round instead of keeping a full set forever.
  Future<void> startRound(Iterable<int> rosterIds) async {
    if (_memoryMode == StudentPickerMemoryMode.off) return;
    final roster = rosterIds.toSet();
    if (roster.isEmpty || !roster.every(_pickedStudentIds.contains)) return;
    await _startNewRound();
  }

  /// Forgets every round stored for this group, in all scopes.
  ///
  /// Clearing only the current scope would leave the school year unreachable
  /// whenever the picker is set to something else.
  Future<void> resetMemory() async {
    _pickedStudentIds = const {};
    notifyListeners();
    await _write(
      (settings) => ProjectSettingsStore.removePath(settings, _groupMemoryPath),
    );
  }

  /// Drops the picks of the current scope only, leaving the other one alone.
  Future<void> _startNewRound() async {
    if (_pickedStudentIds.isEmpty) return;
    _pickedStudentIds = const {};
    notifyListeners();
    await _write((settings) => _removePickedIds(settings, _memoryMode));
  }

  /// The students still eligible to be picked, given the full student list.
  ///
  /// When memory is off, every student is eligible. When all students have
  /// been picked, the set wraps around and everyone is eligible again — call
  /// [startRound] before spinning to clear the memory for the new round.
  List<T> eligibleStudents<T>(List<T> all, int Function(T) idOf) {
    if (_memoryMode == StudentPickerMemoryMode.off) return all;
    final remaining = [
      for (final item in all)
        if (!_pickedStudentIds.contains(idOf(item))) item,
    ];
    return remaining.isEmpty ? all : remaining;
  }

  List<String> get _modePath => [
    'studentPicker',
    'modeByGroup',
    'group_$_groupId',
  ];

  List<String> get _groupMemoryPath => [
    'studentPicker',
    'memory',
    'group_$_groupId',
  ];

  /// Where the picked ids of [mode] live, or `null` when the mode stores none.
  List<String>? _pickedPath(StudentPickerMemoryMode mode) {
    switch (mode) {
      case StudentPickerMemoryMode.off:
        return null;
      case StudentPickerMemoryMode.lesson:
        return [..._groupMemoryPath, 'byDate', _lessonDateKey];
      case StudentPickerMemoryMode.schoolYear:
        return [..._groupMemoryPath, 'schoolYear'];
    }
  }

  Set<int> _readPickedIds(
    Map<String, dynamic> settings,
    StudentPickerMemoryMode mode,
  ) {
    final path = _pickedPath(mode);
    if (path == null) return const {};
    final list = ProjectSettingsStore.listAt(settings, path);
    if (list == null) return const {};
    return {
      for (final value in list)
        if (value is int) value,
    };
  }

  void _writePickedIds(
    Map<String, dynamic> settings,
    StudentPickerMemoryMode mode,
  ) {
    final path = _pickedPath(mode);
    if (path == null) return;
    final ids = _pickedStudentIds.toList()..sort();
    if (mode == StudentPickerMemoryMode.lesson) {
      // Lesson memory only covers the lesson at hand, so replacing the whole
      // map drops the entries of earlier dates as a side effect.
      ProjectSettingsStore.setPath(
        settings,
        [..._groupMemoryPath, 'byDate'],
        {_lessonDateKey: ids},
      );
      return;
    }
    ProjectSettingsStore.setPath(settings, path, ids);
  }

  void _removePickedIds(
    Map<String, dynamic> settings,
    StudentPickerMemoryMode mode,
  ) {
    final path = _pickedPath(mode);
    if (path == null) return;
    ProjectSettingsStore.removePath(settings, path);
  }

  /// Applies [mutate] to the settings sidecar behind any write still in
  /// flight, so two updates cannot read the same state and overwrite each
  /// other.
  Future<void> _write(void Function(Map<String, dynamic> settings) mutate) {
    final write = _pendingWrite.then(
      (_) => _projectSettingsStore.update((settings) {
        mutate(settings);
        return settings;
      }),
    );
    // Keep the chain usable even if this write fails; the caller still sees it.
    _pendingWrite = write.catchError((Object _) {});
    return write;
  }

  static String _serializeMode(StudentPickerMemoryMode mode) {
    switch (mode) {
      case StudentPickerMemoryMode.off:
        return 'off';
      case StudentPickerMemoryMode.lesson:
        return 'lesson';
      case StudentPickerMemoryMode.schoolYear:
        return 'schoolYear';
    }
  }

  static StudentPickerMemoryMode _parseMode(String? value) {
    switch (value) {
      case 'lesson':
        return StudentPickerMemoryMode.lesson;
      case 'schoolYear':
        return StudentPickerMemoryMode.schoolYear;
      default:
        return StudentPickerMemoryMode.off;
    }
  }
}
