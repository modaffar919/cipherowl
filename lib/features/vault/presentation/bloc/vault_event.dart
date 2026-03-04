part of 'vault_bloc.dart';

// ─── Events ────────────────────────────────────────────────────────────────

abstract class VaultEvent {
  const VaultEvent();
}

/// Initial load — subscribe to the DB stream for [userId].
class VaultStarted extends VaultEvent {
  final String userId;
  const VaultStarted(this.userId);
}

/// Internal: emitted when the DB stream fires a new list.
class _VaultItemsReceived extends VaultEvent {
  final List<VaultEntry> items;
  const _VaultItemsReceived(this.items);
}

/// User changed the search box text.
class VaultSearchChanged extends VaultEvent {
  final String query;
  const VaultSearchChanged(this.query);
}

/// User selected / deselected a category chip.
class VaultCategoryChanged extends VaultEvent {
  /// null = "All"
  final String? category;
  const VaultCategoryChanged(this.category);
}

/// User added a new vault entry.
class VaultItemAdded extends VaultEvent {
  final VaultEntry entry;
  const VaultItemAdded(this.entry);
}

/// User saved edits to an existing entry.
class VaultItemUpdated extends VaultEvent {
  final VaultEntry entry;
  const VaultItemUpdated(this.entry);
}

/// User confirmed deletion.
class VaultItemDeleted extends VaultEvent {
  final String itemId;
  const VaultItemDeleted(this.itemId);
}

/// User toggled the favourite star.
class VaultFavoriteToggled extends VaultEvent {
  final String itemId;
  final bool isFavorite;
  const VaultFavoriteToggled(this.itemId, {required this.isFavorite});
}

/// Pull-to-refresh — forces a fresh DB read.
class VaultRefreshRequested extends VaultEvent {
  const VaultRefreshRequested();
}

/// Dismiss the transient success/error toast.
class VaultMessageDismissed extends VaultEvent {
  const VaultMessageDismissed();
}

/// Bulk import — add many items at once (from CSV import).
class VaultItemsImported extends VaultEvent {
  final List<VaultEntry> entries;
  const VaultItemsImported(this.entries);
}
