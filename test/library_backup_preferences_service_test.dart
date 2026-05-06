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
    expect(await service.webDavUrl(), isNull);
    expect(await service.webDavUsername(), isNull);
    expect(await service.webDavServerPath(), isNull);

    await service.setAutoExportEnabled(true);
    await service.setAutoImportEnabled(true);
    await service.setWebDavUrl('https://dav.example.com/remote.php/dav/files/user/');
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
}
