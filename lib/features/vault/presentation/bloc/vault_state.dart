part of 'vault_bloc.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class VaultState {
  const VaultState();
}

/// Before the DB stream is attached.
class VaultInitial extends VaultState {
  const VaultInitial();
}

/// Fetching the first page of items.
class VaultLoading extends VaultState {
  const VaultLoading();
}

/// Items are loaded and the list is visible.
class VaultLoaded extends VaultState {
  /// Full unfiltered list from the DB stream.
  final List<VaultEntry> allItems;

  /// Current search query (empty = no filter).
  final String searchQuery;

  /// Selected category filter (null = "All").
  final String? categoryFilter;

  /// True while an add / update / delete is in flight.
  final bool isOperating;

  /// Optional transient message (success or error) to show as a snack bar.
  final String? message;

  /// Whether [message] represents an error.
  final bool isError;

  /// True while a cloud sync is in progress.
  final bool isSyncing;

  /// Timestamp of the last successful cloud sync, or null if never synced.
  final DateTime? lastSyncAt;

  /// True when the vault is showing decoy items (duress mode).
  /// All CRUD operations are silently accepted but never persisted.
  final bool isDuress;

  const VaultLoaded({
    required this.allItems,
    this.searchQuery = '',
    this.categoryFilter,
    this.isOperating = false,
    this.message,
    this.isError = false,
    this.isSyncing = false,
    this.lastSyncAt,
    this.isDuress = false,
  });

  // ── Derived ──────────────────────────────────────────────────────────────

  /// Filtered list based on current search + category filter.
  List<VaultEntry> get filteredItems {
    return allItems.where((item) {
      final matchesCategory = categoryFilter == null ||
          item.category.name == categoryFilter;
      final q = searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          (item.username ?? '').toLowerCase().contains(q) ||
          (item.url ?? '').toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Count of weak items (strength score < 2).
  int get weakItemCount =>
      allItems.where((i) => i.strengthScore >= 0 && i.strengthScore < 2).length;

  /// Overall security score 0–100 based on strength distribution.
  int get securityScore {
    if (allItems.isEmpty) return 100;
    final scored =
        allItems.where((i) => i.strengthScore >= 0).toList();
    if (scored.isEmpty) return 50;
    final total = scored.fold(0, (sum, i) => sum + i.strengthScore);
    return ((total / (scored.length * 4)) * 100).round().clamp(0, 100);
  }

  VaultLoaded copyWith({
    List<VaultEntry>? allItems,
    String? searchQuery,
    String? categoryFilter,
    bool? isOperating,
    String? message,
    bool? isError,
    bool? isSyncing,
    DateTime? lastSyncAt,
    bool? isDuress,
    bool clearMessage = false,
    bool clearCategory = false,
  }) =>
      VaultLoaded(
        allItems: allItems ?? this.allItems,
        searchQuery: searchQuery ?? this.searchQuery,
        categoryFilter:
            clearCategory ? null : (categoryFilter ?? this.categoryFilter),
        isOperating: isOperating ?? this.isOperating,
        message: clearMessage ? null : (message ?? this.message),
        isError: isError ?? this.isError,
        isSyncing: isSyncing ?? this.isSyncing,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        isDuress: isDuress ?? this.isDuress,
      );
}

/// Something went wrong (DB / repo error).
class VaultError extends VaultState {
  final String message;
  const VaultError(this.message);
}
