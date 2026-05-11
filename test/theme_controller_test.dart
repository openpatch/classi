import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/core/storage/project_settings_store.dart';
import 'package:classi/features/settings/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late String projectPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp('classi-theme');
    projectPath = '${tempDirectory.path}/project.classi';
    await Directory(projectPath).create(recursive: true);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('defaults to system theme mode', () async {
    final controller = _controllerFor(projectPath);
    await controller.initialize();

    expect(controller.themeMode, ThemeMode.system);
  });

  test('sets and persists theme mode inside the current project', () async {
    final controller = _controllerFor(projectPath);
    await controller.initialize();

    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);

    final controller2 = _controllerFor(projectPath);
    await controller2.initialize();
    expect(controller2.themeMode, ThemeMode.dark);
  });

  test('theme mode does not leak across projects', () async {
    final firstProjectController = _controllerFor(projectPath);
    await firstProjectController.initialize();
    await firstProjectController.setThemeMode(ThemeMode.dark);

    final secondProjectPath = '${tempDirectory.path}/second.classi';
    await Directory(secondProjectPath).create(recursive: true);
    final secondProjectController = _controllerFor(secondProjectPath);
    await secondProjectController.initialize();

    expect(secondProjectController.themeMode, ThemeMode.system);
  });

  test('setThemeMode notifies listeners', () async {
    final controller = _controllerFor(projectPath);
    await controller.initialize();

    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setThemeMode(ThemeMode.light);
    expect(notified, isTrue);
  });

  test('setThemeMode skips update when value is unchanged', () async {
    final controller = _controllerFor(projectPath);
    await controller.initialize();

    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.setThemeMode(ThemeMode.system);
    expect(notifyCount, 0);
  });

  test('migrates a legacy global value into the current project', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});

    final controller = _controllerFor(projectPath);
    await controller.initialize();

    expect(controller.themeMode, ThemeMode.dark);

    final reloaded = _controllerFor(projectPath);
    await reloaded.initialize();
    expect(reloaded.themeMode, ThemeMode.dark);
  });
}

ThemeController _controllerFor(String projectPath) {
  return ThemeController(
    projectSettingsStore: ProjectSettingsStore(
      databasePathService: _FixedDatabasePathService(projectPath),
    ),
  );
}

class _FixedDatabasePathService extends DatabasePathService {
  _FixedDatabasePathService(this._databasePath);

  final String _databasePath;

  @override
  Future<String> getCurrentDatabasePath() async => _databasePath;
}
