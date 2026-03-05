# 🏪 Store Listing Assets — CipherOwl

This directory contains all App Store and Google Play listing metadata in both **Arabic (ar / ar-SA)** and **English (en-US)**.

## Directory Structure

```
store/
├── android/                        # Google Play Store metadata
│   ├── en-US/
│   │   ├── title.txt               # App title (≤ 30 chars)
│   │   ├── short_description.txt   # Tagline (≤ 80 chars)
│   │   ├── full_description.txt    # Full listing (≤ 4000 chars)
│   │   ├── keywords.txt            # Comma-separated keywords
│   │   └── changelogs/
│   │       └── 1.txt               # Release notes for version code 1
│   └── ar/
│       └── (same structure as en-US)
│
└── ios/                            # Apple App Store metadata
    ├── en-US/
    │   ├── title.txt               # App name (≤ 30 chars)
    │   ├── subtitle.txt            # Subtitle (≤ 30 chars)
    │   ├── description.txt         # Full description (≤ 4000 chars)
    │   ├── keywords.txt            # Keywords (≤ 100 chars)
    │   ├── promotional_text.txt    # Promotional text (≤ 170 chars)
    │   └── release_notes.txt       # What's New (≤ 4000 chars)
    └── ar-SA/
        └── (same structure as en-US)
```

## Screenshot Specifications

Screenshots are **not included** in this repository. Generate them from the app and place them in the following paths:

### Google Play (Android)
```
store/android/en-US/images/phoneScreenshots/
  01_unlock_screen.png           # 1080×1920 px
  02_vault_home.png
  03_vault_item_detail_totp.png
  04_password_generator.png
  05_security_center.png
  06_security_academy.png
  07_face_track_enrollment.png
  08_dark_web_check.png
store/android/en-US/images/featureGraphic.png   # 1024×500 px
store/android/en-US/images/icon.png             # 512×512 px
```
*(Duplicate for `ar/` with RTL screenshots)*

### Apple App Store (iOS)
```
store/ios/en-US/screenshots/iphone65/
  01_unlock_screen.png           # 1284×2778 px (iPhone 6.5")
  02_vault_home.png
  03_vault_item_detail_totp.png
  04_password_generator.png
  05_security_center.png
  06_security_academy.png
  07_face_track_enrollment.png
  08_dark_web_check.png
```
*(Duplicate for `ar-SA/` with Arabic/RTL screenshots)*

## Fastlane Integration (optional)

If using [Fastlane supply](https://docs.fastlane.tools/actions/supply/) for automated Google Play deployment:

```bash
# Install fastlane
gem install fastlane

# Deliver to Google Play (Android)
fastlane supply --metadata_path store/android --track internal

# Deliver to App Store (iOS)
fastlane deliver --metadata_path store/ios --submit_for_review false
```

## App Information

| Field          | Value                       |
|----------------|-----------------------------|
| App Name       | CipherOwl                   |
| Android ID     | com.cipherowl.cipherowl     |
| iOS Bundle ID  | com.cipherowl.cipherowl     |
| Version        | 1.0.0 (build 1)             |
| Min Android    | API 24 (Android 7.0)        |
| Min iOS        | iOS 14.0                    |
| Category       | Utilities / Productivity    |
| Content Rating | 4+ (Everyone)               |
| Privacy Policy | Required before submission  |
