import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/features/settings/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system theme mode', () async {
    final controller = ThemeController();
    await controller.initialize();

    expect(controller.themeMode, ThemeMode.system);
  });

  test('sets and persists theme mode', () async {
    final controller = ThemeController();
    await controller.initialize();

    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);

    // A new controller loaded from the same preferences should restore the value.
    final controller2 = ThemeController();
    await controller2.initialize();
    expect(controller2.themeMode, ThemeMode.dark);
  });

  test('setThemeMode notifies listeners', () async {
    final controller = ThemeController();
    await controller.initialize();

    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setThemeMode(ThemeMode.light);
    expect(notified, isTrue);
  });

  test('setThemeMode skips update when value is unchanged', () async {
    final controller = ThemeController();
    await controller.initialize();

    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.setThemeMode(ThemeMode.system);
    expect(notifyCount, 0);
  });

  test('loads persisted light and auto theme modes correctly', () async {
    for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
      SharedPreferences.setMockInitialValues({});

      final writer = ThemeController();
      await writer.initialize();
      await writer.setThemeMode(mode);

      final reader = ThemeController();
      await reader.initialize();
      expect(reader.themeMode, mode);
    }
  });

  test('falls back to system for unknown persisted value', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'unknown'});

    final controller = ThemeController();
    await controller.initialize();
    expect(controller.themeMode, ThemeMode.system);
  });
}
