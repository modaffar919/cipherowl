$descriptions = @{
    # EPIC-1 tasks
    "cipherowl-6hi" = "Install Flutter SDK (stable channel), add to system PATH, run flutter doctor to verify. Required: Git, VS Code with Flutter extension."
    "cipherowl-2qj" = "Install Rust via rustup, add Android/iOS cross-compile targets: aarch64-linux-android, armv7-linux-androideabi, aarch64-apple-ios, x86_64-apple-ios."
    "cipherowl-8k3" = "Run flutter pub get to download and resolve all 40+ dependencies in pubspec.yaml. Fix any version conflicts."
    "cipherowl-1kg" = "Configure android/app/build.gradle: minSdkVersion 24, NDK for Rust compilation, release signing config, ProGuard rules for crypto libraries."
    "cipherowl-ag6" = "Configure ios/Runner.xcodeproj: Bundle ID com.cipherowl.app, minimum iOS 14.0, add camera/FaceID/autofill permissions to Info.plist."
    "cipherowl-4ho" = "COMPILE BLOCKER: Create lib/l10n/app_localizations.dart stub or run flutter gen-l10n. Without this file, the project will not compile."
    "cipherowl-zis" = "Create l10n/app_ar.arb and l10n/app_en.arb with all UI strings. Arabic is primary language. Run flutter gen-l10n after creating files."
    "cipherowl-8gi" = "Download and add Cairo (Arabic UI font) and SpaceMono (monospace for passwords) to assets/fonts/. Update pubspec.yaml font declarations."
    "cipherowl-z58" = "Create .gitignore with Flutter/Dart ignores, build/ output, .env files, signing keys, Rust target/ directory, IDE files."
    "cipherowl-9bz" = "Final gate: Run flutter build apk --debug and flutter build ios --debug to verify the complete project compiles with zero errors."

    # EPIC-2 tasks
    "cipherowl-d4r" = "Create native/smartvault_core/ with Cargo.toml. Dependencies: aes-gcm, argon2, x25519-dalek, zeroize, rand, base64. Lib.rs with module structure."
    "cipherowl-bcz" = "Implement AES-256-GCM encrypt/decrypt in Rust. 256-bit key, 96-bit nonce, 128-bit auth tag. Functions: encrypt(key, plaintext) -> ciphertext, decrypt(key, ciphertext) -> plaintext."
    "cipherowl-gqr" = "Implement Argon2id key derivation: time_cost=3, memory_cost=65536 (64MB), parallelism=4, output 32 bytes. Input: password + salt -> derived key."
    "cipherowl-dgh" = "Implement X25519 Elliptic Curve Diffie-Hellman key exchange for secure password sharing between users. Generate keypairs, compute shared secrets."
    "cipherowl-6bh" = "Implement secure memory handling: mlock to prevent swapping, zeroize for guaranteed memory clearing. All sensitive data (keys, passwords) must use SecureBuffer."
    "cipherowl-1za" = "Implement PBKDF2-HMAC-SHA256 with 600,000 iterations as fallback when Argon2id is unavailable. Same input/output interface as Argon2id."
    "cipherowl-0i5" = "Write comprehensive Rust tests using NIST SP 800-38D test vectors for AES-GCM, IETF test vectors for Argon2id, RFC 7748 vectors for X25519."
    "cipherowl-p6g" = "Configure flutter_rust_bridge to generate Dart FFI bindings from Rust code. Setup codegen, build scripts for Android NDK and iOS. Critical bridge between Flutter and Rust."

    # EPIC-3 tasks
    "cipherowl-nlo" = "Define Drift schema: VaultItems (id, title, username, encrypted_password, url, category, notes, totp_secret, created_at, updated_at), SecurityLogs (event_type, details, timestamp), UserSettings (key, value)."
    "cipherowl-5d9" = "Configure SQLCipher encryption for Drift database. Encryption key derived from master password via Argon2id (from Rust core). Database file fully encrypted at rest."
    "cipherowl-073" = "Create Drift DAO classes: VaultDao (CRUD + search + filter by category), SettingsDao (get/set key-value), SecurityLogDao (insert + query by date range)."
    "cipherowl-jv1" = "Run flutter pub run build_runner build to generate Drift database code (.g.dart files). Verify generated code compiles correctly."
    "cipherowl-4ed" = "Implement database migration strategy for schema changes. Version tracking, migration scripts, backward compatibility for app updates."
    "cipherowl-8xg" = "Add encrypted database backup to file and restore from backup. Export/import via share sheet. Backup includes all vault items and settings."

    # EPIC-4 tasks
    "cipherowl-dw8" = "Create AuthBloc: States (initial, loading, authenticated, locked, biometricRequired, error). Events (login, logout, lock, unlock, biometricAuth). Manages master password and session."
    "cipherowl-gtb" = "Create VaultBloc: CRUD operations, search by title/username/url, filter by category (login/card/note/identity), sort by name/date/category. Emits list state with filters."
    "cipherowl-lup" = "Create GeneratorBloc: Generate passwords with configurable length (8-128), character sets (upper/lower/digits/symbols), pronounceable mode, passphrase mode (4-10 words)."
    "cipherowl-yly" = "Create SecurityBloc: Calculate 6-layer security score (master password strength, reused passwords, weak passwords, 2FA coverage, breach exposure, update frequency). Emit recommendations."
    "cipherowl-1zi" = "Create SettingsBloc: Theme (light/dark/system), language (AR/EN), auto-lock timeout, biometric toggle, clipboard clear timeout, all user preferences."
    "cipherowl-ztk" = "Wire all 5 BLoCs to the 15 UI screens. Replace all demo/hardcoded data with real BLoC states. Implement BLoC providers, listeners, and builders throughout the app."
    "cipherowl-yot" = "Create GamificationBloc: Track XP points, calculate levels, manage badge unlocks (25 badges), track daily streaks. Persist state to local database."

    # EPIC-5 tasks
    "cipherowl-zig" = "Create Supabase project on supabase.com, get API URL and anon key. Update lib/core/constants/app_constants.dart with real Supabase credentials."
    "cipherowl-6i8" = "Create Supabase SQL schema: profiles (id, display_name, public_key, created_at), encrypted_vaults (id, user_id, encrypted_data, iv, version, updated_at)."
    "cipherowl-op4" = "Implement Supabase Auth: Email/password signup and login, Google OAuth, Apple Sign-In. Handle auth state changes, token refresh, session persistence."
    "cipherowl-8tj" = "Configure Row Level Security (RLS) policies on ALL Supabase tables. Users can only read/write their own data. No cross-user data access possible."
    "cipherowl-2qq" = "Implement zero-knowledge sync: Encrypt vault locally with user key, upload ciphertext to Supabase, download and decrypt on other devices. Server never sees plaintext. Conflict resolution via vector clocks."
    "cipherowl-rhy" = "Create Supabase Edge Functions: breach-check (proxy to HaveIBeenPwned with k-anonymity), send-notification (security alert push via FCM)."

    # EPIC-6 tasks
    "cipherowl-qm8" = "Integrate Google ML Kit Face Detection: detect faces in camera frames, get face bounding box, landmarks, and contours. Real-time processing for continuous monitoring."
    "cipherowl-9ts" = "Integrate MobileFaceNet TFLite model: Load .tflite model, preprocess face crops to 112x112, run inference to get 128-dimensional face embedding vectors."
    "cipherowl-ko8" = "Build face enrollment UI flow: Guide user to capture 5 face images from different angles (front, left, right, up, down). Store averaged embedding as reference template."
    "cipherowl-rtv" = "Implement face verification: Compare live face embedding against stored template using cosine similarity. Threshold 0.6 for match. Anti-spoofing with liveness detection."
    "cipherowl-fhh" = "Build background face monitoring service: Periodic camera captures (configurable interval), verify face matches enrolled user, auto-lock app if unauthorized face or no face detected."

    # EPIC-7 tasks
    "cipherowl-9rp" = "Implement FIDO2/WebAuthn credential registration: Generate keypair, create attestation, register with relying party. Support USB/NFC/BLE security keys."
    "cipherowl-b7k" = "Implement FIDO2/WebAuthn authentication flow: Challenge-response with registered credential. Support platform authenticators (fingerprint/face) and roaming authenticators (hardware keys)."
    "cipherowl-div" = "Implement intruder detection: After 3 consecutive failed login attempts, silently capture photo with front camera, log GPS location, store in SecurityLogs with timestamp."
    "cipherowl-dq0" = "Implement duress password: Secondary password that opens a fake vault with dummy data. Real vault remains hidden and encrypted. Alert can be silently sent to emergency contact."

    # EPIC-8 tasks
    "cipherowl-933" = "Implement TOTP code generation per RFC 6238: HMAC-SHA1 with 30-second period, 6-digit codes. Support SHA-256 and SHA-512 variants. Handle time drift correction."
    "cipherowl-kgc" = "QR code scanner to import TOTP secrets: Parse otpauth://totp/ URIs, extract secret, issuer, algorithm, digits, period. Camera-based scanning with mobile_scanner package."
    "cipherowl-6jv" = "Wire TOTP to vault item detail screen: Show live TOTP code with circular countdown timer, auto-refresh every 30 seconds, tap to copy code to clipboard."
    "cipherowl-df4" = "Implement BIP39 12-word recovery key: Generate from entropy, display during setup, verify user has saved it. Used to recover account if master password is forgotten."

    # EPIC-9 tasks
    "cipherowl-e0k" = "Create Rive owl mascot animations: Idle (blinking, head tilt), Thinking (processing), Success (happy nod), Error (shake head), Lock (close eyes). Used across all screens."
    "cipherowl-zaq" = "Implement Hero animations between screens and custom page transitions: Slide, fade, scale. SharedAxisTransition for related screens, FadeThroughTransition for unrelated."
    "cipherowl-at2" = "Create Lottie animations for transitions: Loading spinner, success checkmark, empty state, onboarding illustrations. Convert After Effects animations to .json format."
    "cipherowl-xw9" = "Animated password strength meter: Gradient color bar (red to green) with zxcvbn scoring (0-4), animated fill on keypress, strength label (Very Weak to Very Strong)."

    # EPIC-10 tasks
    "cipherowl-bgr" = "Implement 6-layer security score engine: (1) Master password strength, (2) Reused passwords count, (3) Weak passwords count, (4) 2FA coverage percentage, (5) Breach exposure, (6) Password age. Weighted average 0-100."
    "cipherowl-vyv" = "Integrate HaveIBeenPwned API with k-anonymity: SHA-1 hash password, send first 5 chars to API, check response for full hash match. Never sends full password hash to server."
    "cipherowl-jtm" = "Build security recommendations engine: Analyze vault, generate actionable recommendations (enable 2FA, change weak passwords, etc.), award XP for completing recommendations."
    "cipherowl-2tp" = "Wire security_center_screen.dart to real data: Replace hardcoded score with calculated value, show real breach alerts, display actual weak/reused password counts."

    # EPIC-11 tasks
    "cipherowl-26b" = "Implement Android AutofillService: Extend AutofillService class, handle fill requests, match by package name and web domain, provide autofill suggestions from vault."
    "cipherowl-yqj" = "Implement iOS AutoFill Credential Provider extension: Create App Extension target, implement ASCredentialProviderViewController, integrate with iOS password autofill."

    # EPIC-12 tasks
    "cipherowl-a5f" = "Implement X25519 encrypted item sharing: Generate ephemeral keypair, ECDH with recipient public key, encrypt vault item, send via Supabase. Only recipient can decrypt."
    "cipherowl-obe" = "Build organization team vault: Shared vault with role-based access (admin/member/viewer), invite by email, encrypted group key distribution, audit log for all actions."

    # EPIC-13 tasks
    "cipherowl-wnk" = "Configure Firebase project: Create project in Firebase console, add google-services.json (Android) and GoogleService-Info.plist (iOS), initialize Firebase in main.dart."
    "cipherowl-6mm" = "Implement push notifications via FCM: Security alert notifications (breach detected, unauthorized access attempt, weak password warning), notification channels, background handling."
    "cipherowl-2p5" = "Build in-app notification center: List of all security events and alerts, read/unread status, swipe to dismiss, tap to navigate to relevant screen, badge count on tab."

    # EPIC-14 tasks
    "cipherowl-kj5" = "Create security academy content: 10 threat awareness modules (phishing, social engineering, malware, etc.) in Arabic and English. Each module has lessons, illustrations, and quiz."
    "cipherowl-rmq" = "Implement quiz system: Multiple choice questions per module, scoring (correct/incorrect/time bonus), XP rewards for completion, review incorrect answers."
    "cipherowl-p7t" = "Build badge achievement system: 25 badges (First Login, Vault Master, Security Expert, etc.), unlock conditions, badge display grid, share badge to social media."
    "cipherowl-7dw" = "Daily security challenges: One challenge per day (change a weak password, enable 2FA, etc.), streak tracking, bonus XP for consecutive days, streak freeze item."

    # EPIC-15 tasks
    "cipherowl-dla" = "Write unit tests for all BLoCs: AuthBloc, VaultBloc, GeneratorBloc, SecurityBloc, SettingsBloc, GamificationBloc. Test all states and transitions. Target 90%+ coverage."
    "cipherowl-bbt" = "Write widget tests for all 15 screens: Test rendering, user interactions, navigation, form validation, error states. Use WidgetTester and mock BLoCs."
    "cipherowl-8ij" = "Write integration tests: End-to-end flows (onboarding, login, add item, generate password, search, share, backup/restore). Use integration_test package."
    "cipherowl-d5r" = "Security audit against OWASP MASVS: Check all L1+L2 requirements, penetration testing (API, local storage, crypto, network), fix all findings. Document results."

    # EPIC-16 tasks
    "cipherowl-j7j" = "Configure release signing: Generate Android keystore and configure build.gradle signingConfigs, create iOS distribution certificate and provisioning profile in Xcode."
    "cipherowl-fce" = "Create app icons (all required sizes) and splash screens from CipherOwl logo SVGs. Android adaptive icon, iOS icon set, launch screen with logo animation."
    "cipherowl-jf1" = "Prepare App Store listings: Screenshots for all device sizes, app description in Arabic and English, keywords, privacy policy URL, feature graphic."
    "cipherowl-jsl" = "Setup CI/CD with GitHub Actions: Build on push/PR, run tests, lint, build APK/IPA, deploy to Firebase App Distribution (beta) and Play Store/App Store (release)."
    "cipherowl-179" = "Write graduation project report: Introduction, literature review, system design, implementation details, testing results, conclusion. Prepare presentation slides."

    # Standalone tasks
    "cipherowl-4i7" = "Implement admin dashboard for enterprise: User management, policy configuration, audit logs viewer, analytics. Web-based admin panel or in-app admin section."
    "cipherowl-x0y" = "Browser extension for autofill (Phase 2): Chrome/Firefox extension that communicates with mobile app, fills credentials on desktop browsers. Future enhancement."
}

$count = 0
foreach ($entry in $descriptions.GetEnumerator()) {
    $id = $entry.Key
    $desc = $entry.Value -replace "'", "''"
    $sql = "UPDATE beads.issues SET description = '$desc' WHERE id = '$id'"
    bd sql $sql 2>$null
    $count++
    if ($count % 10 -eq 0) { Write-Host "$count tasks updated..." }
}
Write-Host "Done! Updated $count task descriptions."
