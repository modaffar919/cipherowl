import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cipherowl/core/platform/platform_info.dart';

void main() {
  group('PlatformInfo', () {
    test('isWeb returns false in test environment', () {
      // Flutter tests always run as native (not browser)
      expect(PlatformInfo.isWeb, false);
    });

    test('isMobile returns combined Android/iOS', () {
      expect(PlatformInfo.isMobile, PlatformInfo.isAndroid || PlatformInfo.isIOS);
    });

    test('isDesktop returns combined Win/Mac/Linux', () {
      expect(PlatformInfo.isDesktop,
          PlatformInfo.isWindows || PlatformInfo.isMacOS || PlatformInfo.isLinux);
    });

    test('exactly one platform family is true', () {
      // In tests, one of isMobile or isDesktop should be true
      final families = [
        PlatformInfo.isMobile,
        PlatformInfo.isDesktop,
        PlatformInfo.isWeb,
      ];
      expect(families.where((f) => f).length, 1);
    });

    test('hasCamera only on mobile', () {
      expect(PlatformInfo.hasCamera, PlatformInfo.isMobile);
    });

    test('hasFileSystem not on web', () {
      expect(PlatformInfo.hasFileSystem, !PlatformInfo.isWeb);
    });

    test('hasSqlCipher not on web', () {
      expect(PlatformInfo.hasSqlCipher, !PlatformInfo.isWeb);
    });

    test('hasSecureStorage not on web', () {
      expect(PlatformInfo.hasSecureStorage, !PlatformInfo.isWeb);
    });

    test('defaultTargetPlatform matches expected', () {
      // The test runner's platform should be consistent
      expect(defaultTargetPlatform, isA<TargetPlatform>());
    });
  });
}
