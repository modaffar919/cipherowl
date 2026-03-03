#!/usr/bin/env pwsh
# =============================================================================
# CipherOwl Security - Beads Task Setup Script
# =============================================================================
# This script creates the complete task hierarchy for the CipherOwl project.
# Each EPIC is an independent work unit that can be assigned to a different
# developer without conflicts.
#
# Usage: .\beads_setup.ps1
# Prerequisites: bd CLI + Dolt installed, bd init already ran
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CipherOwl - Beads Task Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# =============================================================================
# EPIC 1: Project Foundation & Build System
# Owner: DevOps / Lead Developer
# Priority: P0 (Highest - blocks everything)
# =============================================================================
Write-Host "[EPIC 1] Project Foundation & Build System..." -ForegroundColor Yellow

$epic1 = bd create "EPIC-1: Project Foundation & Build System" -p 0 -t epic --json 2>$null | ConvertFrom-Json
$e1 = $epic1.id
Write-Host "  Created: $e1" -ForegroundColor Green

$t1_1 = (bd create "Install Flutter SDK and configure PATH" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Install Flutter SDK 3.24+ on all dev machines. Run flutter doctor. Ensure Android SDK, Xcode (macOS), Chrome are configured." | bd update $t1_1 --description=-
bd dep add $t1_1 $e1

$t1_2 = (bd create "Install Rust toolchain and targets" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Install rustup, add targets: aarch64-linux-android, armv7-linux-androideabi, x86_64-linux-android, aarch64-apple-ios, x86_64-apple-ios. Install cargo-ndk." | bd update $t1_2 --description=-
bd dep add $t1_2 $e1

$t1_3 = (bd create "Run flutter pub get and resolve dependencies" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Run flutter pub get in project root. Resolve any version conflicts in pubspec.yaml (40+ deps). Ensure all packages download." | bd update $t1_3 --description=-
bd dep add $t1_3 $t1_1

$t1_4 = (bd create "Add font files (Cairo + SpaceMono)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Download Cairo (300,400,600,700) and SpaceMono (400) font files. Place in assets/fonts/. Verify pubspec.yaml font declarations." | bd update $t1_4 --description=-
bd dep add $t1_4 $e1

$t1_5 = (bd create "Create .gitignore for Flutter project" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Add standard Flutter .gitignore: build/, .dart_tool/, .packages, *.iml, .idea/, android/local.properties, ios/Pods/, etc." | bd update $t1_5 --description=-
bd dep add $t1_5 $e1

$t1_6 = (bd create "Configure Android build.gradle (minSdk, NDK)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Set minSdkVersion=24, targetSdkVersion=34, compileSdkVersion=34. Configure NDK for Rust. Set applicationId=com.cipherowl.app. Add signingConfigs." | bd update $t1_6 --description=-
bd dep add $t1_6 $t1_3

$t1_7 = (bd create "Configure iOS Xcode project settings" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Set minimum iOS 15.0. Configure bundle ID=com.cipherowl.app. Add camera/biometric permissions in Info.plist. Configure signing." | bd update $t1_7 --description=-
bd dep add $t1_7 $t1_3

$t1_8 = (bd create "Create app_localizations.dart (compile blocker)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Create lib/core/localization/app_localizations.dart. This file is imported by app.dart but doesn't exist yet - BLOCKS COMPILATION. Implement AppLocalizations class with ar/en delegates." | bd update $t1_8 --description=-
bd dep add $t1_8 $t1_3

$t1_9 = (bd create "Create l10n ARB files (Arabic + English)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Create lib/l10n/app_ar.arb and app_en.arb with all UI strings. Arabic is primary locale. ~200+ string keys covering all 15 screens." | bd update $t1_9 --description=-
bd dep add $t1_9 $t1_8

$t1_10 = (bd create "Verify project compiles (flutter build)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Run flutter build apk --debug. Fix all compile errors. Ensure app launches to SplashScreen. This is the gate for all other EPICs." | bd update $t1_10 --description=-
bd dep add $t1_10 $t1_8
bd dep add $t1_10 $t1_6

Write-Host "  EPIC 1 complete: 10 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 2: Rust Crypto Core (native/smartvault_core)
# Owner: Security Engineer / Rust Developer
# Priority: P0 (Core security - blocks vault operations)
# =============================================================================
Write-Host "[EPIC 2] Rust Crypto Core..." -ForegroundColor Yellow

$epic2 = bd create "EPIC-2: Rust Cryptography Core" -p 0 -t epic --json 2>$null | ConvertFrom-Json
$e2 = $epic2.id
Write-Host "  Created: $e2" -ForegroundColor Green

$t2_1 = (bd create "Scaffold Rust crate with Cargo.toml" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Create native/smartvault_core/ with Cargo.toml. Dependencies: argon2(0.5), aes-gcm(0.10), x25519-dalek(2.0), chacha20poly1305(0.10), zeroize(1.7), rand(0.8), serde(1.0), serde_json." | bd update $t2_1 --description=-
bd dep add $t2_1 $e2
bd dep add $t2_1 $t1_2

$t2_2 = (bd create "Implement Argon2id key derivation" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Implement derive_key(password, salt) -> [u8;32]. Params: t=3, m=65536KB, p=4. Use zeroize for secure memory cleanup. Return 256-bit key." | bd update $t2_2 --description=-
bd dep add $t2_2 $t2_1

$t2_3 = (bd create "Implement AES-256-GCM encrypt/decrypt" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Functions: encrypt(key, plaintext) -> (nonce, ciphertext, tag), decrypt(key, nonce, ciphertext, tag) -> plaintext. 96-bit random nonce. Use aes-gcm crate." | bd update $t2_3 --description=-
bd dep add $t2_3 $t2_1

$t2_4 = (bd create "Implement X25519 key exchange for sharing" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Generate ephemeral X25519 keypairs. Compute shared_secret = ECDH(sender_private, recipient_public). Derive encryption key from shared_secret via HKDF-SHA256." | bd update $t2_4 --description=-
bd dep add $t2_4 $t2_1

$t2_5 = (bd create "Implement secure memory (mlock + zeroize)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "All sensitive data (keys, passwords) must be in zeroized containers. Use mlock() to prevent swapping. Implement SecureBuffer wrapper type." | bd update $t2_5 --description=-
bd dep add $t2_5 $t2_1

$t2_6 = (bd create "Implement PBKDF2 fallback (600K iterations)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "For devices that don't support Argon2id natively. PBKDF2-HMAC-SHA256 with 600,000 iterations. Same API as Argon2id derive_key." | bd update $t2_6 --description=-
bd dep add $t2_6 $t2_1

$t2_7 = (bd create "Configure flutter_rust_bridge FFI bindings" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Set up flutter_rust_bridge ^2.3.0. Generate Dart FFI bindings from Rust. Ensure bridge works on Android (cargo-ndk) and iOS. Test basic function call roundtrip." | bd update $t2_7 --description=-
bd dep add $t2_7 $t2_2
bd dep add $t2_7 $t2_3

$t2_8 = (bd create "Write Rust unit tests for all crypto ops" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Test vectors for: Argon2id (IETF test vectors), AES-256-GCM (NIST vectors), X25519 (RFC 7748 vectors). Edge cases: empty input, max size, wrong key." | bd update $t2_8 --description=-
bd dep add $t2_8 $t2_2
bd dep add $t2_8 $t2_3
bd dep add $t2_8 $t2_4

Write-Host "  EPIC 2 complete: 8 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 3: Local Database (Drift + SQLCipher)
# Owner: Backend Developer
# Priority: P0 (Blocks all data operations)
# =============================================================================
Write-Host "[EPIC 3] Local Database..." -ForegroundColor Yellow

$epic3 = bd create "EPIC-3: Local Database (Drift + SQLCipher)" -p 0 -t epic --json 2>$null | ConvertFrom-Json
$e3 = $epic3.id
Write-Host "  Created: $e3" -ForegroundColor Green

$t3_1 = (bd create "Create Drift database schema (tables)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Create lib/core/database/app_database.dart. Tables: VaultItems (id, title, username, encryptedPassword, encryptedNotes, category, url, iconUrl, totpSecret, strength, isFavorite, tags, createdAt, updatedAt), SecurityLogs (id, eventType, timestamp, details), UserSettings (key, value), SyncMetadata (id, lastSync, version)." | bd update $t3_1 --description=-
bd dep add $t3_1 $e3
bd dep add $t3_1 $t1_10

$t3_2 = (bd create "Configure SQLCipher encryption for Drift" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Use drift ^2.20.2 with sqlcipher_flutter_libs. Database encryption key derived from master password via Argon2id. Key stored in flutter_secure_storage. Configure PRAGMA cipher_page_size=4096." | bd update $t3_2 --description=-
bd dep add $t3_2 $t3_1
bd dep add $t3_2 $t2_7

$t3_3 = (bd create "Create Drift DAOs (VaultDao, SettingsDao)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "VaultDao: getAllItems, searchItems, getByCategory, insertItem, updateItem, deleteItem, getFavorites. SettingsDao: getSetting, setSetting, getAllSettings. SecurityLogDao: logEvent, getRecentLogs." | bd update $t3_3 --description=-
bd dep add $t3_3 $t3_1

$t3_4 = (bd create "Run Drift code generation (build_runner)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Run: dart run build_runner build. This generates *.g.dart files for Drift. Add build_runner and drift_dev to dev_dependencies. Verify generated files compile." | bd update $t3_4 --description=-
bd dep add $t3_4 $t3_3

$t3_5 = (bd create "Implement database migration strategy" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Handle schema upgrades between app versions. Use Drift's migration API. Write migration tests. Version 1 = initial schema." | bd update $t3_5 --description=-
bd dep add $t3_5 $t3_4

$t3_6 = (bd create "Add database backup/restore functionality" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Encrypted database export to file. Import from encrypted backup. Use AES-256-GCM from Rust core to encrypt the backup file. Verify integrity on restore." | bd update $t3_6 --description=-
bd dep add $t3_6 $t3_4
bd dep add $t3_6 $t2_7

Write-Host "  EPIC 3 complete: 6 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 4: State Management (BLoC)
# Owner: Flutter Developer
# Priority: P0 (Blocks all UI-data integration)
# =============================================================================
Write-Host "[EPIC 4] State Management (BLoC)..." -ForegroundColor Yellow

$epic4 = bd create "EPIC-4: State Management (BLoC Layer)" -p 0 -t epic --json 2>$null | ConvertFrom-Json
$e4 = $epic4.id
Write-Host "  Created: $e4" -ForegroundColor Green

$t4_1 = (bd create "Create AuthBloc (login/unlock/biometric)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "States: AuthInitial, AuthLoading, AuthAuthenticated, AuthLocked, AuthFailed, AuthSetupRequired. Events: LoginRequested, BiometricRequested, FIDORequested, LockRequested, SetupCompleted. Handle master password validation via Argon2id." | bd update $t4_1 --description=-
bd dep add $t4_1 $e4
bd dep add $t4_1 $t3_4

$t4_2 = (bd create "Create VaultBloc (CRUD + search + filter)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "States: VaultInitial, VaultLoading, VaultLoaded(items, filter, search), VaultError. Events: LoadItems, SearchItems, FilterByCategory, AddItem, UpdateItem, DeleteItem, ToggleFavorite. Wire to VaultDao." | bd update $t4_2 --description=-
bd dep add $t4_2 $e4
bd dep add $t4_2 $t3_4

$t4_3 = (bd create "Create SecurityBloc (score + layers)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Calculate security score from 6 layers (weights in app_constants.dart, total=100). Layers: masterPasswordStrength(25), uniquePasswords(20), twoFactorEnabled(20), biometricEnabled(15), recentBreachCheck(10), appUpdateStatus(10). Emit SecurityState with score, grade (A-F), recommendations." | bd update $t4_3 --description=-
bd dep add $t4_3 $e4
bd dep add $t4_3 $t3_4

$t4_4 = (bd create "Create SettingsBloc (all app settings)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Manage: faceTrackEnabled, biometricEnabled, duressEnabled, lockTimeout, darkWebMonitor, autofillEnabled, language(ar/en), autoBackup. Persist via SettingsDao. Emit SettingsState." | bd update $t4_4 --description=-
bd dep add $t4_4 $e4
bd dep add $t4_4 $t3_4

$t4_5 = (bd create "Create GeneratorBloc (password generation)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Replace demo logic in generator_screen.dart with proper BLoC. States: GeneratorState(password, strength, type). Events: GeneratePassword(length, options), GeneratePassphrase(wordCount), CopyToClipboard. Use Random.secure()." | bd update $t4_5 --description=-
bd dep add $t4_5 $e4

$t4_6 = (bd create "Create GamificationBloc (XP + levels)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Track XP from 13 actions (defined in app_constants.dart xpRewards map). Calculate level from 6 tiers (levelTitles). Emit: totalXP, currentLevel, nextLevelXP, badges(25 types), streak, challenges." | bd update $t4_6 --description=-
bd dep add $t4_6 $e4
bd dep add $t4_6 $t3_4

$t4_7 = (bd create "Wire all BLoCs to screens (replace demo data)" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Replace all hardcoded demo data in 15 screens with BlocBuilder/BlocListener. Connect: VaultListScreen->VaultBloc, DashboardScreen->AuthBloc+VaultBloc, SecurityCenterScreen->SecurityBloc, SettingsScreen->SettingsBloc, GeneratorScreen->GeneratorBloc." | bd update $t4_7 --description=-
bd dep add $t4_7 $t4_1
bd dep add $t4_7 $t4_2
bd dep add $t4_7 $t4_3

Write-Host "  EPIC 4 complete: 7 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 5: Supabase Cloud Backend
# Owner: Backend Developer
# Priority: P1 (Sync can come after offline-first works)
# =============================================================================
Write-Host "[EPIC 5] Supabase Cloud Backend..." -ForegroundColor Yellow

$epic5 = bd create "EPIC-5: Supabase Cloud Backend" -p 1 -t epic --json 2>$null | ConvertFrom-Json
$e5 = $epic5.id
Write-Host "  Created: $e5" -ForegroundColor Green

$t5_1 = (bd create "Create Supabase project and configure" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Create Supabase project. Get URL + anon key. Update app_constants.dart (replace placeholder supabaseUrl/supabaseAnonKey). Enable Auth, Database, Edge Functions, Storage." | bd update $t5_1 --description=-
bd dep add $t5_1 $e5

$t5_2 = (bd create "Create Supabase SQL schema (profiles, vaults)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Tables: profiles(id, email, encrypted_master_key_hash, public_key, created_at), encrypted_vaults(id, user_id, encrypted_data, iv, version, updated_at), shared_items(id, sender_id, recipient_id, encrypted_data, ephemeral_public_key, expires_at, one_time, pin_hash), sync_log(id, user_id, action, timestamp)." | bd update $t5_2 --description=-
bd dep add $t5_2 $t5_1

$t5_3 = (bd create "Configure Row Level Security (RLS) policies" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "CRITICAL SECURITY: Enable RLS on ALL tables. Policies: users can only read/write their own data. shared_items readable by sender OR recipient. Zero-knowledge: server never sees plaintext." | bd update $t5_3 --description=-
bd dep add $t5_3 $t5_2

$t5_4 = (bd create "Implement Supabase Auth (email + social)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Email/password signup+login. Google OAuth. Apple Sign-In. JWT token management. Session refresh. Password reset flow. Wire to AuthBloc." | bd update $t5_4 --description=-
bd dep add $t5_4 $t5_2
bd dep add $t5_4 $t4_1

$t5_5 = (bd create "Implement zero-knowledge sync protocol" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Sync flow: 1) Encrypt vault locally with AES-256-GCM, 2) Upload encrypted blob to Supabase, 3) On other device: download blob, decrypt with master key. Server NEVER sees plaintext. Conflict resolution: last-write-wins with vector clocks." | bd update $t5_5 --description=-
bd dep add $t5_5 $t5_3
bd dep add $t5_5 $t2_7

$t5_6 = (bd create "Create Edge Functions (breach check, notifications)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Edge Functions: 1) check-breach: k-anonymity HaveIBeenPwned API check (send first 5 chars of SHA-1 hash only), 2) send-notification: Firebase Cloud Messaging trigger for security alerts." | bd update $t5_6 --description=-
bd dep add $t5_6 $t5_2

Write-Host "  EPIC 5 complete: 6 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 6: Face-Track Biometric System
# Owner: ML Engineer / Mobile Developer
# Priority: P1 (Differentiating feature)
# =============================================================================
Write-Host "[EPIC 6] Face-Track Biometric System..." -ForegroundColor Yellow

$epic6 = bd create "EPIC-6: Face-Track Continuous Biometric" -p 1 -t epic --json 2>$null | ConvertFrom-Json
$e6 = $epic6.id
Write-Host "  Created: $e6" -ForegroundColor Green

$t6_1 = (bd create "Integrate MobileFaceNet TFLite model" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Download MobileFaceNet .tflite model. Place in assets/models/. Use tflite_flutter ^0.10.4 to load model. Input: 112x112 RGB face crop. Output: 128-dim embedding vector." | bd update $t6_1 --description=-
bd dep add $t6_1 $e6
bd dep add $t6_1 $t1_10

$t6_2 = (bd create "Implement face detection with ML Kit" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Use google_mlkit_face_detection ^0.11.0. Detect face bounding box from camera stream. Crop face region. Validate: exactly 1 face, sufficient size, good angle (no extreme pose)." | bd update $t6_2 --description=-
bd dep add $t6_2 $e6
bd dep add $t6_2 $t1_10

$t6_3 = (bd create "Build face enrollment flow (5 captures)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Wire face_setup_screen.dart to real camera. Capture 5 face images from different angles. Generate 5 embeddings. Store average embedding encrypted in secure storage. Show progress animation." | bd update $t6_3 --description=-
bd dep add $t6_3 $t6_1
bd dep add $t6_3 $t6_2

$t6_4 = (bd create "Implement face verification (cosine similarity)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Compare live face embedding vs stored embedding. Cosine similarity threshold >= 0.6 = match. Anti-spoofing: check liveness (blink detection, head movement). Return match confidence score." | bd update $t6_4 --description=-
bd dep add $t6_4 $t6_3

$t6_5 = (bd create "Build background face monitoring service" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Periodic face check every 30 seconds while app is in foreground. If face doesn't match -> auto-lock app. If no face detected for 60s -> auto-lock. Battery-efficient implementation." | bd update $t6_5 --description=-
bd dep add $t6_5 $t6_4

$t6_6 = (bd create "Implement intruder snapshot on auth failure" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "After 3 failed unlock attempts: silently capture front camera photo. Store encrypted locally + upload to Supabase. Show in security log with timestamp and location." | bd update $t6_6 --description=-
bd dep add $t6_6 $t6_2

Write-Host "  EPIC 6 complete: 6 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 7: FIDO2/WebAuthn & Advanced Auth
# Owner: Security Engineer
# Priority: P2
# =============================================================================
Write-Host "[EPIC 7] FIDO2/WebAuthn & Advanced Auth..." -ForegroundColor Yellow

$epic7 = bd create "EPIC-7: FIDO2/WebAuthn & Advanced Auth" -p 2 -t epic --json 2>$null | ConvertFrom-Json
$e7 = $epic7.id
Write-Host "  Created: $e7" -ForegroundColor Green

$t7_1 = (bd create "Implement FIDO2/WebAuthn registration" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Use platform authenticator (fingerprint/face via FIDO2). Register credential with Supabase as relying party. Store credential ID securely." | bd update $t7_1 --description=-
bd dep add $t7_1 $e7
bd dep add $t7_1 $t5_4

$t7_2 = (bd create "Implement FIDO2/WebAuthn authentication" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Authenticate using registered FIDO2 credential. Verify assertion with server. Fallback to password if FIDO2 fails." | bd update $t7_2 --description=-
bd dep add $t7_2 $t7_1

$t7_3 = (bd create "Implement duress password system" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Allow user to set a duress password. When entered: show fake vault with decoy data, silently wipe real data or alert emergency contact. Different from master password by exactly 1 character." | bd update $t7_3 --description=-
bd dep add $t7_3 $e7
bd dep add $t7_3 $t4_1

$t7_4 = (bd create "Implement BIP39 recovery key system" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Generate 12-word BIP39 mnemonic during setup. Derive recovery key from mnemonic. Encrypt master key backup with recovery key. Store encrypted backup in Supabase. Recovery flow: enter 12 words -> derive key -> decrypt master key." | bd update $t7_4 --description=-
bd dep add $t7_4 $e7
bd dep add $t7_4 $t2_7

Write-Host "  EPIC 7 complete: 4 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 8: TOTP & 2FA System
# Owner: Flutter Developer
# Priority: P1
# =============================================================================
Write-Host "[EPIC 8] TOTP & 2FA System..." -ForegroundColor Yellow

$epic8 = bd create "EPIC-8: TOTP & Two-Factor Authentication" -p 1 -t epic --json 2>$null | ConvertFrom-Json
$e8 = $epic8.id
Write-Host "  Created: $e8" -ForegroundColor Green

$t8_1 = (bd create "Implement TOTP code generation (RFC 6238)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Use otp ^3.1.4 package. Generate 6-digit TOTP codes with 30s period. Support HMAC-SHA1/SHA256/SHA512. Display countdown timer. Auto-refresh code." | bd update $t8_1 --description=-
bd dep add $t8_1 $e8
bd dep add $t8_1 $t1_10

$t8_2 = (bd create "QR code scanner for TOTP secret import" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Use mobile_scanner ^5.1.1. Scan otpauth:// QR codes. Parse URI: issuer, account, secret, algorithm, digits, period. Auto-create vault item with TOTP secret." | bd update $t8_2 --description=-
bd dep add $t8_2 $e8
bd dep add $t8_2 $t1_10

$t8_3 = (bd create "Wire TOTP to vault item detail screen" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Replace static TOTP card in vault_item_detail_screen.dart with live countdown. Show animated circular progress. Auto-copy on tap. Support multiple TOTP per item." | bd update $t8_3 --description=-
bd dep add $t8_3 $t8_1
bd dep add $t8_3 $t4_7

Write-Host "  EPIC 8 complete: 3 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 9: Animations & Visual Polish
# Owner: UI/UX Developer
# Priority: P2
# =============================================================================
Write-Host "[EPIC 9] Animations & Visual Polish..." -ForegroundColor Yellow

$epic9 = bd create "EPIC-9: Animations & Visual Polish (Rive + Lottie)" -p 2 -t epic --json 2>$null | ConvertFrom-Json
$e9 = $epic9.id
Write-Host "  Created: $e9" -ForegroundColor Green

$t9_1 = (bd create "Create Rive animations (owl mascot)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Design CipherOwl mascot in Rive editor. States: idle (blinking), scanning (eyes moving), locked (eyes closed), alert (eyes wide + red), happy (eyes curved + sparkle). Export .riv files to assets/animations/." | bd update $t9_1 --description=-
bd dep add $t9_1 $e9

$t9_2 = (bd create "Create Lottie animations (transitions)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Lottie animations for: loading spinner, success checkmark, error shake, lock/unlock transition, shield pulse, XP gain celebration. Place .json files in assets/animations/." | bd update $t9_2 --description=-
bd dep add $t9_2 $e9

$t9_3 = (bd create "Implement page transitions (Hero + custom)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Hero animations for vault item cards. Custom slide/fade transitions between screens. Staggered list animations for vault items. Shimmer loading effect for skeleton screens." | bd update $t9_3 --description=-
bd dep add $t9_3 $e9
bd dep add $t9_3 $t1_10

$t9_4 = (bd create "Password strength meter animations" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Animated color-changing strength bar (red->orange->yellow->green). Animated score counter. Crack time display with typewriter effect. Use zxcvbn ^1.0.0 for scoring." | bd update $t9_4 --description=-
bd dep add $t9_4 $e9
bd dep add $t9_4 $t1_10

Write-Host "  EPIC 9 complete: 4 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 10: Security Center & Dark Web Monitoring
# Owner: Security Engineer
# Priority: P1
# =============================================================================
Write-Host "[EPIC 10] Security Center & Dark Web..." -ForegroundColor Yellow

$epic10 = bd create "EPIC-10: Security Center & Dark Web Monitoring" -p 1 -t epic --json 2>$null | ConvertFrom-Json
$e10 = $epic10.id
Write-Host "  Created: $e10" -ForegroundColor Green

$t10_1 = (bd create "Implement security score calculation engine" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Calculate real security score from 6 weighted layers (defined in app_constants.dart). Analyze all vault items for: password reuse, weak passwords, old passwords, missing 2FA. Grade A-F." | bd update $t10_1 --description=-
bd dep add $t10_1 $e10
bd dep add $t10_1 $t4_3

$t10_2 = (bd create "HaveIBeenPwned breach check (k-anonymity)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Check passwords against HIBP API using k-anonymity: SHA-1 hash password, send first 5 chars, compare remaining hash against returned list. Never send full hash. Show breach count per password." | bd update $t10_2 --description=-
bd dep add $t10_2 $e10
bd dep add $t10_2 $t4_2

$t10_3 = (bd create "Build security recommendations engine" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Generate actionable recommendations: 'Change 5 reused passwords', 'Enable 2FA on 3 accounts', 'Update 8 old passwords (>90 days)'. Each recommendation awards XP when completed." | bd update $t10_3 --description=-
bd dep add $t10_3 $t10_1

$t10_4 = (bd create "Wire security_center_screen to real data" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Replace animated shield demo with real score. Populate 6 security layers with calculated values. Show real recommendations list. Animate score changes." | bd update $t10_4 --description=-
bd dep add $t10_4 $t10_1
bd dep add $t10_4 $t10_3

Write-Host "  EPIC 10 complete: 4 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 11: Autofill Service
# Owner: Platform Developer
# Priority: P1
# =============================================================================
Write-Host "[EPIC 11] Autofill Service..." -ForegroundColor Yellow

$epic11 = bd create "EPIC-11: Autofill Service (Android + iOS)" -p 1 -t epic --json 2>$null | ConvertFrom-Json
$e11 = $epic11.id
Write-Host "  Created: $e11" -ForegroundColor Green

$t11_1 = (bd create "Android AutofillService implementation" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Implement Android AutofillService. Register as autofill provider in AndroidManifest.xml. Detect username/password fields. Show CipherOwl fill suggestion. Require biometric before filling." | bd update $t11_1 --description=-
bd dep add $t11_1 $e11
bd dep add $t11_1 $t4_2

$t11_2 = (bd create "iOS AutoFill Credential Provider" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Create AutoFill Credential Provider extension for iOS. Register in Capabilities. Provide credentials from vault. Require Face ID/Touch ID before filling." | bd update $t11_2 --description=-
bd dep add $t11_2 $e11
bd dep add $t11_2 $t4_2

$t11_3 = (bd create "Browser extension autofill (Phase 2)" -p 3 --json 2>$null | ConvertFrom-Json).id
echo "Future: Chrome/Firefox/Safari extension for desktop autofill. Communicate with mobile app via Supabase realtime. Low priority - Phase 2." | bd update $t11_3 --description=-
bd dep add $t11_3 $e11

Write-Host "  EPIC 11 complete: 3 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 12: Sharing & Enterprise
# Owner: Backend Developer
# Priority: P2
# =============================================================================
Write-Host "[EPIC 12] Sharing & Enterprise..." -ForegroundColor Yellow

$epic12 = bd create "EPIC-12: Encrypted Sharing & Enterprise" -p 2 -t epic --json 2>$null | ConvertFrom-Json
$e12 = $epic12.id
Write-Host "  Created: $e12" -ForegroundColor Green

$t12_1 = (bd create "Implement X25519 encrypted sharing" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Wire sharing_screen.dart to Rust X25519. Flow: lookup recipient public key from Supabase -> ECDH shared secret -> AES-256-GCM encrypt item -> store in shared_items table. Support expiry, one-time, PIN protection." | bd update $t12_1 --description=-
bd dep add $t12_1 $e12
bd dep add $t12_1 $t2_4
bd dep add $t12_1 $t5_2

$t12_2 = (bd create "Build organization/team vault" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Enterprise feature: shared team vault with role-based access (Admin, Manager, Member). Admin can assign items to roles. Audit log of who accessed what." | bd update $t12_2 --description=-
bd dep add $t12_2 $e12
bd dep add $t12_2 $t12_1

$t12_3 = (bd create "Implement admin dashboard for enterprise" -p 3 --json 2>$null | ConvertFrom-Json).id
echo "Wire enterprise_screen.dart to real data. Features: user management, policy enforcement, compliance reports, security score per team member, breach alerts. 8 feature cards." | bd update $t12_3 --description=-
bd dep add $t12_3 $e12
bd dep add $t12_3 $t12_2

Write-Host "  EPIC 12 complete: 3 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 13: Firebase & Push Notifications
# Owner: Mobile Developer
# Priority: P2
# =============================================================================
Write-Host "[EPIC 13] Firebase & Notifications..." -ForegroundColor Yellow

$epic13 = bd create "EPIC-13: Firebase & Push Notifications" -p 2 -t epic --json 2>$null | ConvertFrom-Json
$e13 = $epic13.id
Write-Host "  Created: $e13" -ForegroundColor Green

$t13_1 = (bd create "Configure Firebase project and add config files" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Create Firebase project. Download google-services.json (Android) and GoogleService-Info.plist (iOS). Add firebase_core, firebase_messaging to pubspec.yaml (already listed). Initialize in main.dart." | bd update $t13_1 --description=-
bd dep add $t13_1 $e13
bd dep add $t13_1 $t1_10

$t13_2 = (bd create "Implement push notifications for security alerts" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Notification types: breach detected, login from new device, intruder snapshot captured, shared item received, password expiry reminder. Handle foreground/background/terminated states." | bd update $t13_2 --description=-
bd dep add $t13_2 $t13_1

$t13_3 = (bd create "Implement in-app notification center" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "In-app notification list with read/unread status. Badge count on bottom nav. Grouped by type. Swipe to dismiss. Link to relevant screen on tap." | bd update $t13_3 --description=-
bd dep add $t13_3 $t13_2

Write-Host "  EPIC 13 complete: 3 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 14: Academy & Gamification
# Owner: Flutter Developer
# Priority: P2
# =============================================================================
Write-Host "[EPIC 14] Academy & Gamification..." -ForegroundColor Yellow

$epic14 = bd create "EPIC-14: Security Academy & Gamification" -p 2 -t epic --json 2>$null | ConvertFrom-Json
$e14 = $epic14.id
Write-Host "  Created: $e14" -ForegroundColor Green

$t14_1 = (bd create "Create academy content (10 threat modules)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Content for 10 threat cards (already in academy_screen.dart): Phishing, Malware, Social Engineering, Brute Force, Man-in-the-Middle, SQL Injection, Zero-Day, Ransomware, Insider Threat, IoT Attacks. Each: title_ar, title_en, description, quiz, XP reward." | bd update $t14_1 --description=-
bd dep add $t14_1 $e14

$t14_2 = (bd create "Implement quiz system with scoring" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "Multiple choice quiz per academy module. 5 questions each. Track score, show correct answers. Award XP on completion (first time only). Store completion in database." | bd update $t14_2 --description=-
bd dep add $t14_2 $t14_1
bd dep add $t14_2 $t4_6

$t14_3 = (bd create "Build badge/achievement system (25 badges)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "25 badges: First Password, Vault Master (100 items), Security Guru (score 95+), Academy Graduate (all modules), Streak King (30 days), Share Bear (first share), etc. Animated unlock ceremony." | bd update $t14_3 --description=-
bd dep add $t14_3 $t14_1
bd dep add $t14_3 $t4_6

$t14_4 = (bd create "Daily security challenges system" -p 3 --json 2>$null | ConvertFrom-Json).id
echo "Daily challenge: change a weak password, enable 2FA on an account, complete an academy module. Extra XP for daily streaks. Reset at midnight." | bd update $t14_4 --description=-
bd dep add $t14_4 $t14_3

Write-Host "  EPIC 14 complete: 4 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 15: Testing & Quality
# Owner: QA Engineer
# Priority: P1
# =============================================================================
Write-Host "[EPIC 15] Testing & Quality..." -ForegroundColor Yellow

$epic15 = bd create "EPIC-15: Testing & Quality Assurance" -p 1 -t epic --json 2>$null | ConvertFrom-Json
$e15 = $epic15.id
Write-Host "  Created: $e15" -ForegroundColor Green

$t15_1 = (bd create "Write unit tests for all BLoCs" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Test all BLoC states and transitions. Use bloc_test package. Mock dependencies with mocktail. Cover: AuthBloc, VaultBloc, SecurityBloc, SettingsBloc, GeneratorBloc. Target: 90%+ coverage." | bd update $t15_1 --description=-
bd dep add $t15_1 $e15
bd dep add $t15_1 $t4_7

$t15_2 = (bd create "Write widget tests for all screens" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Widget tests for all 15 screens. Test: renders correctly, user interactions work, navigation triggers, error states display. Use flutter_test + mockito." | bd update $t15_2 --description=-
bd dep add $t15_2 $e15
bd dep add $t15_2 $t4_7

$t15_3 = (bd create "Write integration tests (end-to-end)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Integration tests: full user flow from setup -> add item -> generate password -> search -> share -> lock -> unlock. Use integration_test package. Test on real device." | bd update $t15_3 --description=-
bd dep add $t15_3 $e15
bd dep add $t15_3 $t4_7

$t15_4 = (bd create "Security audit and penetration testing" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Audit: verify no plaintext in memory, secure storage usage, certificate pinning, root/jailbreak detection, no logging of sensitive data, proper key rotation, anti-tampering. Use OWASP MASVS checklist." | bd update $t15_4 --description=-
bd dep add $t15_4 $e15
bd dep add $t15_4 $t2_8

Write-Host "  EPIC 15 complete: 4 tasks" -ForegroundColor Green

# =============================================================================
# EPIC 16: Deployment & Release
# Owner: DevOps / Project Lead
# Priority: P1
# =============================================================================
Write-Host "[EPIC 16] Deployment & Release..." -ForegroundColor Yellow

$epic16 = bd create "EPIC-16: Deployment & App Store Release" -p 1 -t epic --json 2>$null | ConvertFrom-Json
$e16 = $epic16.id
Write-Host "  Created: $e16" -ForegroundColor Green

$t16_1 = (bd create "Create app icons and splash screens" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Generate adaptive icons for Android (foreground+background layers). iOS app icon set (all sizes). Splash screen with CipherOwl logo. Use flutter_native_splash. Logo files available in C:\Users\user\Desktop\CipherOwl_Logo\." | bd update $t16_1 --description=-
bd dep add $t16_1 $e16

$t16_2 = (bd create "Configure release signing (Android + iOS)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Android: Create keystore, configure signingConfigs in build.gradle, ProGuard rules. iOS: Configure provisioning profiles, distribution certificate, archive settings." | bd update $t16_2 --description=-
bd dep add $t16_2 $e16

$t16_3 = (bd create "App Store listing (screenshots, description)" -p 1 --json 2>$null | ConvertFrom-Json).id
echo "Create Play Store and App Store listings. Screenshots for phone+tablet. Feature graphic. Arabic+English descriptions. Privacy policy URL. App category: Tools/Security." | bd update $t16_3 --description=-
bd dep add $t16_3 $e16

$t16_4 = (bd create "CI/CD pipeline (GitHub Actions)" -p 2 --json 2>$null | ConvertFrom-Json).id
echo "GitHub Actions workflows: 1) PR check (lint+test), 2) Build APK/IPA on merge to main, 3) Deploy to Play Console/TestFlight beta, 4) Release to production on tag." | bd update $t16_4 --description=-
bd dep add $t16_4 $e16

$t16_5 = (bd create "Graduation project report and presentation" -p 0 --json 2>$null | ConvertFrom-Json).id
echo "Prepare graduation project deliverables: technical report (architecture, security model, algorithms), presentation slides, live demo plan, Q&A preparation. Include beads task tracking as project management evidence." | bd update $t16_5 --description=-
bd dep add $t16_5 $e16

Write-Host "  EPIC 16 complete: 5 tasks" -ForegroundColor Green

# =============================================================================
# Summary
# =============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  16 EPICs created with 80+ tasks" -ForegroundColor White
Write-Host "  All dependencies configured" -ForegroundColor White
Write-Host "  Ready for team assignment" -ForegroundColor White
Write-Host ""
Write-Host "  Commands:" -ForegroundColor Gray
Write-Host "    bd list              - See all tasks" -ForegroundColor Gray
Write-Host "    bd ready             - See unblocked tasks" -ForegroundColor Gray
Write-Host "    bd update ID --claim - Claim a task" -ForegroundColor Gray
Write-Host "    bd show ID           - View task details" -ForegroundColor Gray
Write-Host "    bd close ID          - Complete a task" -ForegroundColor Gray
Write-Host ""
