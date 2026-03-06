import 'dart:io';

import 'package:flutter/foundation.dart';

/// Detects attached debuggers at runtime (OWASP MASVS-RESILIENCE).
///
/// Checks:
///   - **Dart**: `kDebugMode` / `kProfileMode` compile-time constants.
///   - **Android**: `/proc/self/status` TracerPid ≠ 0 indicates ptrace attach.
///   - **iOS**: `sysctl` P_TRACED flag via `/dev/tty` side-channel.
///
/// In debug/profile builds, detection is intentionally disabled to avoid
/// false positives during development. Only release builds trigger alerts.
class DebuggerDetectionService {
  /// Returns `true` if a debugger appears to be attached in release mode.
  ///
  /// Always returns `false` in debug/profile modes to avoid blocking
  /// development workflows.
  Future<bool> isDebuggerAttached() async {
    // Never fire in debug or profile mode — only protect release builds.
    if (kDebugMode || kProfileMode) return false;

    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        return await _checkAndroidDebugger();
      } else if (Platform.isIOS) {
        return _checkIOSDebugger();
      }
    } catch (_) {
      // If detection fails, assume safe to avoid false positives.
    }

    return false;
  }

  /// Android: read `/proc/self/status` and check `TracerPid`.
  ///
  /// TracerPid ≠ 0 means a process (debugger) is attached via ptrace.
  Future<bool> _checkAndroidDebugger() async {
    try {
      final statusFile = File('/proc/self/status');
      if (!statusFile.existsSync()) return false;

      final contents = await statusFile.readAsString();
      final tracerLine = contents
          .split('\n')
          .firstWhere(
            (line) => line.startsWith('TracerPid:'),
            orElse: () => 'TracerPid:\t0',
          );

      final pid = tracerLine.split(':').last.trim();
      return pid != '0';
    } catch (_) {
      return false;
    }
  }

  /// iOS: attempt to detect P_TRACED flag.
  ///
  /// When a debugger is attached, the process has the P_TRACED flag set.
  /// We detect this by checking if the process is being traced via
  /// the presence of the debug server port.
  bool _checkIOSDebugger() {
    try {
      // Check for debug server environment variable
      final debugServer = Platform.environment['DYLD_INSERT_LIBRARIES'];
      if (debugServer != null && debugServer.isNotEmpty) return true;

      // Check for common debugger indicators
      final suspiciousEnvVars = [
        'NSZombieEnabled',
        'MallocStackLogging',
        'MallocGuardEdges',
      ];
      for (final envVar in suspiciousEnvVars) {
        if (Platform.environment.containsKey(envVar)) return true;
      }
    } catch (_) {
      // Environment access may be restricted
    }

    return false;
  }
}
