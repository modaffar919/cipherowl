# ADR-001: Rust for All Cryptographic Operations

**Status**: Accepted
**Date**: 2025
**Deciders**: CipherOwl Team

## Context

CipherOwl needs military-grade cryptography for password vault encryption, key derivation, secure sharing, TOTP generation, and biometric embedding protection. The application targets Flutter (Dart) across mobile, desktop, and web platforms.

## Decision

All cryptographic operations are implemented in Rust, accessed via flutter_rust_bridge (FFI). No crypto is implemented in Dart.

## Rationale

- **Memory safety**: Rust's ownership model prevents use-after-free and buffer overflows in security-critical code
- **Secure memory**: `zeroize` crate guarantees key material is zeroed on drop; `mlock`/`VirtualLock` pins memory to RAM
- **Auditable**: Single crate (`smartvault_core`) contains all crypto — one audit surface
- **Performance**: Native code for Argon2id key derivation (memory-hard) outperforms Dart by 10–50x
- **Cross-platform**: Same Rust code compiles for Android (NDK), iOS, Windows, macOS, Linux

## Consequences

- **Positive**: Consistent crypto behavior across all platforms; fuzz-testable (cargo-fuzz); passes MASVS-CRYPTO requirements
- **Negative**: Increased build complexity (cargo-ndk, cross-compilation); flutter_rust_bridge version coupling
- **Mitigated**: CI/CD workflows automate cross-compilation; bridge version pinned in Cargo.toml

---

# ADR-002: BLoC for State Management

**Status**: Accepted
**Date**: 2025

## Context

CipherOwl has complex state: vault items, sync status, biometric session, security scores, TOTP timers. Need predictable, testable state management.

## Decision

Flutter BLoC (flutter_bloc) with strict separation: Events → BLoC → States. No state logic in widgets.

## Rationale

- **Predictability**: Unidirectional data flow, every state transition is an event
- **Testability**: bloc_test provides `expect` on state sequences without widget rendering
- **Separation**: Widgets are pure UI; business logic lives in BLoCs; data in repositories
- **Team scaling**: Clear contracts between BLoC events/states enable parallel development

## Consequences

- More boilerplate than Riverpod/Provider
- Enforced by analysis_options.yaml and code review

---

# ADR-003: SQLCipher for Local Database Encryption

**Status**: Accepted
**Date**: 2025

## Context

Vault entries must be encrypted at rest on-device. Options: raw file encryption, SQLCipher, Hive encrypted, custom.

## Decision

Drift ORM + SQLCipher (via sqlcipher_flutter_libs) with a random AES-256 key stored in platform secure storage.

## Rationale

- **Proven**: SQLCipher is the industry standard for encrypted SQLite (used by Signal, 1Password)
- **Transparent**: Encryption handled at database level — no per-field encrypt/decrypt in application code
- **Query support**: Full SQL capabilities with Drift's type-safe query builder
- **Key management**: Database key derived independently and stored in FlutterSecureStorage (Keychain/Keystore)

## Consequences

- Database file is opaque (cannot be read by standard SQLite tools)
- Key rotation requires full re-encryption (planned but not yet implemented)
- sqlcipher_flutter_libs adds ~2MB to APK size

---

# ADR-004: Zero-Knowledge Cloud Sync via Supabase

**Status**: Accepted
**Date**: 2025

## Context

Users want multi-device sync. We must ensure the cloud provider cannot access user data.

## Decision

All vault data encrypted client-side (AES-256-GCM, Rust) before upload. Supabase stores only ciphertext. Server has Row Level Security (RLS) but no decryption capability.

## Rationale

- **Privacy**: Server compromise exposes only ciphertext — useless without per-user keys
- **Compliance**: GDPR privacy-by-design (Art. 25); no data processing on server
- **Trust model**: Users don't need to trust our infrastructure
- **Conflict resolution**: Three-way merge handles concurrent edits with encrypted payloads

## Consequences

- Cannot perform server-side search on vault contents
- Sync conflicts require client-side merge logic
- Account recovery requires the BIP-39 mnemonic — no server-side reset

---

# ADR-005: Continuous Biometric Authentication (Face-Track)

**Status**: Accepted
**Date**: 2025

## Context

Traditional password managers unlock once and stay unlocked. This creates a window for unauthorized access if the user walks away.

## Decision

Implement continuous face verification using MobileFaceNet (TFLite, on-device). The app periodically checks that the enrolled face is still present and locks if not.

## Rationale

- **Security**: Reduces the "unlocked and unattended" attack window
- **Usability**: No repeated manual authentication needed
- **Privacy**: Face embeddings stored encrypted (AES-256-GCM), never leave device
- **Anti-spoofing**: Multi-signal liveness detection (blink, motion, texture analysis)

## Consequences

- Requires camera permission and front-facing camera
- Battery impact mitigated by configurable check interval
- Users can disable Face-Track and use traditional lock methods
- Face embedding migration handled automatically (legacy → encrypted)

---

# ADR-006: CustomPaint over Rive/Lottie for Owl Mascot

**Status**: Accepted
**Date**: 2026-03

## Context

EPIC-9 originally specified using Rive for the animated owl mascot (6 states: idle, watching, verifying, success, failed, danger) and Lottie for page transition animations. Both `rive: ^0.14.4` and `lottie: ^3.1.2` were added to `pubspec.yaml`.

## Decision

Implement the owl mascot using Flutter CustomPaint instead of Rive. Use Lottie for supplementary transition animations (success checkmark, loading spinner) only.

## Rationale

- **Zero external assets**: CustomPaint requires no `.riv` or `.json` files — no asset loading failures, no missing file crashes
- **Smaller APK**: No bundled binary animation assets (Rive files can be 50–200KB each)
- **Full control**: Animation states integrate directly with BLoC state machine — no Rive state machine mapping layer needed
- **Performance**: CustomPaint renders at native Flutter frame rate; no Rive runtime overhead
- **Already production-ready**: OwlMascotWidget implements all 6 states with breathing animation, glow effects, and color transitions

## Consequences

- **Positive**: Simpler build pipeline; no designer tool dependency; 100% code-controlled animation behavior
- **Negative**: More complex Dart code in `owl_mascot.dart` compared to importing a `.riv` asset
- **Lottie retained**: Small Lottie JSON files used for success/loading micro-animations to complement CustomPaint mascot

---

# ADR-007: OIDC-First Enterprise SSO Strategy

**Status**: Accepted
**Date**: 2026-03

## Context

EPIC-12 requires enterprise SSO integration supporting OIDC, SAML, and LDAP. The SSO config storage layer (sso_config_service.dart, 006_sso_config.sql) supports all three providers. However, implementing all three authentication flows simultaneously is high-effort and low-value for a graduation project.

## Decision

Implement OIDC authorization code flow first. Defer SAML and LDAP to post-launch roadmap. Store configurations for all three providers (existing infrastructure) but only execute OIDC authentication.

## Rationale

- **Coverage**: OIDC covers Google Workspace, Microsoft Azure AD, Okta, Auth0 — 90%+ of enterprise IdPs
- **Supabase compatibility**: Supabase Auth natively supports OIDC providers; SAML/LDAP would require custom auth hooks
- **Complexity**: SAML assertion parsing and LDAP bind/search require specialized libraries and testing infrastructure
- **Incremental**: OIDC implementation establishes the SSO auth pattern; SAML/LDAP can follow the same event/state architecture

## Consequences

- Admin dashboard can configure all three provider types (UI ready)
- Only OIDC "Connect" button is active; SAML/LDAP show "Coming Soon"
- LDAP sync and SAML assertion verification documented as future work
