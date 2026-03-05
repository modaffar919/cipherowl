/// Result returned by every sync operation.
sealed class SyncResult {
  const SyncResult();
}

/// Sync completed successfully.
class SyncSuccess extends SyncResult {
  /// Number of items pushed to the server.
  final int pushed;

  /// Number of items pulled (newer on server) and applied locally.
  final int pulled;

  const SyncSuccess({required this.pushed, required this.pulled});

  @override
  String toString() => 'SyncSuccess(pushed: $pushed, pulled: $pulled)';
}

/// Sync skipped because the user is not signed in to cloud.
class SyncSkipped extends SyncResult {
  const SyncSkipped();
}

/// Sync failed.
class SyncFailure extends SyncResult {
  final String message;
  final Object? error;

  const SyncFailure(this.message, [this.error]);

  @override
  String toString() => 'SyncFailure($message)';
}