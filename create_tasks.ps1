Set-Location "C:\Users\user\OneDrive\Desktop\cipherowl"
$ErrorActionPreference = "Continue"

function New-Task($title, $priority, $parent) {
    $r = bd create $title -p $priority --json 2>$null | ConvertFrom-Json
    if ($parent) { bd dep add $r.id $parent 2>$null | Out-Null }
    Write-Host "  $($r.id) <- $title"
    return $r.id
}

# === EPIC 1 already has: cipherowl-d5g + cipherowl-6hi ===
Write-Host "EPIC-1 remaining tasks..." -ForegroundColor Yellow
$e1 = "cipherowl-d5g"
$t1_1 = "cipherowl-6hi"
$t1_2 = New-Task "Install Rust toolchain and cross-compile targets" 0 $e1
$t1_3 = New-Task "Run flutter pub get and resolve all dependencies" 0 $t1_1
$t1_4 = New-Task "Add font files Cairo and SpaceMono to assets" 1 $e1
$t1_5 = New-Task "Create .gitignore for Flutter project" 1 $e1
$t1_6 = New-Task "Configure Android build.gradle minSdk24 NDK signing" 0 $t1_3
$t1_7 = New-Task "Configure iOS Xcode project and Info.plist permissions" 1 $t1_3
$t1_8 = New-Task "Create app_localizations.dart - COMPILE BLOCKER" 0 $t1_3
$t1_9 = New-Task "Create l10n ARB files for Arabic and English" 1 $t1_8
$t1_10 = New-Task "Verify full project compiles with flutter build" 0 $t1_8

# === EPIC 2: Rust Crypto Core ===
Write-Host "`nEPIC-2: Rust Cryptography Core..." -ForegroundColor Yellow
$e2 = New-Task "EPIC-2: Rust Cryptography Core - native/smartvault_core" 0 $null
$t2_1 = New-Task "Scaffold Rust crate with Cargo.toml and deps" 0 $t1_2
bd dep add $t2_1 $e2 2>$null | Out-Null
$t2_2 = New-Task "Implement Argon2id key derivation t3 m65536 p4" 0 $t2_1
$t2_3 = New-Task "Implement AES-256-GCM encrypt and decrypt" 0 $t2_1
$t2_4 = New-Task "Implement X25519 ECDH key exchange for sharing" 1 $t2_1
$t2_5 = New-Task "Implement secure memory with mlock and zeroize" 0 $t2_1
$t2_6 = New-Task "Implement PBKDF2 fallback 600K iterations" 2 $t2_1
$t2_7 = New-Task "Configure flutter_rust_bridge FFI bindings" 0 $t2_2
bd dep add $t2_7 $t2_3 2>$null | Out-Null
$t2_8 = New-Task "Write Rust unit tests with NIST and IETF vectors" 0 $t2_2
bd dep add $t2_8 $t2_3 2>$null | Out-Null
bd dep add $t2_8 $t2_4 2>$null | Out-Null

# === EPIC 3: Local Database ===
Write-Host "`nEPIC-3: Local Database Drift + SQLCipher..." -ForegroundColor Yellow
$e3 = New-Task "EPIC-3: Local Database with Drift and SQLCipher" 0 $null
$t3_1 = New-Task "Create Drift database schema VaultItems SecurityLogs UserSettings" 0 $t1_10
bd dep add $t3_1 $e3 2>$null | Out-Null
$t3_2 = New-Task "Configure SQLCipher encryption for Drift database" 0 $t3_1
bd dep add $t3_2 $t2_7 2>$null | Out-Null
$t3_3 = New-Task "Create Drift DAOs VaultDao SettingsDao SecurityLogDao" 0 $t3_1
$t3_4 = New-Task "Run Drift code generation with build_runner" 0 $t3_3
$t3_5 = New-Task "Implement database migration strategy" 1 $t3_4
$t3_6 = New-Task "Add database backup and restore functionality" 2 $t3_4
bd dep add $t3_6 $t2_7 2>$null | Out-Null

# === EPIC 4: State Management ===
Write-Host "`nEPIC-4: State Management BLoC..." -ForegroundColor Yellow
$e4 = New-Task "EPIC-4: State Management BLoC Layer" 0 $null
$t4_1 = New-Task "Create AuthBloc with login unlock biometric states" 0 $t3_4
bd dep add $t4_1 $e4 2>$null | Out-Null
$t4_2 = New-Task "Create VaultBloc with CRUD search filter categories" 0 $t3_4
bd dep add $t4_2 $e4 2>$null | Out-Null
$t4_3 = New-Task "Create SecurityBloc score layers recommendations" 1 $t3_4
bd dep add $t4_3 $e4 2>$null | Out-Null
$t4_4 = New-Task "Create SettingsBloc for all app settings" 1 $t3_4
bd dep add $t4_4 $e4 2>$null | Out-Null
$t4_5 = New-Task "Create GeneratorBloc for password generation" 1 $e4
$t4_6 = New-Task "Create GamificationBloc XP levels badges streaks" 2 $t3_4
bd dep add $t4_6 $e4 2>$null | Out-Null
$t4_7 = New-Task "Wire all BLoCs to 15 screens replace demo data" 0 $t4_1
bd dep add $t4_7 $t4_2 2>$null | Out-Null
bd dep add $t4_7 $t4_3 2>$null | Out-Null

# === EPIC 5: Supabase Cloud Backend ===
Write-Host "`nEPIC-5: Supabase Cloud Backend..." -ForegroundColor Yellow
$e5 = New-Task "EPIC-5: Supabase Cloud Backend Zero-Knowledge" 1 $null
$t5_1 = New-Task "Create Supabase project and update config keys" 1 $e5
$t5_2 = New-Task "Create Supabase SQL schema profiles encrypted_vaults" 1 $t5_1
$t5_3 = New-Task "Configure Row Level Security RLS on all tables" 0 $t5_2
$t5_4 = New-Task "Implement Supabase Auth email and social login" 1 $t5_2
bd dep add $t5_4 $t4_1 2>$null | Out-Null
$t5_5 = New-Task "Implement zero-knowledge sync protocol" 0 $t5_3
bd dep add $t5_5 $t2_7 2>$null | Out-Null
$t5_6 = New-Task "Create Edge Functions breach check and notifications" 2 $t5_2

# === EPIC 6: Face-Track ===
Write-Host "`nEPIC-6: Face-Track Biometric System..." -ForegroundColor Yellow
$e6 = New-Task "EPIC-6: Face-Track Continuous Biometric Monitoring" 1 $null
$t6_1 = New-Task "Integrate MobileFaceNet TFLite 128-dim embeddings" 1 $t1_10
bd dep add $t6_1 $e6 2>$null | Out-Null
$t6_2 = New-Task "Implement face detection with Google ML Kit" 1 $t1_10
bd dep add $t6_2 $e6 2>$null | Out-Null
$t6_3 = New-Task "Build face enrollment flow 5 captures from angles" 1 $t6_1
bd dep add $t6_3 $t6_2 2>$null | Out-Null
$t6_4 = New-Task "Implement face verification cosine similarity 0.6" 1 $t6_3
$t6_5 = New-Task "Build background face monitoring service" 1 $t6_4
$t6_6 = New-Task "Implement intruder snapshot on 3 failed attempts" 2 $t6_2

# === EPIC 7: FIDO2 & Advanced Auth ===
Write-Host "`nEPIC-7: FIDO2 and Advanced Auth..." -ForegroundColor Yellow
$e7 = New-Task "EPIC-7: FIDO2 WebAuthn and Advanced Authentication" 2 $null
$t7_1 = New-Task "Implement FIDO2 WebAuthn credential registration" 2 $t5_4
bd dep add $t7_1 $e7 2>$null | Out-Null
$t7_2 = New-Task "Implement FIDO2 WebAuthn authentication flow" 2 $t7_1
$t7_3 = New-Task "Implement duress password with fake vault" 2 $t4_1
bd dep add $t7_3 $e7 2>$null | Out-Null
$t7_4 = New-Task "Implement BIP39 12-word recovery key system" 1 $t2_7
bd dep add $t7_4 $e7 2>$null | Out-Null

# === EPIC 8: TOTP & 2FA ===
Write-Host "`nEPIC-8: TOTP and 2FA..." -ForegroundColor Yellow
$e8 = New-Task "EPIC-8: TOTP Two-Factor Authentication System" 1 $null
$t8_1 = New-Task "Implement TOTP code generation RFC6238 30s period" 1 $t1_10
bd dep add $t8_1 $e8 2>$null | Out-Null
$t8_2 = New-Task "QR code scanner for TOTP secret import otpauth" 1 $t1_10
bd dep add $t8_2 $e8 2>$null | Out-Null
$t8_3 = New-Task "Wire TOTP to vault item detail with live countdown" 1 $t8_1
bd dep add $t8_3 $t4_7 2>$null | Out-Null

# === EPIC 9: Animations ===
Write-Host "`nEPIC-9: Animations and Visual Polish..." -ForegroundColor Yellow
$e9 = New-Task "EPIC-9: Animations Rive Lottie Visual Polish" 2 $null
$t9_1 = New-Task "Create Rive owl mascot animations states" 2 $e9
$t9_2 = New-Task "Create Lottie transition animations" 2 $e9
$t9_3 = New-Task "Implement Hero and custom page transitions" 2 $t1_10
bd dep add $t9_3 $e9 2>$null | Out-Null
$t9_4 = New-Task "Animated password strength meter with zxcvbn" 2 $t1_10
bd dep add $t9_4 $e9 2>$null | Out-Null

# === EPIC 10: Security Center ===
Write-Host "`nEPIC-10: Security Center and Dark Web..." -ForegroundColor Yellow
$e10 = New-Task "EPIC-10: Security Center and Dark Web Monitoring" 1 $null
$t10_1 = New-Task "Implement security score calculation engine 6 layers" 1 $t4_3
bd dep add $t10_1 $e10 2>$null | Out-Null
$t10_2 = New-Task "HaveIBeenPwned breach check k-anonymity API" 1 $t4_2
bd dep add $t10_2 $e10 2>$null | Out-Null
$t10_3 = New-Task "Build security recommendations engine with XP" 1 $t10_1
$t10_4 = New-Task "Wire security_center_screen to real calculated data" 1 $t10_1
bd dep add $t10_4 $t10_3 2>$null | Out-Null

# === EPIC 11: Autofill ===
Write-Host "`nEPIC-11: Autofill Service..." -ForegroundColor Yellow
$e11 = New-Task "EPIC-11: Autofill Service Android and iOS" 1 $null
$t11_1 = New-Task "Android AutofillService implementation" 1 $t4_2
bd dep add $t11_1 $e11 2>$null | Out-Null
$t11_2 = New-Task "iOS AutoFill Credential Provider extension" 1 $t4_2
bd dep add $t11_2 $e11 2>$null | Out-Null
$t11_3 = New-Task "Browser extension autofill Phase 2" 3 $e11

# === EPIC 12: Sharing & Enterprise ===
Write-Host "`nEPIC-12: Sharing and Enterprise..." -ForegroundColor Yellow
$e12 = New-Task "EPIC-12: Encrypted Sharing and Enterprise Features" 2 $null
$t12_1 = New-Task "Implement X25519 encrypted item sharing" 2 $t2_4
bd dep add $t12_1 $e12 2>$null | Out-Null
bd dep add $t12_1 $t5_2 2>$null | Out-Null
$t12_2 = New-Task "Build organization team vault with roles" 2 $t12_1
$t12_3 = New-Task "Implement admin dashboard for enterprise" 3 $t12_2

# === EPIC 13: Firebase ===
Write-Host "`nEPIC-13: Firebase and Notifications..." -ForegroundColor Yellow
$e13 = New-Task "EPIC-13: Firebase and Push Notifications" 2 $null
$t13_1 = New-Task "Configure Firebase project and config files" 2 $t1_10
bd dep add $t13_1 $e13 2>$null | Out-Null
$t13_2 = New-Task "Implement push notifications for security alerts" 2 $t13_1
$t13_3 = New-Task "Implement in-app notification center" 2 $t13_2

# === EPIC 14: Academy & Gamification ===
Write-Host "`nEPIC-14: Academy and Gamification..." -ForegroundColor Yellow
$e14 = New-Task "EPIC-14: Security Academy and Gamification System" 2 $null
$t14_1 = New-Task "Create academy content 10 threat modules AR EN" 2 $e14
$t14_2 = New-Task "Implement quiz system with scoring and XP" 2 $t14_1
bd dep add $t14_2 $t4_6 2>$null | Out-Null
$t14_3 = New-Task "Build badge achievement system 25 badges" 2 $t14_1
bd dep add $t14_3 $t4_6 2>$null | Out-Null
$t14_4 = New-Task "Daily security challenges and streaks" 3 $t14_3

# === EPIC 15: Testing ===
Write-Host "`nEPIC-15: Testing and Quality..." -ForegroundColor Yellow
$e15 = New-Task "EPIC-15: Testing and Quality Assurance" 1 $null
$t15_1 = New-Task "Write unit tests for all BLoCs 90pct coverage" 1 $t4_7
bd dep add $t15_1 $e15 2>$null | Out-Null
$t15_2 = New-Task "Write widget tests for all 15 screens" 1 $t4_7
bd dep add $t15_2 $e15 2>$null | Out-Null
$t15_3 = New-Task "Write integration tests end-to-end flows" 1 $t4_7
bd dep add $t15_3 $e15 2>$null | Out-Null
$t15_4 = New-Task "Security audit OWASP MASVS penetration testing" 0 $t2_8
bd dep add $t15_4 $e15 2>$null | Out-Null

# === EPIC 16: Deployment ===
Write-Host "`nEPIC-16: Deployment and Release..." -ForegroundColor Yellow
$e16 = New-Task "EPIC-16: Deployment and App Store Release" 1 $null
$t16_1 = New-Task "Create app icons and splash screens from logo" 1 $e16
$t16_2 = New-Task "Configure release signing Android and iOS" 1 $e16
$t16_3 = New-Task "App Store listing screenshots description AR EN" 1 $e16
$t16_4 = New-Task "CI/CD pipeline GitHub Actions build test deploy" 2 $e16
$t16_5 = New-Task "Graduation project report and presentation" 0 $e16

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ALL TASKS CREATED!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
