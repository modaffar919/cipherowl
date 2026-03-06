import 'package:flutter_test/flutter_test.dart';

import 'package:cipherowl/core/security/device_integrity_service.dart';

void main() {
  group('DeviceIntegrityService', () {
    late DeviceIntegrityService service;

    setUp(() {
      service = DeviceIntegrityService();
    });

    test('isDeviceCompromised returns a boolean', () async {
      final result = await service.isDeviceCompromised();
      expect(result, isA<bool>());
    });

    test('result is cached after first call', () async {
      final first = await service.isDeviceCompromised();
      final second = await service.isDeviceCompromised();
      expect(first, equals(second));
    });

    test('reset clears cached state', () async {
      await service.isDeviceCompromised();
      service.reset();
      // After reset, the next call should re-evaluate.
      final result = await service.isDeviceCompromised();
      expect(result, isA<bool>());
    });
  });
}
