# CipherOwl API Documentation

## Architecture Overview

CipherOwl uses a layered architecture:

```
┌─────────────────────────────────────────────┐
│                Flutter UI                    │
│            (BLoC Pattern)                    │
├─────────────────────────────────────────────┤
│              Dart Services                   │
│  VaultCryptoService, RecoveryKeyService,     │
│  SharingService, AttachmentService, etc.     │
├─────────────────────────────────────────────┤
│         flutter_rust_bridge (FFI)            │
├─────────────────────────────────────────────┤
│           Rust Crypto Core                   │
│  AES-256-GCM, Argon2id, Ed25519, X25519,    │
│  TOTP, zxcvbn, BIP39, Face Matching         │
├─────────────────────────────────────────────┤
│        Drift + SQLCipher (Local DB)          │
│        Supabase (Cloud Sync)                 │
└─────────────────────────────────────────────┘
```

---

## Rust Crypto API (`native/smartvault_core/`)

All cryptographic operations run in the Rust core via FFI. Functions prefixed with `api_` are exposed to Dart.

### AES-256-GCM Encryption

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_generate_key()` | — | `Vec<u8>` (32 bytes) | Generate random AES-256 key |
| `api_generate_nonce()` | — | `Vec<u8>` (12 bytes) | Generate random GCM nonce |
| `api_encrypt(plaintext, key)` | `Vec<u8>`, `Vec<u8>` | `Result<Vec<u8>>` | Encrypt; output = `nonce(12) ‖ ciphertext+tag` |
| `api_decrypt(blob, key)` | `Vec<u8>`, `Vec<u8>` | `Result<Vec<u8>>` | Decrypt blob from `api_encrypt` |

### Key Derivation

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_derive_key(password, salt)` | `Vec<u8>`, `Vec<u8>` | `Result<Vec<u8>>` | Argon2id: t=3, m=64MiB, p=4 |
| `api_derive_key_pbkdf2(password, salt)` | `Vec<u8>`, `Vec<u8>` | `Vec<u8>` | PBKDF2-SHA512: 600K iterations (fallback) |
| `api_hash_password(password)` | `String` | `Result<String>` | Argon2id hash (PHC format) |
| `api_verify_password(password, hash)` | `String`, `String` | `Result<bool>` | Verify against PHC hash |

### X25519 Key Exchange

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_generate_x25519_private_key()` | — | `Vec<u8>` (32 bytes) | Random private key |
| `api_get_x25519_public_key(private_key)` | `Vec<u8>` | `Result<Vec<u8>>` | Derive public key |
| `api_derive_x25519_shared_secret(priv, pub)` | `Vec<u8>`, `Vec<u8>` | `Result<Vec<u8>>` | ECDH shared secret |

### Ed25519 Signatures

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_ed25519_generate_signing_key()` | — | `Vec<u8>` (32 bytes) | Random signing key |
| `api_ed25519_get_verifying_key(signing_key)` | `Vec<u8>` | `Result<Vec<u8>>` | Public verifying key |
| `api_ed25519_sign(message, signing_key)` | `Vec<u8>`, `Vec<u8>` | `Result<Vec<u8>>` (64 bytes) | Sign message |
| `api_ed25519_verify(message, sig, pub_key)` | `Vec<u8>`, `Vec<u8>`, `Vec<u8>` | `Result<bool>` | Verify signature |

### Encrypted Sharing

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_sharing_encrypt(plaintext, recipient_pub)` | `Vec<u8>`, `Vec<u8>` | `Result<Vec<u8>>` | Ephemeral ECDH + AES-GCM |
| `api_sharing_decrypt(blob, recipient_priv)` | `Vec<u8>`, `Vec<u8>` | `Result<Vec<u8>>` | Decrypt shared blob |

### TOTP (RFC 6238)

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_totp_generate(secret, timestamp)` | `String`, `u64` | `Result<String>` | 6-digit TOTP code |
| `api_totp_generate_custom(secret, ts, digits, period)` | `String`, `u64`, `u32`, `u64` | `Result<String>` | Custom digits/period |
| `api_totp_time_remaining(timestamp)` | `u64` | `u64` | Seconds left in window |

### Password Generation & Strength

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_generate_password(config)` | `ApiGeneratorConfig` | `Result<String>` | CSPRNG password |
| `api_estimate_strength(password)` | `String` | `ApiStrengthResult` | zxcvbn score (0–4) |

### Face Biometric

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_face_cosine_similarity(a, b)` | `Vec<f32>`, `Vec<f32>` | `Result<f32>` | Cosine similarity [-1, 1] |
| `api_face_is_same_person(a, b, threshold)` | `Vec<f32>`, `Vec<f32>`, `Option<f32>` | `Result<bool>` | Match check (default 0.75) |
| `api_face_find_best_match(probe, stored)` | `Vec<f32>`, `Vec<Vec<f32>>` | `Result<Option<(usize, f32)>>` | Best match index + score |

### BIP39 Recovery

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `api_generate_mnemonic(word_count)` | `usize` | `Result<Vec<String>>` | 12 or 24 word mnemonic |
| `api_validate_mnemonic(words)` | `Vec<String>` | `Result<bool>` | Validate checksum |
| `api_mnemonic_to_seed(words, passphrase)` | `Vec<String>`, `String` | `Result<Vec<u8>>` | 64-byte seed |

---

## Dart Service Layer

### VaultCryptoService (`lib/core/crypto/`)

Wraps Rust AES-256-GCM with automatic key management via `FlutterSecureStorage`.

```dart
class VaultCryptoService {
  Future<Uint8List> encrypt(String plaintext);
  Future<String> decrypt(Uint8List ciphertext);
  Future<Uint8List> encryptBytes(List<int> plaintext);
  Future<Uint8List> decryptBytes(Uint8List ciphertext);
  Future<void> rekeyFromDerivedKey(String hexKey);
  Future<void> clearKey();
}
```

Key storage: `cipherowl_vault_key_v1` in platform Keychain/Keystore.

### RecoveryKeyService (`lib/features/auth/data/services/`)

```dart
class RecoveryKeyService {
  String generateMnemonic();
  Future<Uint8List> deriveKey(String mnemonic);
  Future<void> saveVerifier(Uint8List derivedKey);
  Future<bool> verifyMnemonic(String mnemonic);
  Future<bool> get isSetUp;
  Future<void> clear();
  static List<String> splitWords(String mnemonic);
  static bool validateWords(List<String> words);
}
```

### AttachmentService (`lib/features/vault/data/services/`)

```dart
class AttachmentService {
  Future<VaultAttachment?> pickAndAttach(String itemId);
  Future<VaultAttachment> addAttachment({...});
  Future<List<VaultAttachment>> listAttachments(String itemId);
  Future<Uint8List> readAttachment(VaultAttachment attachment);
  Future<void> deleteAttachment(String attachmentId);
  Future<void> deleteAllForItem(String itemId);
  static String formatFileSize(int bytes);
}
```

### OfflineQueueService (`lib/features/sync/data/`)

```dart
class OfflineQueueService {
  void start();
  void dispose();
  Future<void> enqueue({required String operationType, required Map<String, dynamic> payload, String? itemId});
  Future<int> pendingCount();
  Stream<int> watchPendingCount();
  Future<void> drainQueue();
  Future<void> clearAll();
}
```

### ZeroKnowledgeSyncService (`lib/features/sync/data/`)

```dart
class ZeroKnowledgeSyncService {
  Future<SyncResult> sync({required List<VaultEntry> localItems, required Future<void> Function(List<VaultEntry>) onMerge});
}
```

### ThreeWayMergeEngine (`lib/features/sync/domain/`)

```dart
class ThreeWayMergeEngine {
  MergeResult merge({required VaultEntry base, required VaultEntry local, required VaultEntry remote});
}
```

---

## BLoC Layer

### Core BLoCs

| BLoC | Events | States | Purpose |
|------|--------|--------|---------|
| `AuthBloc` | `AuthAppStarted`, `MasterPasswordSubmitted`, `AuthVaultLocked`, `FaceVerified` | `AuthInitial`, `AuthLocked`, `AuthUnlocked`, `AuthFailed` | Authentication flow |
| `VaultBloc` | `VaultStarted`, `VaultItemAdded/Updated/Deleted`, `VaultDuressActivated`, `VaultCloudSyncRequested` | `VaultInitial`, `VaultLoading`, `VaultLoaded`, `VaultError` | Vault CRUD + duress |
| `SecurityBloc` | `SecurityStarted` | `SecurityLoaded` | Password health scores |
| `GeneratorBloc` | `GeneratorConfigChanged`, `GeneratorRefreshed` | `GeneratorState` | Password generation |
| `SettingsBloc` | Various toggles | `SettingsLoaded` | App settings |
| `GeofenceBloc` | `GeofenceStarted`, `GeofenceZoneAdded/Removed`, `GeofenceMonitoringToggled` | `GeofenceLoaded` | Location-based auto-lock |
| `GamificationBloc` | `GamificationStarted`, `GamificationXpEarned`, `GamificationBadgeUnlocked` | `GamificationLoaded` | Security gamification |
| `FaceEnrollmentBloc` | `FaceEnrollmentStarted`, `FaceEnrollmentCaptured` | `FaceEnrollmentState` | Biometric enrollment |

---

## Database Schema (Drift + SQLCipher)

### Core Tables

- **VaultItems**: Encrypted credentials (id, userId, title, encryptedPassword, encryptedNotes, category, strengthScore, timestamps)
- **VaultAttachments**: Encrypted file attachments (id, itemId, fileName, mimeType, fileSize, localPath)
- **VaultItemVersions**: Auto-versioning snapshots before mutations
- **PendingOperations**: Offline sync queue (operationType, payload, retryCount, maxRetries=5)
- **EmergencyContacts**: Emergency access contacts with ECDH public keys

### Security Features

- Database encrypted with SQLCipher (AES-256 page-level encryption)
- All sensitive fields use `Uint8List` (AES-256-GCM encrypted blobs)
- Vault key stored in platform Keychain/Keystore, never in DB

---

## Supabase Cloud Backend

### Edge Functions

- **share-vault-item**: Handles encrypted vault item sharing
- **send-notification**: Push notifications via FCM

### Database Tables (Cloud)

- **profiles**: User metadata
- **shared_items**: Encrypted sharing records
- **browser_autofill**: Encrypted credentials for browser extension
- **emergency_requests**: Emergency access requests with 72h delay

### Row-Level Security

All tables use Supabase RLS policies ensuring users can only access their own data.
