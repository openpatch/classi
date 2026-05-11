import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/project_settings_store.dart';

const _themeModePreferenceKey = 'app_theme_mode';
const _themeModePath = ['appearance', 'themeMode'];

class ThemeController extends ChangeNotifier {
  ThemeController({ProjectSettingsStore? projectSettingsStore})
    : _projectSettingsStore = projectSettingsStore ?? ProjectSettingsStore();

  final ProjectSettingsStore _projectSettingsStore;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    final settings = await _projectSettingsStore.read();
    final stored = ProjectSettingsStore.stringAt(settings, _themeModePath);
    if (stored != null) {
      _themeMode = _themeModeFromStorage(stored);
      notifyListeners();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(_themeModePreferenceKey);
    _themeMode = _themeModeFromStorage(legacy);
    if (await _projectSettingsStore.hasProjectContainer()) {
      await _projectSettingsStore.update((projectSettings) {
        ProjectSettingsStore.setPath(
          projectSettings,
          _themeModePath,
          _storageValue(_themeMode),
        );
        return projectSettings;
      });
      await preferences.remove(_themeModePreferenceKey);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) {
      return;
    }

    _themeMode = value;
    notifyListeners();

    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(
        settings,
        _themeModePath,
        _storageValue(value),
      );
      return settings;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_themeModePreferenceKey);
  }

  static ThemeMode _themeModeFromStorage(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _storageValue(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
