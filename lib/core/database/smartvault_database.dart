// ignore_for_file: type=lint
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'smartvault_database.g.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

/// Category of a vault entry.
enum VaultItemCategory {
  login,
  card,
  secureNote,
  identity,
  totp,
}

/// Severity level of a security event.
enum SecurityEventSeverity {
  info,
  warning,
  critical,
}

// ─── Tables ──────────────────────────────────────────────────────────────────

/// Main vault table — stores credential/note entries.
///
/// Sensitive fields (encryptedPassword, encryptedNotes) are stored as raw
/// AES-256-GCM blobs encrypted by the Rust core before insertion.
class VaultItems extends Table {
  /// UUID v4 primary key — generated client-side.
  TextColumn get id => text().named('id')();

  /// Supabase user ID that owns this entry.
  TextColumn get userId => text().named('user_id')();

  /// Human-readable title (e.g. "Gmail", "Bank of America").
  TextColumn get title => text().named('title')();

  /// Username / email / login identifier.
  TextColumn get username => text().named('username').nullable()();

  /// AES-256-GCM encrypted password blob (nonce prepended).
  BlobColumn get encryptedPassword =>
      blob().named('encrypted_password').nullable()();

  /// Website or app URL.
  TextColumn get url => text().named('url').nullable()();

  /// AES-256-GCM encrypted notes blob.
  BlobColumn get encryptedNotes =>
      blob().named('encrypted_notes').nullable()();

  /// TOTP secret (encrypted) — used when category == totp.
  BlobColumn get encryptedTotpSecret =>
      blob().named('encrypted_totp_secret').nullable()();

  /// Category tag for filtering / icons.
  TextColumn get category =>
      text().named('category').withDefault(const Constant('login'))();

  /// User-pinned / favourited entry.
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();

  /// Soft-delete flag for zero-knowledge sync (deleted entries kept until sync).
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  /// Strength score 0–4 from zxcvbn (cached after generation).
  IntColumn get strengthScore =>
      integer().named('strength_score').nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  DateTimeColumn get lastAccessedAt =>
      dateTime().named('last_accessed_at').nullable()();

  /// Timestamp when the row was last successfully synced to Supabase.
  DateTimeColumn get syncedAt =>
      dateTime().named('synced_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Security audit log — immutable append-only event log.
class SecurityLogs extends Table {
  IntColumn get id => integer().named('id').autoIncrement()();

  /// Event code, e.g. "login_success", "failed_unlock", "breach_detected".
  TextColumn get eventType => text().named('event_type')();

  /// Human-readable description of what happened.
  TextColumn get description => text().named('description')();

  /// Severity level: info | warning | critical.
  TextColumn get severity =>
      text().named('severity').withDefault(const Constant('info'))();

  /// Device or IP info captured at event time (may be null for offline events).
  TextColumn get deviceInfo =>
      text().named('device_info').nullable()();

  /// Optional reference to the vault item this event relates to.
  TextColumn get relatedItemId =>
      text().named('related_item_id').nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

/// Key-value store for user preferences and app state.
///
/// Values are stored as JSON strings.  Sensitive values (e.g. Argon2 salt)
/// are encrypted before storage.
class UserSettings extends Table {
  /// Setting key — e.g. "locale", "theme", "argon2_salt", "biometric_enabled".
  TextColumn get key => text().named('key')();

  /// JSON-encoded value string.
  TextColumn get value => text().named('value')();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

// ─── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [VaultItems, SecurityLogs, UserSettings])
class SmartVaultDatabase extends _$SmartVaultDatabase {
  SmartVaultDatabase() : super(_openConnection());

  /// For injecting a custom executor in tests.
  SmartVaultDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed default settings
          await _seedDefaultSettings();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );

  // ─── Vault Item DAOs ─────────────────────────────────────────────────────

  /// All non-deleted vault items for a user, sorted by title.
  Future<List<VaultItem>> watchAllItems(String userId) =>
      (select(vaultItems)
            ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  /// Find a single vault item by id.
  Future<VaultItem?> findItemById(String id) =>
      (select(vaultItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Insert or replace a vault item (upsert semantics for sync).
  Future<void> upsertItem(VaultItemsCompanion item) =>
      into(vaultItems).insertOnConflictUpdate(item);

  /// Soft-delete an item (keeps row for sync/undo).
  Future<void> softDeleteItem(String id) =>
      (update(vaultItems)..where((t) => t.id.equals(id))).write(
        VaultItemsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Items modified after [since] — used for incremental sync.
  Future<List<VaultItem>> itemsModifiedAfter(String userId, DateTime since) =>
      (select(vaultItems)
            ..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.updatedAt.isBiggerThanValue(since),
            ))
          .get();

  // ─── Security Log DAOs ───────────────────────────────────────────────────

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

  /// Recent security events.
  Future<List<SecurityLog>> recentEvents({int limit = 50}) =>
      (select(securityLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  // ─── Settings DAOs ───────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(userSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(userSettings).insertOnConflictUpdate(
        UserSettingsCompanion.insert(
          key: key,
          value: value,
        ),
      );

  // ─── Private helpers ─────────────────────────────────────────────────────

  Future<void> _seedDefaultSettings() async {
    const defaults = {
      'locale': '"ar"',
      'theme': '"system"',
      'biometric_enabled': 'false',
      'auto_lock_minutes': '5',
      'clipboard_clear_seconds': '30',
      'show_password_strength': 'true',
    };
    for (final entry in defaults.entries) {
      await setSetting(entry.key, entry.value);
    }
  }
}

// ─── Connection factory ──────────────────────────────────────────────────────

/// Opens the SQLite/SQLCipher database using drift_flutter.
/// SQLCipher encryption key is managed by the Rust core (cipherowl-5d9).
QueryExecutor _openConnection() {
  return driftDatabase(name: 'smartvault');
}
