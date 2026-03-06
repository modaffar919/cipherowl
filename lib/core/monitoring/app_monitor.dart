import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lightweight app health monitoring service.
///
/// Captures unhandled errors, records security events, and tracks performance
/// metrics. In production, this can be extended to forward to Firebase
/// Crashlytics, Sentry, or any remote logging backend.
class AppMonitor {
  static final AppMonitor _instance = AppMonitor._();
  static AppMonitor get instance => _instance;

  AppMonitor._();

  final List<_ErrorRecord> _recentErrors = [];
  final List<_PerfRecord> _recentPerf = [];

  /// Maximum number of error records kept in memory.
  static const int _maxRecords = 50;

  // ── Error Tracking ──────────────────────────────────────────────────────

  /// Initialize global error handlers. Call once from main().
  void init() {
    FlutterError.onError = (details) {
      _recordFlutterError(details);
      // Default handler prints to console in debug
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _recordError('platform', error, stack);
      return true; // Prevent crash
    };
  }

  /// Wrap the app's runApp call to catch async errors in the root zone.
  static Future<void> runGuarded(Future<void> Function() appMain) async {
    await runZonedGuarded(
      appMain,
      (error, stackTrace) {
        instance._recordError('zone', error, stackTrace);
      },
    );
  }

  void _recordFlutterError(FlutterErrorDetails details) {
    _addError(_ErrorRecord(
      source: 'flutter',
      error: details.exceptionAsString(),
      stack: details.stack?.toString() ?? '',
      timestamp: DateTime.now(),
    ));
  }

  void _recordError(String source, Object error, StackTrace? stack) {
    _addError(_ErrorRecord(
      source: source,
      error: error.toString(),
      stack: stack?.toString() ?? '',
      timestamp: DateTime.now(),
    ));
  }

  void _addError(_ErrorRecord record) {
    _recentErrors.add(record);
    if (_recentErrors.length > _maxRecords) {
      _recentErrors.removeAt(0);
    }
    if (kDebugMode) {
      debugPrint('[AppMonitor] ${record.source}: ${record.error}');
    }
  }

  /// Log a security-related event (login failures, breach detections, etc.).
  void logSecurityEvent(String event, {Map<String, dynamic>? metadata}) {
    if (kDebugMode) {
      debugPrint('[Security] $event ${metadata ?? ''}');
    }
  }

  // ── Performance Tracking ────────────────────────────────────────────────

  /// Start a performance trace. Returns a [Stopwatch] that should be stopped
  /// and passed to [endTrace].
  Stopwatch startTrace(String name) {
    return Stopwatch()..start();
  }

  /// End a performance trace and record the duration.
  void endTrace(String name, Stopwatch watch) {
    watch.stop();
    _recentPerf.add(_PerfRecord(
      name: name,
      durationMs: watch.elapsedMilliseconds,
      timestamp: DateTime.now(),
    ));
    if (_recentPerf.length > _maxRecords) {
      _recentPerf.removeAt(0);
    }
    if (kDebugMode) {
      debugPrint('[Perf] $name: ${watch.elapsedMilliseconds}ms');
    }
  }

  // ── Diagnostics (for debug/support screens) ─────────────────────────────

  /// Recent error count.
  int get errorCount => _recentErrors.length;

  /// Recent errors for diagnostics.
  List<Map<String, dynamic>> get recentErrors => _recentErrors
      .map((e) => {
            'source': e.source,
            'error': e.error,
            'timestamp': e.timestamp.toIso8601String(),
          })
      .toList();

  /// Recent performance metrics.
  List<Map<String, dynamic>> get recentPerf => _recentPerf
      .map((p) => {
            'name': p.name,
            'durationMs': p.durationMs,
            'timestamp': p.timestamp.toIso8601String(),
          })
      .toList();
}

class _ErrorRecord {
  final String source;
  final String error;
  final String stack;
  final DateTime timestamp;
  const _ErrorRecord({
    required this.source,
    required this.error,
    required this.stack,
    required this.timestamp,
  });
}

class _PerfRecord {
  final String name;
  final int durationMs;
  final DateTime timestamp;
  const _PerfRecord({
    required this.name,
    required this.durationMs,
    required this.timestamp,
  });
}
