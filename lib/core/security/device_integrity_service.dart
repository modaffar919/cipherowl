import 'dart:io';

import 'package:flutter/foundation.dart';

/// Detects rooted/jailbroken devices and emulator environments.
///
/// OWASP MASVS-RESILIENCE-1: The app detects and responds to the presence
/// of a rooted or jailbroken device.
class DeviceIntegrityService {
  /// Cached result after first check.
  bool? _isCompromised;

  /// Returns `true` if the device appears to be rooted, jailbroken, or an
  /// emulator. Result is cached after the first call.
  Future<bool> isDeviceCompromised() async {
    if (_isCompromised != null) return _isCompromised!;

    if (kIsWeb) {
      _isCompromised = false;
      return false;
    }

    try {
      if (Platform.isAndroid) {
        _isCompromised = await _checkAndroid();
      } else if (Platform.isIOS) {
        _isCompromised = await _checkIOS();
      } else {
        // Desktop platforms — no root check needed.
        _isCompromised = false;
      }
    } catch (_) {
      // If detection fails, assume safe to avoid false positives.
      _isCompromised = false;
    }

    return _isCompromised!;
  }

  /// Android root detection heuristics.
  Future<bool> _checkAndroid() async {
    // 1. Check for common su binaries.
    final suPaths = [
      '/system/app/Superuser.apk',
      '/system/xbin/su',
      '/system/bin/su',
      '/sbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/data/local/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/su/bin/su',
      '/data/adb/su',
    ];
    for (final path in suPaths) {
      if (await _fileExists(path)) return true;
    }

    // 2. Check for Magisk or other root managers.
    final rootIndicators = [
      '/sbin/.magisk',
      '/data/adb/magisk',
      '/cache/.disable_magisk',
      '/system/app/KingRoot.apk',
      '/system/app/Kinguser.apk',
    ];
    for (final path in rootIndicators) {
      if (await _fileExists(path)) return true;
    }

    // 3. Check build tags for test-keys (custom ROM).
    try {
      final result = await Process.run('getprop', ['ro.build.tags']);
      if (result.stdout.toString().contains('test-keys')) return true;
    } catch (_) {
      // getprop unavailable is normal on some devices.
    }

    // 4. Check if /system is writable (should be read-only).
    try {
      final result = await Process.run('mount', []);
      final output = result.stdout.toString();
      if (output.contains('/system') && output.contains('rw,')) return true;
    } catch (_) {
      // mount command may not be accessible.
    }

    return false;
  }

  /// iOS jailbreak detection heuristics.
  Future<bool> _checkIOS() async {
    // 1. Check for Cydia and other jailbreak apps.
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Applications/Sileo.app',
      '/Applications/Zebra.app',
      '/Applications/Filza.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/usr/sbin/sshd',
      '/usr/bin/sshd',
      '/etc/apt',
      '/bin/bash',
      '/usr/libexec/sftp-server',
      '/private/var/lib/apt/',
      '/private/var/stash',
      '/var/lib/cydia',
    ];
    for (final path in jailbreakPaths) {
      if (await _fileExists(path)) return true;
    }

    // 2. Check if app can write outside sandbox (jailbreak indicator).
    try {
      final testFile = File('/private/cipherowl_jb_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true; // Should NOT be writable on non-jailbroken device.
    } catch (_) {
      // Expected: permission denied on clean device.
    }

    return false;
  }

  /// Safe file existence check.
  Future<bool> _fileExists(String path) async {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Resets cached state (useful for testing).
  void reset() {
    _isCompromised = null;
  }
}
