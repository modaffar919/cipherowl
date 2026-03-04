import 'package:drift/drift.dart';

import '../smartvault_database.dart';

part 'security_log_dao.g.dart';

/// Data Access Object for the append-only [SecurityLogs] audit table.
@DriftAccessor(tables: [SecurityLogs])
class SecurityLogDao extends DatabaseAccessor<SmartVaultDatabase>
    with _$SecurityLogDaoMixin {
  SecurityLogDao(super.db);

  // ── Write ────────────────────────────────────────────────────────────────

  /// Append a security event to the audit log.
  Future<void> logEvent({
    required String eventType,
    required String description,
    String severity = 'info',
    String? deviceInfo,
    String? relatedItemId,
  }) =>
      into(securityLogs).insert(
        SecurityLogsCompanion.insert(
          eventType: eventType,
          description: description,
          severity: Value(severity),
          deviceInfo: Value(deviceInfo),
          relatedItemId: Value(relatedItemId),
        ),
      );

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Most recent [limit] events, newest first.
  Future<List<SecurityLog>> recentEvents({int limit = 50}) =>
      (select(securityLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Live stream of recent events — drives the Security Center feed.
  Stream<List<SecurityLog>> watchRecentEvents({int limit = 20}) =>
      (select(securityLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Events of a specific type (e.g. 'failed_unlock').
  Future<List<SecurityLog>> eventsByType(String eventType) =>
      (select(securityLogs)
            ..where((t) => t.eventType.equals(eventType))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Only warning / critical events.
  Future<List<SecurityLog>> criticalEvents() =>
      (select(securityLogs)
            ..where((t) =>
                t.severity.equals('warning') |
                t.severity.equals('critical'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Count failed unlock attempts logged in the last [minutes] minutes.
  Future<int> failedAttemptsIn({int minutes = 60}) async {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    final count = countAll(
      filter: securityLogs.eventType.equals('failed_unlock') &
          securityLogs.createdAt.isBiggerThanValue(cutoff),
    );
    final query = selectOnly(securityLogs)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count)!;
  }

  /// Delete log entries older than [days] days, to cap storage growth.
  Future<int> pruneOlderThan({int days = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (delete(securityLogs)
          ..where((t) => t.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Wipe the entire audit log (used on vault reset / logout).
  Future<int> clearAll() => delete(securityLogs).go();
}
