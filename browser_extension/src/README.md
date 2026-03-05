# CipherOwl Browser Extension — امتداد المتصفح

A Chrome / Firefox **Manifest V3** extension that auto-fills passwords from
your CipherOwl vault.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Browser | Chrome 116+, Firefox 109+, or any Chromium-based browser |
| CipherOwl mobile app | Vault must have been synced to Supabase at least once |
| Developer mode | Enabled in browser extensions page |

---

## Installation (Developer Mode)

1. Open **chrome://extensions** (or **about:debugging** in Firefox).
2. Enable **Developer mode** (top-right toggle in Chrome).
3. Click **Load unpacked** and select this `browser_extension/src/` folder.
4. The CipherOwl owl icon appears in the toolbar.

---

## Pairing with the Mobile App

The extension decrypts credentials using the **sync key** — a 32-byte random
key stored on your device.  To pair:

1. Open CipherOwl → **Settings → ربط امتداد المتصفح** (Link Browser Extension).
2. Tap **نسخ المفتاح** (Copy Key) — you get a 64-char hex string.
3. Open the extension popup → **Sign in** with your CipherOwl account.
4. Paste the key in the **ربط الخزينة** (Link Vault) screen.
5. Done — credentials appear in the popup and auto-fill buttons appear on login forms.

---

## Features

- **Auto-fill**: An owl button appears next to password fields; click it to fill.
- **Popup search**: Full-text search across all vault entries.
- **Domain suggestions**: Matching credentials for the current website appear first.
- **Cache TTL**: Decrypted credentials are cleared from browser memory after 30 min.
- **Lock**: Click the lock icon to clear the key without logging out.

---

## Security Model

| Vector | Mitigation |
|--------|-----------|
| Extension storage | Sync key stored in `chrome.storage.local` (encrypted by the browser's profile key on disk) |
| Credential exposure | Decrypted credentials cached in `chrome.storage.local` only while unlocked; TTL alarm auto-clears in 30 min |
| Network | All traffic goes to your own Supabase project (not to any CipherOwl server) |
| XSS in autofill button | CSP + no `innerHTML` with user data; SVG icon loaded from extension origin |
| Content script isolation | Extension JS runs in an isolated JS world — cannot be accessed by page scripts |
| Supabase RLS | `browser_autofill` table enforces Row Level Security — users can only read their own rows |

> ⚠️ **Trust boundary**: Anyone who obtains your sync key can decrypt your vault.
> Treat it like a master password.

---

## Configuration

Before loading the extension, set your Supabase credentials in
`popup/popup.js`:

```js
const SUPABASE_URL  = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON = 'YOUR_ANON_KEY';
```

Find these values in your Supabase project → **Settings → API**.

---

## Apply the Supabase Migration

Before the extension can read data, apply the database migration:

```bash
# From the project root
supabase db push
# or open supabase/migrations/003_browser_autofill.sql in the Supabase SQL Editor
```

---

## Generating PNG Icons (Optional)

Chrome uses the SVG icon in the toolbar.  For the extension management page
(`chrome://extensions`) you can optionally generate PNG icons:

```bash
# Requires Node.js + sharp (npm i sharp)
node scripts/generate_extension_icons.js
```

Or use any SVG-to-PNG converter on `icons/icon.svg` to produce
`icons/icon16.png`, `icons/icon48.png`, `icons/icon128.png`.

---

## File Structure

```
browser_extension/src/
├── manifest.json          # Chrome MV3 manifest
├── popup/
│   ├── popup.html         # Extension popup UI
│   ├── popup.css          # Dark-theme styles
│   └── popup.js           # Auth + decrypt + UI logic (ES module)
├── content/
│   └── content.js         # Form detection + autofill button injection
├── background/
│   └── background.js      # Service worker (cache TTL + popup trigger)
├── icons/
│   └── icon.svg           # Owl mascot icon
└── README.md              # This file
```
