import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/project_settings_store.dart';
import '../students/student_sorting.dart';

const _studentSortPreferenceKey = 'student_sort_field';
const _studentSortPath = ['students', 'sortField'];

class StudentSortController extends ChangeNotifier {
  StudentSortController({ProjectSettingsStore? projectSettingsStore})
    : _projectSettingsStore = projectSettingsStore ?? ProjectSettingsStore();

  final ProjectSettingsStore _projectSettingsStore;
  StudentSortField _sortField = StudentSortField.lastName;

  StudentSortField get sortField => _sortField;

  Future<void> initialize() async {
    final settings = await _projectSettingsStore.read();
    final stored = ProjectSettingsStore.stringAt(settings, _studentSortPath);
    if (stored != null) {
      _sortField = StudentSortFieldPersistence.fromStorage(stored);
      notifyListeners();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(_studentSortPreferenceKey);
    _sortField = StudentSortFieldPersistence.fromStorage(legacy);
    if (await _projectSettingsStore.hasProjectContainer()) {
      await _projectSettingsStore.update((projectSettings) {
        ProjectSettingsStore.setPath(
          projectSettings,
          _studentSortPath,
          _sortField.storageValue,
        );
        return projectSettings;
      });
      await preferences.remove(_studentSortPreferenceKey);
    }
    notifyListeners();
  }

  Future<void> setSortField(StudentSortField value) async {
    if (_sortField == value) {
      return;
    }

    _sortField = value;
    notifyListeners();

    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(
        settings,
        _studentSortPath,
        value.storageValue,
      );
      return settings;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_studentSortPreferenceKey);
  }
}
