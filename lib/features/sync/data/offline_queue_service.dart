import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import 'package:cipherowl/core/database/smartvault_database.dart';

/// Manages offline operation queuing and automatic retry.
///
/// When the device is offline, mutations are serialised as JSON and
/// stored in the [PendingOperations] Drift table. When connectivity
/// returns, the queue is drained in FIFO order.
class OfflineQueueService {
  final SmartVaultDatabase _db;
  final Connectivity _connectivity;
  final Future<void> Function(String type, Map<String, dynamic> payload)
      _executor;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _draining = false;

  /// Maximum retry attempts before marking an operation as 'failed'.
  static const int maxRetries = 5;

  /// Creates the offline queue service.
  ///
  /// [executor] — callback that performs the actual cloud operation.
  /// It receives the operation type and decoded payload.
  OfflineQueueService({
    required SmartVaultDatabase db,
    required Future<void> Function(String type, Map<String, dynamic> payload)
        executor,
    Connectivity? connectivity,
  })  : _db = db,
        _executor = executor,
        _connectivity = connectivity ?? Connectivity();

  /// Start listening for connectivity changes.
  void start() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) drainQueue();
    });
  }

  /// Stop listening.
  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Enqueue an operation for later execution.
  Future<void> enqueue({
    required String operationType,
    required Map<String, dynamic> payload,
    String? itemId,
  }) async {
    await _db.into(_db.pendingOperations).insert(
          PendingOperationsCompanion(
            operationType: Value(operationType),
            payload: Value(jsonEncode(payload)),
            itemId: Value(itemId),
            status: const Value('pending'),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  /// Count of pending operations.
  Future<int> pendingCount() async {
    final q = _db.select(_db.pendingOperations)
      ..where((t) => t.status.isIn(['pending', 'failed']));
    final rows = await q.get();
    return rows.length;
  }

  /// Watch the count of pending operations (for UI badges).
  Stream<int> watchPendingCount() {
    final q = _db.select(_db.pendingOperations)
      ..where((t) => t.status.isIn(['pending', 'failed']));
    return q.watch().map((rows) => rows.length);
  }

  /// Process all pending operations in FIFO order.
  Future<void> drainQueue() async {
    if (_draining) return;
    _draining = true;

    try {
      while (true) {
        final ops = await (_db.select(_db.pendingOperations)
              ..where((t) => t.status.isIn(['pending', 'failed']))
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(1))
            .get();

        if (ops.isEmpty) break;
        final op = ops.first;

        // Mark processing
        await (_db.update(_db.pendingOperations)
              ..where((t) => t.id.equals(op.id)))
            .write(const PendingOperationsCompanion(
                status: Value('processing')));

        try {
          final payload =
              jsonDecode(op.payload) as Map<String, dynamic>;
          await _executor(op.operationType, payload);

          // Success — remove from queue
          await (_db.delete(_db.pendingOperations)
                ..where((t) => t.id.equals(op.id)))
              .go();
        } catch (_) {
          final newRetries = op.retryCount + 1;
          if (newRetries >= maxRetries) {
            // Permanently failed
            await (_db.update(_db.pendingOperations)
                  ..where((t) => t.id.equals(op.id)))
                .write(PendingOperationsCompanion(
              status: const Value('failed'),
              retryCount: Value(newRetries),
            ));
          } else {
            // Back to pending for retry
            await (_db.update(_db.pendingOperations)
                  ..where((t) => t.id.equals(op.id)))
                .write(PendingOperationsCompanion(
              status: const Value('pending'),
              retryCount: Value(newRetries),
            ));
          }
          break; // Stop draining on failure — retry later
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Clear all pending operations (used during logout / reset).
  Future<void> clearAll() async {
    await _db.delete(_db.pendingOperations).go();
  }
}
