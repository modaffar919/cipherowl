# 🔑 GitHub Repository Secrets — CipherOwl

This document lists every secret that must be configured in
**GitHub → Settings → Secrets and variables → Actions** before the CI/CD
workflows can run successfully.

---

## Android CD (`cd-android.yml`)

| Secret Name                | Description                                                  |
|----------------------------|--------------------------------------------------------------|
| `ANDROID_KEYSTORE_BASE64`  | Base64-encoded release keystore (`.jks` / `.keystore` file) |
| `ANDROID_STORE_PASSWORD`   | Keystore store password                                      |
| `ANDROID_KEY_PASSWORD`     | Key entry password                                           |
| `ANDROID_KEY_ALIAS`        | Key alias inside the keystore                                |

**How to prepare the keystore secret:**
```bash
# Generate a release keystore (one time, keep it safe!)
keytool -genkey -v -keystore cipherowl-release.jks \
  -alias cipherowl -keyalg RSA -keysize 4096 \
  -validity 10000 -storetype PKCS12

# Base64-encode it for GitHub
base64 -i cipherowl-release.jks | tr -d '\n'
# Paste the output as ANDROID_KEYSTORE_BASE64
```

---

## iOS CD (`cd-ios.yml`)

| Secret Name                           | Description                                                              |
|---------------------------------------|--------------------------------------------------------------------------|
| `IOS_CERTIFICATE_BASE64`              | Base64-encoded Apple Distribution certificate (`.p12`)                   |
| `IOS_CERTIFICATE_PASSWORD`            | Password for the `.p12` certificate                                      |
| `IOS_PROVISIONING_PROFILE_BASE64`     | Base64-encoded App Store provisioning profile (`.mobileprovision`)       |
| `KEYCHAIN_PASSWORD`                   | A random password used to create the ephemeral CI keychain               |
| `APPLE_TEAM_ID`                       | Your Apple Developer Team ID (10-char alphanumeric, e.g. `ABC1234567`)   |
| `APP_STORE_CONNECT_API_KEY_ID`        | App Store Connect API Key ID (from App Store Connect → Users & Access)   |
| `APP_STORE_CONNECT_API_ISSUER_ID`     | App Store Connect API Issuer UUID                                        |
| `APP_STORE_CONNECT_API_KEY_BASE64`    | Base64-encoded `.p8` private key file for App Store Connect API          |

**How to prepare the iOS certificate secret:**
```bash
# Export the Distribution certificate from Keychain Access as .p12
# Then base64-encode:
base64 -i Certificates.p12 | tr -d '\n'
# Paste as IOS_CERTIFICATE_BASE64

# Same for provisioning profile:
base64 -i CipherOwl_AppStore.mobileprovision | tr -d '\n'
# Paste as IOS_PROVISIONING_PROFILE_BASE64
```

---

## Security Audit (`security-audit.yml`)

No additional secrets required beyond the default `GITHUB_TOKEN` (automatically
provided by GitHub Actions).

---

## CI (`ci.yml`)

| Secret Name      | Description                                                         |
|------------------|---------------------------------------------------------------------|
| `CODECOV_TOKEN`  | *(Optional)* Token for Codecov coverage upload — only needed if your repo is private |

---

## Quick Checklist

```
Android Release
  [ ] ANDROID_KEYSTORE_BASE64
  [ ] ANDROID_STORE_PASSWORD
  [ ] ANDROID_KEY_PASSWORD
  [ ] ANDROID_KEY_ALIAS

iOS Release
  [ ] IOS_CERTIFICATE_BASE64
  [ ] IOS_CERTIFICATE_PASSWORD
  [ ] IOS_PROVISIONING_PROFILE_BASE64
  [ ] KEYCHAIN_PASSWORD
  [ ] APPLE_TEAM_ID
  [ ] APP_STORE_CONNECT_API_KEY_ID
  [ ] APP_STORE_CONNECT_API_ISSUER_ID
  [ ] APP_STORE_CONNECT_API_KEY_BASE64
```

> ⚠️ **Never commit secrets to source control.** All sensitive values must be
> stored in GitHub Actions Secrets, not in files checked into the repository.
