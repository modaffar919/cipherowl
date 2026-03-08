# Security Policy — CipherOwl

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in CipherOwl, **please do not open a public issue**.

Instead:
1. Email the development team directly or use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability).
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We aim to acknowledge reports within **48 hours** and provide a fix within **7 days** for critical issues.

## Security Architecture

### Cryptographic Primitives (Rust)
- **AES-256-GCM** — Vault encryption (NIST SP 800-38D compliant)
- **Argon2id** — Key derivation (t=3, m=64MB, p=4, OWASP recommended)
- **X25519 ECDH** — Key exchange for encrypted sharing
- **Ed25519** — Digital signatures for data integrity
- **PBKDF2-SHA512** — Fallback KDF (600K iterations)
- **Secure Memory** — `mlock` to prevent swapping + `zeroize` on drop

### Data Protection
- SQLCipher — Database encrypted at rest with AES-256
- FlutterSecureStorage — Biometrics in iOS Keychain / Android EncryptedSharedPrefs
- Zero-knowledge sync — Data encrypted before cloud upload
- Certificate pinning — Supabase connections

### Anti-Tampering
- Intruder snapshot after 3 failed authentication attempts
- Duress password with decoy empty vault
- Face-Track continuous biometric verification (300ms interval)
- Liveness detection (blink + head motion analysis)

### Automated Security Checks
- `cargo audit` — Weekly Rust dependency audit
- Gitleaks — Secret scanning on every push
- CodeQL — Static analysis for JavaScript (browser extension)
- License compliance — Blocks GPL/AGPL dependencies

## Dependency Policy

- All cryptographic operations are implemented in Rust — no Dart crypto
- Dependencies are audited weekly via GitHub Actions
- GPL/AGPL-licensed dependencies are prohibited
- Outdated dependencies are flagged (non-blocking)
