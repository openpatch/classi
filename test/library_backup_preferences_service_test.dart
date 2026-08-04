import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/core/storage/library_backup_preferences_service.dart';
import 'package:classi/core/storage/project_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late String projectPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp(
      'classi-backup-prefs',
    );
    projectPath = '${tempDirectory.path}/project.classi';
    await Directory(projectPath).create(recursive: true);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('stores backup preferences inside the current project', () async {
    final service = _serviceFor(projectPath);

    expect(await service.autoExportEnabled(), isFalse);
    expect(await service.autoImportEnabled(), isFalse);
    expect(await service.webDavUrl(), isNull);
    expect(await service.webDavUsername(), isNull);
    expect(await service.webDavServerPath(), isNull);

    await service.setAutoExportEnabled(true);
    await service.setAutoImportEnabled(true);
    await service.setWebDavUrl(
      'https://dav.example.com/remote.php/dav/files/user/',
    );
    await service.setWebDavUsername('alice');
    await service.setWebDavServerPath('/classi-backups/');

    expect(await service.autoExportEnabled(), isTrue);
    expect(await service.autoImportEnabled(), isTrue);
    expect(
      await service.webDavUrl(),
      'https://dav.example.com/remote.php/dav/files/user/',
    );
    expect(await service.webDavUsername(), 'alice');
    expect(await service.webDavServerPath(), '/classi-backups/');
  });

  test('stores and clears the last known sync revision', () async {
    final service = _serviceFor(projectPath);

    expect(await service.lastKnownRevision(), isNull);

    await service.setLastKnownRevision('device-a-1');
    expect(await service.lastKnownRevision(), 'device-a-1');

    await service.setLastKnownRevision(null);
    expect(await service.lastKnownRevision(), isNull);
  });

  test('backup preferences do not leak across projects', () async {
    final firstProject = _serviceFor(projectPath);
    await firstProject.setAutoExportEnabled(true);
    await firstProject.setWebDavUrl('https://dav.example.com/a');

    final secondProjectPath = '${tempDirectory.path}/second.classi';
    await Directory(secondProjectPath).create(recursive: true);
    final secondProject = _serviceFor(secondProjectPath);

    expect(await secondProject.autoExportEnabled(), isFalse);
    expect(await secondProject.webDavUrl(), isNull);
  });
}

LibraryBackupPreferencesService _serviceFor(String projectPath) {
  return LibraryBackupPreferencesService(
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
