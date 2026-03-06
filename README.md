# 🦉 CipherOwl — Military-Grade Password Manager

<div align="center">

**حارسك الرقمي | Your Digital Guardian**

[![CI](https://github.com/modaffar919/cipherowl/actions/workflows/ci.yml/badge.svg)](https://github.com/modaffar919/cipherowl/actions/workflows/ci.yml)
[![Security Audit](https://github.com/modaffar919/cipherowl/actions/workflows/security-audit.yml/badge.svg)](https://github.com/modaffar919/cipherowl/actions/workflows/security-audit.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-Crypto_Core-000000?logo=rust)](https://www.rust-lang.org)

</div>

---

## Overview

CipherOwl is a zero-knowledge password manager combining **Rust-based military-grade cryptography** with **continuous biometric monitoring** and **gamified security education**. Built as a graduation project, it targets Android, iOS, Web, and Windows.

### Key Differentiators

- **Face-Track Lock** — Continuous face verification every 300ms; vault locks instantly when the user looks away
- **Zero-Knowledge Architecture** — All encryption happens client-side before any cloud sync
- **Rust Crypto Core** — AES-256-GCM, Argon2id, X25519 ECDH, Ed25519 signatures, secure memory with mlock/zeroize
- **Security Academy** — 10 threat-awareness modules with quizzes, XP, badges, and daily challenges
- **Travel Mode** — Hide sensitive vault categories at border crossings

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3.41+ / Dart 3.3+ |
| Crypto Core | Rust via flutter_rust_bridge (FFI) |
| State Management | BLoC (flutter_bloc) |
| Local Database | Drift + SQLCipher (AES-256 encrypted) |
| Cloud Backend | Supabase (PostgreSQL + RLS + Edge Functions) |
| Biometrics | Google ML Kit + MobileFaceNet TFLite |
| Navigation | GoRouter |
| Animations | Rive + Lottie |
| Languages | Arabic (primary) + English |

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Flutter UI (BLoC)                  │
│  15 screens · Arabic-first · WCAG 2.1 AA accessible  │
├──────────────────────────────────────────────────────┤
│              Domain / Repository Layer               │
├────────────────┬─────────────────┬───────────────────┤
│  Drift+SQLCipher│   Supabase      │  Rust FFI         │
│  (local vault)  │  (zero-knowledge│  (AES-GCM,        │
│                 │   cloud sync)   │   Argon2id,       │
│                 │                 │   X25519, Ed25519) │
└────────────────┴─────────────────┴───────────────────┘
```

### Feature Modules

| Module | Description |
|--------|-------------|
| `auth` | Master password, biometric, FIDO2/WebAuthn, magic link, duress mode |
| `vault` | CRUD, search, categories, favorites, versioning, import/export |
| `generator` | Password & passphrase generation with zxcvbn strength analysis |
| `security_center` | 6-layer security score, dark web monitoring (HIBP k-anonymity) |
| `face_track` | 5-pose enrollment, background face monitoring, liveness detection |
| `sync` | 3-way merge, offline queue, conflict resolution |
| `academy` | 10 modules, quizzes, XP/badges/streaks gamification |
| `autofill` | Android AutofillService + iOS Credential Provider |
| `travel_mode` | Hide vault categories at borders |
| `notifications` | FCM push + in-app notification center |

---

## Getting Started

### Prerequisites

- Flutter 3.41+ (`flutter --version`)
- Rust toolchain (`rustup show`)
- Android SDK (API 24+) or Xcode (iOS 14+)
- Java 17

### Setup

```bash
# Clone
git clone https://github.com/modaffar919/cipherowl.git
cd cipherowl

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run
```

### Rust Crypto Core

```bash
cd native/smartvault_core
cargo test --release    # 105 tests
cd ../..
```

---

## Testing

```bash
# All Flutter tests (193 tests)
flutter test

# Static analysis
flutter analyze

# Rust crypto tests (105 tests)
cd native/smartvault_core && cargo test --release
```

**Test coverage:** 10 test files spanning unit tests (BLoC, merge, platform), widget tests (15 screens, accessibility), and integration tests (multi-BLoC flows).

---

## CI/CD

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `ci.yml` | Push/PR to main, develop | Flutter analyze, test, Rust test, coverage |
| `cd-android.yml` | Tag `v*` | Build signed APK/AAB, upload to Google Play |
| `cd-ios.yml` | Tag `v*` | Build IPA, upload to App Store Connect |
| `security-audit.yml` | Weekly + push to main | cargo-audit, Gitleaks, CodeQL, license check |

See [.github/SECRETS.md](.github/SECRETS.md) for required repository secrets.

---

## Project Structure

```
lib/
├── main.dart, app.dart
├── core/          # Constants, theme, router, platform abstractions
├── features/      # Feature modules (auth, vault, generator, etc.)
├── shared/        # Reusable widgets, accessibility helpers
├── l10n/          # Localization (Arabic + English)
└── src/           # Generated Rust FFI bindings

native/smartvault_core/    # Rust crate (cryptography)
supabase/                  # Migrations + Edge Functions
browser_extension/         # Chrome/Firefox autofill extension
store/                     # App Store & Play Store metadata
```

---

## Security

- **Encryption:** AES-256-GCM with Argon2id key derivation (t=3, m=64MB, p=4)
- **Zero-Knowledge:** Data encrypted client-side; server never sees plaintext
- **Secure Memory:** Rust `mlock` + `zeroize` for sensitive data
- **Biometric Storage:** Face embeddings in FlutterSecureStorage (Keychain/EncryptedSharedPrefs)
- **Anti-Tampering:** Intruder snapshot after 3 failed attempts, duress password with decoy vault
- **Dependency Audit:** Weekly cargo-audit + Gitleaks + CodeQL

For security vulnerabilities, see [SECURITY.md](SECURITY.md).

---

## License

Proprietary — © 2026 CipherOwl. All rights reserved.
