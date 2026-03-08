# Chrome Web Store Listing — CipherOwl Autofill

## Extension Details

**Name**: CipherOwl Autofill
**Short Description** (132 chars max):
> Fill passwords automatically from your CipherOwl vault — ملء كلمات المرور تلقائياً من خزينة CipherOwl

**Category**: Productivity
**Language**: Arabic (Primary), English

## Detailed Description

### English

CipherOwl Autofill seamlessly fills your passwords, usernames, and TOTP codes directly from your encrypted CipherOwl vault.

**Features:**
- 🔐 **Zero-Knowledge Autofill** — Credentials are decrypted on-device, never on our servers
- ⚡ **One-Click Fill** — Click the CipherOwl icon or use Ctrl+Shift+L to fill login forms instantly
- 🔑 **Password Generator** — Generate strong passwords without leaving the page
- 📱 **Cross-Platform Sync** — Access your vault from any device
- 🛡️ **Military-Grade Encryption** — AES-256-GCM encryption powered by Rust
- 🌐 **Arabic & English** — Full bilingual support

**Security:**
- All encryption happens locally in your browser
- No plaintext data is ever transmitted
- Built with the same Rust crypto core as the CipherOwl mobile app
- Open architecture — auditable security model

**How It Works:**
1. Install the extension
2. Log in with your CipherOwl account
3. Navigate to any login page
4. Click the CipherOwl icon to autofill

### Arabic

إضافة CipherOwl للملء التلقائي تقوم بملء كلمات المرور وأسماء المستخدمين ورموز TOTP مباشرة من خزينتك المشفرة.

**المميزات:**
- 🔐 ملء تلقائي بدون معرفة مسبقة — يتم فك التشفير على جهازك فقط
- ⚡ ملء بنقرة واحدة — Ctrl+Shift+L لملء نماذج تسجيل الدخول فوراً
- 🔑 مولد كلمات مرور — أنشئ كلمات مرور قوية دون مغادرة الصفحة
- 📱 مزامنة عبر الأجهزة — الوصول من أي جهاز
- 🛡️ تشفير عسكري — AES-256-GCM مدعوم بـ Rust
- 🌐 عربي وإنجليزي — دعم ثنائي اللغة كامل

## Store Assets Required

| Asset | Size | File |
|-------|------|------|
| Small tile | 440×280 px | `store/screenshots/ext_tile.png` |
| Screenshot 1 | 1280×800 px | `store/screenshots/ext_01_popup.png` |
| Screenshot 2 | 1280×800 px | `store/screenshots/ext_02_autofill.png` |
| Screenshot 3 | 1280×800 px | `store/screenshots/ext_03_generator.png` |
| Icon | 128×128 px | `browser_extension/src/icons/icon-128.png` |

## Privacy Practices

- **Single Purpose**: Autofill passwords from CipherOwl vault
- **Data Usage**: No data collected; all processing is local
- **Permissions Justification**:
  - `storage`: Store encrypted session data locally
  - `activeTab`: Inject autofill into current page only
  - `scripting`: Detect and fill login forms
  - `alarms`: Session timeout for security
  - `host_permissions (<all_urls>)`: Autofill works on any website

## Review Notes

- Extension communicates only with the user's Supabase project (no third-party servers)
- All stored data is encrypted with AES-256-GCM before writing to browser storage
- Content script only activates when login forms are detected
- No analytics or tracking
