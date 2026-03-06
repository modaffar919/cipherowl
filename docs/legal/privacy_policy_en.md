# Privacy Policy — CipherOwl Password Manager

**Last Updated:** June 2025

## 1. Introduction

CipherOwl ("the App") is a zero-knowledge password manager. We are committed to protecting your privacy. This policy explains what data we collect, how we use it, and your rights.

## 2. Data We Collect

### 2.1 Data Stored Locally Only
- **Vault entries** (passwords, notes, TOTP secrets): Encrypted with AES-256-GCM on your device. We never have access to your plaintext data.
- **Master password hash**: Stored locally using Argon2id. Your master password is never transmitted.
- **Biometric data** (face embeddings): Processed on-device using MobileFaceNet. Biometric data never leaves your device.
- **Recovery key verifier**: A truncated hash stored locally for verification only.

### 2.2 Data Synchronized to Cloud (Optional)
If you enable cloud sync:
- **Encrypted vault blobs**: Already encrypted before upload; our servers cannot decrypt them.
- **Sync metadata**: Timestamps and device identifiers for conflict resolution.
- **Account email**: For authentication only.

### 2.3 Data We Never Collect
- Plaintext passwords or notes
- Biometric images or raw face data
- Browsing history
- Location data (geofence zones are stored locally only)
- Analytics or tracking data

## 3. Zero-Knowledge Architecture

All encryption and decryption happens exclusively on your device using our Rust cryptography core. The cloud server stores only encrypted blobs that are meaningless without your master password or recovery key.

## 4. Third-Party Services

- **Supabase**: Cloud database and authentication (encrypted data only)
- **Firebase Cloud Messaging**: Push notifications (device tokens only)
- **Have I Been Pwned API**: Breach monitoring uses k-anonymity (only partial SHA-1 hash prefix is sent)

## 5. Data Retention

- Local data persists until you delete it or wipe the vault.
- Cloud data is deleted when you delete your account.
- No backups of plaintext data exist anywhere.

## 6. Your Rights

You may:
- Export all your data at any time
- Delete your account and all associated cloud data
- Use the app fully offline without cloud sync
- Request information about what data we hold

## 7. Security

- AES-256-GCM encryption for all vault data
- Argon2id key derivation (600,000 iterations)
- Ed25519 digital signatures for data integrity
- X25519 key exchange for encrypted sharing
- Secure memory handling with mlock/zeroize in Rust

## 8. Children's Privacy

CipherOwl is not intended for children under 13. We do not knowingly collect data from children.

## 9. Changes to This Policy

We will notify users of material changes through in-app notifications. Continued use after notification constitutes acceptance.

## 10. Contact

For privacy inquiries, contact us through the app's Settings > Support section.
