import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clari/core/providers/app_providers.dart';
import 'package:clari/core/security/key_service.dart';
import 'package:clari/core/security/security_preferences_service.dart';
import 'package:clari/core/session/app_session_controller.dart';
import 'package:clari/core/storage/database_path_service.dart';
import 'package:clari/core/storage/library_backup_preferences_service.dart';
import 'package:clari/core/storage/library_backup_service.dart';
import 'package:clari/shared/router/app_router.dart';

void main() {
  test('router provider stays stable across session notifications', () {
    final session = _TestAppSessionController();
    final container = ProviderContainer(
      overrides: [appSessionProvider.overrideWith((ref) => session)],
    );
    addTearDown(container.dispose);

    final firstRouter = container.read(routerProvider);
    session.emitChange();
    final secondRouter = container.read(routerProvider);

    expect(firstRouter, same(secondRouter));
  });
}

class _TestAppSessionController extends AppSessionController {
  _TestAppSessionController()
    : super(
        keyService: KeyService(),
        databasePathService: DatabasePathService(),
        securityPreferencesService: SecurityPreferencesService(),
        libraryBackupPreferencesService: LibraryBackupPreferencesService(),
        libraryBackupService: LibraryBackupService(),
      );

  @override
  AppSessionStatus get status => AppSessionStatus.ready;

  @override
  bool get hasPendingRecoveryKey => false;

  void emitChange() => notifyListeners();
}
