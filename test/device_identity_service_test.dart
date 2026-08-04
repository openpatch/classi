import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classi/core/sync/device_identity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getOrCreateDeviceId persists the same id across calls', () async {
    final service = DeviceIdentityService();

    final first = await service.getOrCreateDeviceId();
    final second = await service.getOrCreateDeviceId();

    expect(first, second);
    expect(first, isNotEmpty);
  });

  test('a fresh service instance reads back the persisted device id', () async {
    final id = await DeviceIdentityService().getOrCreateDeviceId();
    final reloaded = await DeviceIdentityService().getOrCreateDeviceId();

    expect(reloaded, id);
  });

  test(
    'deviceName falls back to a generic platform label until set',
    () async {
      final service = DeviceIdentityService();

      expect(await service.storedDeviceName(), isNull);
      expect(
        await service.deviceName(),
        DeviceIdentityService.defaultDeviceName(),
      );

      await service.setDeviceName('Kitchen iPad');
      expect(await service.storedDeviceName(), 'Kitchen iPad');
      expect(await service.deviceName(), 'Kitchen iPad');

      await service.setDeviceName('   ');
      expect(
        await service.storedDeviceName(),
        isNull,
        reason: 'a blank name clears the stored label',
      );
    },
  );
}
