# Privacy Policy — CipherOwl

**Last updated:** March 2026

CipherOwl ("the App") is a password manager developed by CipherOwl. This Privacy Policy describes how we collect, use, and protect your information.

---

## 1. Zero-Knowledge Architecture

CipherOwl uses a **zero-knowledge** design. All sensitive data — passwords, notes, TOTP secrets, and biometric embeddings — is encrypted on your device using AES-256-GCM before it ever leaves the device. We **cannot** read, access, or recover your encrypted vault data.

**Your master password never leaves your device.** It is used locally to derive an encryption key via Argon2id key derivation and is never transmitted to our servers.

---

## 2. Data We Collect

### Data Stored Locally (On Your Device)
- Vault entries (encrypted with AES-256-GCM)
- Master password hash (Argon2id, never transmitted)
- Face biometric embeddings (encrypted, never transmitted)
- TOTP secrets (encrypted)
- App settings and preferences

### Data Synced to Cloud (Encrypted)
If you enable cloud sync via Supabase:
- **Encrypted vault blobs** — indecipherable without your master password
- Account email address (for authentication only)
- Sync timestamps

### Data We Do NOT Collect
- Plaintext passwords or vault contents
- Biometric data (face, fingerprint)
- Browsing history or keystrokes
- Location data (geofencing is processed locally)
- Analytics or usage tracking
- Advertising identifiers

---

## 3. Face-Track Biometric Data

CipherOwl's Face-Track feature processes facial data **entirely on your device**:
- Face detection uses Google ML Kit (on-device)
- Face embeddings are generated using MobileFaceNet TFLite (on-device)
- Embeddings are stored in the device's secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- **No biometric data is ever transmitted to any server**

---

## 4. Third-Party Services

| Service | Purpose | Data Shared |
|---------|---------|-------------|
| Supabase | Cloud sync & authentication | Encrypted vault blobs, email |
| Firebase Cloud Messaging | Push notifications | Device token (no vault data) |
| HaveIBeenPwned API | Dark web breach checking | First 5 characters of password SHA-1 hash (k-anonymity) |

No third-party analytics, advertising, or tracking SDKs are included in the App.

---

## 5. Data Security

- **Encryption:** AES-256-GCM with Argon2id key derivation (t=3, m=64MB, p=4)
- **Secure Memory:** Sensitive data in Rust is protected with `mlock` and cleared with `zeroize`
- **Transport Security:** All network communication uses TLS 1.2+
- **Local Storage:** SQLCipher database with AES-256 encryption
- **Biometric Storage:** iOS Keychain / Android EncryptedSharedPreferences

---

## 6. Data Retention

- Your vault data remains on your device and/or in your encrypted cloud sync until you delete it.
- Deleting the App removes all local data.
- To delete cloud-synced data, use the App's account deletion feature or contact us.

---

## 7. Children's Privacy

CipherOwl is not directed at children under 13. We do not knowingly collect personal information from children.

---

## 8. Your Rights

You have the right to:
- Access your data (it's on your device)
- Delete your account and all associated data
- Export your vault data (Settings → Import/Export)
- Revoke cloud sync at any time

---

## 9. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be posted within the App and on our repository.

---

## 10. Contact

For privacy-related questions, please open an issue on the project repository or contact the development team.

---

**سياسة الخصوصية باختصار (عربي):**
CipherOwl يستخدم تشفير عسكري (AES-256-GCM) مع بنية المعرفة الصفرية — جميع بياناتك مشفرة على جهازك قبل أي مزامنة سحابية. لا نستطيع قراءة كلمات مرورك أو بياناتك البيومترية. معالجة الوجه تتم محلياً 100% على جهازك.
