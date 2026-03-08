# CipherOwl Security Whitepaper

**Version**: 1.0
**Date**: 2025
**Classification**: Public

## 1. Executive Summary

CipherOwl is a zero-knowledge password manager that employs military-grade cryptography with continuous biometric verification. All sensitive data is encrypted client-side before any network transmission, ensuring that neither CipherOwl servers nor any intermediary can access user plaintext data.

## 2. Threat Model

### 2.1 Assets Protected
- Master passwords and vault credentials
- TOTP secrets and generated codes
- Face biometric embeddings
- Recovery keys (BIP-39 mnemonics)
- User metadata and preferences

### 2.2 Threat Actors
- **External attackers**: Network eavesdroppers, cloud infrastructure compromises
- **Insider threats**: Compromised server administrators
- **Physical access**: Device theft, shoulder surfing
- **Biometric spoofing**: Photo/video replay attacks

### 2.3 Trust Boundaries
- Client device (trusted execution environment)
- Network transport (TLS 1.3, untrusted)
- Cloud storage (Supabase, untrusted for plaintext)

## 3. Cryptographic Architecture

### 3.1 Core Algorithms (Rust Implementation)

All cryptographic operations execute in native Rust code via FFI — never in Dart/JavaScript.

| Algorithm | Purpose | Parameters |
|-----------|---------|------------|
| AES-256-GCM | Vault encryption | 256-bit key, 96-bit nonce, authenticated |
| Argon2id | Key derivation | 64 MB memory, 3 iterations, 4 parallelism |
| X25519 | Key exchange (sharing) | Curve25519 ECDH |
| Ed25519 | Digital signatures | Edwards curve |
| PBKDF2-HMAC-SHA256 | Web key derivation | 100,000 iterations |
| BIP-39 | Recovery key generation | 256-bit entropy, 24 words |

### 3.2 Key Hierarchy

```
Master Password
    │
    ├── Argon2id ──► Vault Encryption Key (AES-256)
    │                    │
    │                    ├── Encrypts vault entries
    │                    ├── Encrypts face embeddings
    │                    └── Encrypts TOTP secrets
    │
    ├── PBKDF2 ──► Authentication Key (for Supabase auth)
    │
    └── BIP-39 ──► Recovery Mnemonic (24 words)
                       │
                       └── Re-derives Vault Key on recovery
```

### 3.3 Zero-Knowledge Sync Protocol

1. Client derives vault key from master password (Argon2id)
2. Each entry encrypted with AES-256-GCM using derived key
3. Encrypted blobs uploaded to Supabase with nonce and metadata
4. Server stores only ciphertext — never receives plaintext or key
5. Three-way merge for conflict resolution (client A ↔ server ↔ client B)

### 3.4 Secure Memory Management

- Rust `zeroize` crate: All sensitive data zeroed on drop
- `mlock` (Unix) / `VirtualLock` (Windows): Pin key material to RAM, prevent swap
- No plaintext keys in Dart heap after FFI call returns

## 4. Biometric Security

### 4.1 Face-Track Continuous Authentication
- **Model**: MobileFaceNet TFLite (quantized, on-device)
- **Enrollment**: 512-dimensional embedding extracted, encrypted with AES-256-GCM
- **Verification**: Cosine similarity threshold (0.7) against encrypted stored embedding
- **Continuous**: Periodic re-verification while app is foregrounded

### 4.2 Anti-Spoofing Measures
- **Blink detection**: Eye aspect ratio analysis across frames
- **Motion analysis**: Head movement variance requirement
- **Texture analysis**: Laplacian variance (focus detection) + Sobel edge density
- **Passive liveness**: Combined score — 60% of frames must pass all three checks

### 4.3 Embedding Protection
- Face embeddings encrypted at rest using VaultCryptoService (AES-256-GCM)
- Legacy plaintext embeddings migrated automatically on first load
- Embeddings never transmitted to any server

## 5. Device Integrity

### 5.1 Root/Jailbreak Detection
- Multi-signal detection: known binaries, system paths, properties
- Blocks vault access on compromised devices

### 5.2 Debugger Detection (MASVS-RESILIENCE-2)
- **Android**: `/proc/self/status` TracerPid monitoring
- **iOS**: DYLD_INSERT_LIBRARIES and environment variable inspection
- Disabled in debug/profile mode to allow development

### 5.3 Certificate Pinning
- TLS certificate pinning for Supabase API endpoints
- Prevents MITM attacks even with compromised CA

## 6. Data Protection

### 6.1 At Rest
- **Mobile**: SQLCipher (AES-256-CBC) for structured data
- **Secure Storage**: Platform keychain/keystore for keys
- **Web**: Web Crypto API (AES-256-GCM) + IndexedDB

### 6.2 In Transit
- TLS 1.3 for all Supabase communication
- Additional application-layer encryption (zero-knowledge)

### 6.3 Data Deletion (GDPR Art. 17)
- Full cascade deletion across 15 database tables
- Storage bucket cleanup (attachments)
- Audit log for compliance verification
- Local secure storage wipe on client

## 7. TOTP 2FA Implementation

- TOTP secrets encrypted in vault with AES-256-GCM
- Code generation in Rust (HMAC-SHA1, RFC 6238 compliant)
- Time-step: 30 seconds, 6 digits default
- QR code scanning for easy enrollment

## 8. Compliance References

| Standard | Coverage |
|----------|----------|
| OWASP MASVS | STORAGE, CRYPTO, AUTH, NETWORK, RESILIENCE |
| OWASP ASVS 4.0 | V2 (Auth), V3 (Session), V6 (Crypto) |
| GDPR | Art. 17 (erasure), Art. 25 (privacy by design) |
| NIST SP 800-63B | Memorized secrets, biometric authentication |
| SOC 2 Type II | Trust principles: Security, Confidentiality |

## 9. Incident Response

- Security events logged via AppMonitor
- Failed authentication attempts tracked
- Anomalous access patterns trigger auto-lock
- Geo-fencing auto-lock for location-based protection

## 10. Limitations & Known Constraints

- Face-Track requires front camera access
- Biometric data quality depends on device hardware
- Offline mode limits sync to reconnection
- Web platform crypto limited to WebCrypto API subset
