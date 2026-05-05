import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModePreferenceKey = 'app_theme_mode';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromStorage(
      preferences.getString(_themeModePreferenceKey),
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) {
      return;
    }

    _themeMode = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModePreferenceKey, _storageValue(value));
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
