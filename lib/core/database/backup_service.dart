import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cipherowl/src/rust/frb_generated.dart/api.dart';
import 'smartvault_database.dart';

/// Backup file magic header (4 bytes) + schema version (1 byte).
///
/// Wire format:
///   [4]  magic = 0x43 0x4F 0x42 0x4B  ("COBK")
///   [1]  format version = 0x01
///   [32] AES-256-GCM nonce (12 bytes) + reserved (20 bytes)  â†گ actually [12] nonce
///   ...  see [_BackupEnvelope]
///
/// Simplified wire format used here:
///   magic(4) | version(1) | nonce(12) | ciphertext_with_tag(N)
const _kMagic = [0x43, 0x4F, 0x42, 0x4B]; // "COBK"
const _kFormatVersion = 0x01;

/// Manages encrypted export/import of all vault data.
///
/// The backup file is a binary envelope:
///   - 4-byte magic "COBK"
///   - 1-byte format version
///   - 12-byte AES-256-GCM nonce
///   - N-byte AES-256-GCM ciphertext + 16-byte tag
///
/// The plaintext is a UTF-8 JSON document containing all VaultItems
/// and UserSettings.  SecurityLogs are excluded (audit-only data).
///
/// The AES key is the same SQLCipher database key stored in secure storage,
/// so only the same device (or same key) can decrypt the backup.
class BackupService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  static const _dbKeyStorageKey = 'cipherowl_db_key_v1';
  static const _backupFileName = 'cipherowl_backup.cobk';

  // â”€â”€â”€ Export â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Exports all vault data as an encrypted `.cobk` file and triggers the
  /// system share sheet so the user can save it to cloud storage, email, etc.
  ///
  /// Throws [BackupException] on failure.
  static Future<void> exportAndShare(SmartVaultDatabase db, String userId) async {
    final key = await _loadKey();
    final json = await _buildJsonPayload(db, userId);
    final encrypted = _encrypt(json, key);
    final envelope = _buildEnvelope(encrypted);

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, _backupFileName));
    await file.writeAsBytes(envelope, flush: true);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/octet-stream')],
      subject: 'CipherOwl Backup',
    ));
  }

  // â”€â”€â”€ Import â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Opens a file picker, decrypts the selected `.cobk` file, and restores
  /// all vault items + settings into [db].
  ///
  /// Existing items with duplicate IDs are updated (upsert).
  /// Returns the number of vault items restored.
  ///
  /// Throws [BackupException] on failure (wrong key, corrupt file, etc.).
  static Future<int> importFromFile(SmartVaultDatabase db) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      throw const BackupException('ظ„ظ… ظٹطھظ… ط§ط®طھظٹط§ط± ط£ظٹ ظ…ظ„ظپ');
    }

    final path = result.files.single.path;
    if (path == null) throw const BackupException('ظ…ط³ط§ط± ط§ظ„ظ…ظ„ظپ ط؛ظٹط± ظ…طھط§ط­');

    final bytes = await File(path).readAsBytes();
    final key = await _loadKey();
    final json = _decryptEnvelope(bytes, key);
    final count = await _restoreFromJson(db, json);
    return count;
  }

  // â”€â”€â”€ Private helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Loads the AES key from secure storage as raw bytes (32 bytes).
  static Future<Uint8List> _loadKey() async {
    final hex = await _storage.read(key: _dbKeyStorageKey);
    if (hex == null || hex.length != 64) {
      throw const BackupException('ظ…ظپطھط§ط­ ظ‚ط§ط¹ط¯ط© ط§ظ„ط¨ظٹط§ظ†ط§طھ ط؛ظٹط± ظ…ظˆط¬ظˆط¯');
    }
    return Uint8List.fromList(
      List.generate(32, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
    );
  }

  /// Builds the JSON payload from the database.
  static Future<String> _buildJsonPayload(SmartVaultDatabase db, String userId) async {
    final items = await db.vaultDao.getAllItems(userId);
    final settings = await db.settingsDao.getAllSettings();

    final payload = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'vault_items': items.map((item) => {
        'id': item.id,
        'user_id': item.userId,
        'title': item.title,
        'username': item.username,
        'url': item.url,
        'category': item.category,
        'is_favorite': item.isFavorite,
        'is_deleted': item.isDeleted,
        'strength_score': item.strengthScore,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
        'synced_at': item.syncedAt?.toIso8601String(),
        // Encrypted blobs stored as base64 strings
        'encrypted_password': item.encryptedPassword != null
            ? base64Encode(item.encryptedPassword!)
            : null,
        'encrypted_notes': item.encryptedNotes != null
            ? base64Encode(item.encryptedNotes!)
            : null,
        'encrypted_totp_secret': item.encryptedTotpSecret != null
            ? base64Encode(item.encryptedTotpSecret!)
            : null,
      }).toList(),
      'settings': settings,
    };
    return jsonEncode(payload);
  }

  /// Encrypts [plaintext] with the given AES-256-GCM [key].
  /// Uses `apiEncrypt` which prepends a random 12-byte nonce to the output.
  /// Returns the nonce-prepended ciphertext blob.
  static Uint8List _encrypt(String plaintext, Uint8List key) {
    return apiEncrypt(
      plaintext: utf8.encode(plaintext),
      key: key.toList(),
    );
  }

  /// Builds the binary envelope: magic(4) + version(1) + encrypted_blob(N).
  static Uint8List _buildEnvelope(Uint8List encryptedBlob) {
    final header = Uint8List.fromList([..._kMagic, _kFormatVersion]);
    return Uint8List.fromList([...header, ...encryptedBlob]);
  }

  /// Decrypts a binary envelope and returns the JSON plaintext string.
  static String _decryptEnvelope(Uint8List bytes, Uint8List key) {
    // Validate magic + version (5 header bytes) + nonce(12) + min tag(16)
    if (bytes.length < 5 + 12 + 16) {
      throw const BackupException('ظ…ظ„ظپ ط§ظ„ظ†ط³ط®ط© ط§ظ„ط§ط­طھظٹط§ط·ظٹط© طھط§ظ„ظپ ط£ظˆ ط؛ظٹط± ظ…ظƒطھظ…ظ„');
    }
    for (int i = 0; i < 4; i++) {
      if (bytes[i] != _kMagic[i]) {
        throw const BackupException('ظ…ظ„ظپ ط؛ظٹط± طµط§ظ„ط­: ظ„ظٹط³ ظ…ظ„ظپ CipherOwl Backup');
      }
    }
    if (bytes[4] != _kFormatVersion) {
      throw const BackupException('ط¥طµط¯ط§ط± ظ…ظ„ظپ ط§ظ„ظ†ط³ط®ط© ط§ظ„ط§ط­طھظٹط§ط·ظٹط© ط؛ظٹط± ظ…ط¯ط¹ظˆظ…');
    }

    final ciphertextWithNonce = bytes.sublist(5).toList();

    try {
      final plaintext = apiDecrypt(
        ciphertextWithNonce: ciphertextWithNonce,
        key: key.toList(),
      );
      return utf8.decode(plaintext);
    } catch (_) {
      throw const BackupException(
          'ظپط´ظ„ ظپظƒ ط§ظ„طھط´ظپظٹط± â€” ط§ظ„ظ…ظپطھط§ط­ ط®ط§ط·ط¦ ط£ظˆ ط§ظ„ظ…ظ„ظپ طھط§ظ„ظپ');
    }
  }

  /// Restores vault items and settings from decrypted JSON.
  /// Returns the number of vault items upserted.
  static Future<int> _restoreFromJson(SmartVaultDatabase db, String json) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('ط¨ظٹط§ظ†ط§طھ ط§ظ„ظ†ط³ط®ط© ط§ظ„ط§ط­طھظٹط§ط·ظٹط© ط؛ظٹط± طµط§ظ„ط­ط©');
    }

    int count = 0;

    // Restore vault items
    final rawItems = payload['vault_items'] as List<dynamic>? ?? [];
    for (final raw in rawItems) {
      final map = raw as Map<String, dynamic>;
      await db.vaultDao.upsertItem(VaultItemsCompanion(
        id: Value(map['id'] as String),
        userId: Value(map['user_id'] as String),
        title: Value(map['title'] as String),
        username: Value.absentIfNull(map['username'] as String?),
        url: Value.absentIfNull(map['url'] as String?),
        category: Value(map['category'] as String? ?? 'login'),
        isFavorite: Value(map['is_favorite'] as bool? ?? false),
        isDeleted: Value(map['is_deleted'] as bool? ?? false),
        strengthScore: Value.absentIfNull(map['strength_score'] as int?),
        encryptedPassword: Value.absentIfNull(
          map['encrypted_password'] != null
              ? base64Decode(map['encrypted_password'] as String)
              : null,
        ),
        encryptedNotes: Value.absentIfNull(
          map['encrypted_notes'] != null
              ? base64Decode(map['encrypted_notes'] as String)
              : null,
        ),
        encryptedTotpSecret: Value.absentIfNull(
          map['encrypted_totp_secret'] != null
              ? base64Decode(map['encrypted_totp_secret'] as String)
              : null,
        ),
        updatedAt: Value(DateTime.parse(map['updated_at'] as String)),
        createdAt: Value(DateTime.parse(map['created_at'] as String)),
      ));
      count++;
    }

    // Restore settings (skip sensitive keys like argon2_salt)
    const skipKeys = {'argon2_salt', 'cipherowl_db_key_v1'};
    final rawSettings = payload['settings'] as Map<String, dynamic>? ?? {};
    for (final entry in rawSettings.entries) {
      if (skipKeys.contains(entry.key)) continue;
      await db.settingsDao.setSetting(entry.key, entry.value as String);
    }

    return count;
  }
}

// â”€â”€â”€ Exception â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}
