// ignore_for_file: type=lint
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/vault_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/security_log_dao.dart';

export 'daos/vault_dao.dart';
export 'daos/settings_dao.dart';
export 'daos/security_log_dao.dart';

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

/// Vault item version history — stores encrypted snapshots before updates.
///
/// Each row is an immutable snapshot of a VaultItem row taken *before*
/// a mutation.  The [encryptedSnapshot] is a JSON blob encrypted with
/// AES-256-GCM (same key as the vault item itself).
class VaultItemVersions extends Table {
  /// Auto-incrementing version row ID.
  IntColumn get id => integer().named('id').autoIncrement()();

  /// The vault item this version belongs to.
  TextColumn get itemId => text().named('item_id')();

  /// Monotonically increasing version number per item.
  IntColumn get version => integer().named('version')();

  /// AES-256-GCM encrypted JSON snapshot of the full item state.
  BlobColumn get encryptedSnapshot =>
      blob().named('encrypted_snapshot')();

  /// What kind of change triggered the snapshot.
  TextColumn get changeType =>
      text().named('change_type').withDefault(const Constant('update'))();

  DateTimeColumn get changedAt =>
      dateTime().named('changed_at').withDefault(currentDateAndTime)();
}

/// Encrypted file attachments linked to vault items.
///
/// The actual file blob is stored on disk at [localPath] (encrypted).
/// Metadata is kept here for indexing and sync.
class VaultAttachments extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text().named('id')();

  /// The vault item this attachment belongs to.
  TextColumn get itemId => text().named('item_id')();

  /// Original filename (e.g. 'invoice.pdf').
  TextColumn get fileName => text().named('file_name')();

  /// MIME type (e.g. 'application/pdf', 'image/png').
  TextColumn get mimeType => text().named('mime_type')();

  /// Original file size in bytes (before encryption).
  IntColumn get fileSize => integer().named('file_size')();

  /// Relative path to the encrypted file on local storage.
  TextColumn get localPath => text().named('local_path')();

  /// Supabase Storage object path (null if not yet synced).
  TextColumn get remotePath => text().named('remote_path').nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
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

/// Queued offline operations — persisted until connectivity returns.
///
/// Each row represents a single mutation that needs to be pushed to
/// Supabase when the device goes back online.
class PendingOperations extends Table {
  /// Auto-incrementing ID (execution order).
  IntColumn get id => integer().named('id').autoIncrement()();

  /// Operation type: 'upsert', 'delete', 'attachment_upload', etc.
  TextColumn get operationType => text().named('operation_type')();

  /// JSON-encoded payload for the operation.
  TextColumn get payload => text().named('payload')();

  /// Related vault item ID (nullable for non-item operations).
  TextColumn get itemId => text().named('item_id').nullable()();

  /// Number of failed retry attempts.
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  /// Status: 'pending', 'processing', 'failed'.
  TextColumn get status =>
      text().named('status').withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

// ─── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [VaultItems, VaultItemVersions, VaultAttachments, SecurityLogs, UserSettings, PendingOperations],
  daos: [VaultDao, SettingsDao, SecurityLogDao],
)
class SmartVaultDatabase extends _$SmartVaultDatabase {
  SmartVaultDatabase({required String encryptionKey})
      : super(_openConnection(encryptionKey));

  /// For injecting a custom executor in tests (unencrypted / in-memory).
  SmartVaultDatabase.forTesting(super.e);

  /// Current schema version.
  ///
  /// History:
  ///   v1 — Initial schema: VaultItems, SecurityLogs, UserSettings
  ///   v2 — VaultItems: added [strengthScore], [syncedAt], [lastAccessedAt]
  ///          and [encryptedTotpSecret] columns (back-filled with NULL).
  ///   v3 — Added VaultItemVersions table for edit history / rollback.
  ///   v4 — Added VaultAttachments table for encrypted file attachments.
  ///   v5 — Added PendingOperations table for offline queue.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultSettings();
        },
        onUpgrade: (m, from, to) async {
          await customStatement('PRAGMA foreign_keys = OFF');
          await transaction(() async {
            // v1 → v2: add columns that were missing in the original schema
            if (from < 2) {
              // These columns were introduced in v2; add them if absent.
              // addColumn is a no-op-safe migration helper in Drift.
              await m.addColumn(vaultItems, vaultItems.strengthScore);
              await m.addColumn(vaultItems, vaultItems.syncedAt);
              await m.addColumn(vaultItems, vaultItems.lastAccessedAt);
              await m.addColumn(vaultItems, vaultItems.encryptedTotpSecret);
            }
            if (from < 3) {
              await m.createTable(vaultItemVersions);
            }
            if (from < 4) {
              await m.createTable(vaultAttachments);
            }
            if (from < 5) {
              await m.createTable(pendingOperations);
            }
          });
          await customStatement('PRAGMA foreign_keys = ON');
        },
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
      await settingsDao.setSetting(entry.key, entry.value);
    }
  }
}

// ─── Connection factory ──────────────────────────────────────────────────────

/// Opens an encrypted SQLCipher database using drift + sqlcipher_flutter_libs.
///
/// The [encryptionKey] is a 64-char hex string (32 bytes) derived from the
/// master password via Argon2id (EPIC-2) or randomly generated on first launch.
QueryExecutor _openConnection(String encryptionKey) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smartvault.db'));

    return NativeDatabase.createBackgroundConnection(
      file,
      setup: (db) {
        // SQLCipher PRAGMA — must be the very first operation on the database.
        db.execute("PRAGMA key = \"x'$encryptionKey'\";");
        // Recommended SQLCipher settings for security/performance balance.
        db.execute('PRAGMA cipher_page_size = 4096;');
        db.execute('PRAGMA kdf_iter = 64000;');
        db.execute('PRAGMA cipher_hmac_algorithm = HMAC_SHA512;');
        db.execute('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;');
      },
    );
  });
}
