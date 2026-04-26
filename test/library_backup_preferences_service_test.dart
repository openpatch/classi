import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/core/storage/library_backup_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores auto export and import preferences', () async {
    final service = LibraryBackupPreferencesService();

    expect(await service.autoExportEnabled(), isFalse);
    expect(await service.autoImportEnabled(), isFalse);
    expect(await service.autoExportFolderPath(), isNull);
    expect(await service.autoImportBackupPath(), isNull);

    await service.setAutoExportEnabled(true);
    await service.setAutoExportFolderPath('/tmp/exports');
    await service.setAutoImportEnabled(true);
    await service.setAutoImportBackupPath('/tmp/exports/class-a.classi-backup');

    expect(await service.autoExportEnabled(), isTrue);
    expect(await service.autoImportEnabled(), isTrue);
    expect(await service.autoExportFolderPath(), '/tmp/exports');
    expect(
      await service.autoImportBackupPath(),
      '/tmp/exports/class-a.classi-backup',
    );
  });
}
