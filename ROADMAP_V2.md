# 🦉 CipherOwl — خارطة الطريق الشاملة v2.0

> **تاريخ الإنشاء:** 2026-03-06
> **النوع:** مشروع تخرج بتمويل شركات → تطبيق عالمي إنتاجي
> **الهدف:** معدل خطأ 0% · تغطية اختبارات 95%+ · تدقيق أمني خارجي
> **المنصات:** Android · iOS · Web (PWA) · Windows · macOS · Linux · Browser Extension
> **إجمالي المهام:** 38 مهمة في 6 مراحل

---

## 📊 ملخص المراحل

| المرحلة | الوصف | المهام | الأولوية | الحالة |
|:-------:|-------|:------:|:--------:|:------:|
| **0** | تصحيح الأخطاء الحرجة | 6 | 🔴 P0 | 🔵 لم تبدأ |
| **1** | إكمال الميزات الناقصة | 8 | 🟠 P1 | 🔵 لم تبدأ |
| **2** | الميزات الجديدة | 8 | 🟠 P1 | 🔵 لم تبدأ |
| **3** | توسيع المنصات | 4 | 🟠 P1-P3 | 🔵 لم تبدأ |
| **4** | الاختبارات وضمان الجودة | 7 | 🔴 P0 | 🔵 لم تبدأ |
| **5** | البنية التحتية للإنتاج | 5 | 🔴 P0-P2 | 🔵 لم تبدأ |

---

## 🔴 المرحلة 0 — تصحيح الأخطاء الحرجة (Foundation Fixes)

> **الهدف:** إصلاح كل ما هو مؤشر ✅ لكنه غير منفذ فعلياً.
> **بعد هذه المرحلة:** كل ✅ في المشروع يعكس الواقع الفعلي.

### المهام

| # | المهمة | الأولوية | التبعية | الحالة |
|:-:|--------|:--------:|:-------:|:------:|
| 0.1 | **zxcvbn Password Strength في Rust** — تنفيذ حقيقي بدل الـ stub | 🔴 P0 | — | 🔵 لم تبدأ |
| 0.2 | **BIP39 Recovery Key في Rust** — تنفيذ generate/validate/seed | 🔴 P0 | — | 🔵 لم تبدأ |
| 0.3 | **وصل Face Enrollment بالكاميرا الحقيقية** — استبدال fake delay | 🔴 P0 | — | 🔵 لم تبدأ |
| 0.4 | **تفعيل Face Auth عند فتح التطبيق** — مطابقة embeddings | 🔴 P0 | 0.3 | 🔵 لم تبدأ |
| 0.5 | **إصلاح 91 تحذير Lint** — deprecated APIs | 🔴 P0 | — | 🔵 لم تبدأ |
| 0.6 | **تنظيف TODO comments المنتهية** — توحيد التعليقات | 🔴 P0 | — | 🔵 لم تبدأ |

### التفاصيل التقنية

#### 0.1 — zxcvbn Password Strength في Rust
```
المشكلة: src/password/generator.rs يحتوي stub فارغ مع TODO comment
الحل:
  1. إضافة `zxcvbn` crate إلى Cargo.toml
  2. تنفيذ estimate_strength(password) → StrengthResult { score: 0-4, feedback, crack_time }
  3. تحديث api.rs بـ #[frb] api_estimate_strength()
  4. إعادة توليد FFI bindings
  5. ربط GeneratorScreen و AddEditItemScreen بـ score الحقيقي
الملفات:
  - native/smartvault_core/Cargo.toml
  - native/smartvault_core/src/password/generator.rs
  - native/smartvault_core/src/api.rs
  - lib/features/generator/
  - lib/features/vault/presentation/screens/add_edit_item_screen.dart
```

#### 0.2 — BIP39 Recovery Key في Rust
```
المشكلة: لا يوجد أي كود BIP39 في Rust crate رغم أن المهمة مؤشرة ✅
الحل:
  1. إنشاء native/smartvault_core/src/crypto/bip39.rs
  2. إضافة bip39 crate dependency
  3. تنفيذ generate_mnemonic(word_count: 12|24) → Vec<String>
  4. تنفيذ validate_mnemonic(words) → bool
  5. تنفيذ mnemonic_to_seed(words, passphrase) → [u8; 64]
  6. تحديث api.rs بدوال جديدة + FFI
  7. ربط SetupScreen (Page 2) بالتوليد الحقيقي
الملفات:
  - native/smartvault_core/src/crypto/bip39.rs (جديد)
  - native/smartvault_core/src/crypto/mod.rs
  - native/smartvault_core/Cargo.toml
  - native/smartvault_core/src/api.rs
  - lib/features/auth/presentation/screens/setup_screen.dart
```

#### 0.3 — وصل Face Enrollment بالكاميرا الحقيقية
```
المشكلة: FaceSetupScreen يحاكي التقاط الوجه بـ fake delay 1s
الحل:
  1. استبدال المحاكاة بفتح الكاميرا الحقيقية (camera package)
  2. استخدام FaceDetectorService لاكتشاف الوجه
  3. استخدام FaceEmbeddingService لاستخراج 128-dim embedding
  4. التقاط 5 أوضاع (أمام، يسار، يمين، أعلى، أسفل) مع isFaceInPose()
  5. حساب متوسط الـ 5 embeddings
  6. تشفير بـ AES-256-GCM وحفظ في flutter_secure_storage
الملفات:
  - lib/features/face_track/presentation/screens/face_setup_screen.dart
  - lib/core/services/face_detector_service.dart
  - lib/core/services/face_embedding_service.dart
```

#### 0.4 — تفعيل Face Auth عند فتح التطبيق
```
المشكلة: لا مطابقة embeddings عند فتح التطبيق
الحل:
  1. إضافة زر Face Unlock في LockScreen
  2. عند الضغط: كاميرا → اكتشاف → embedding → مقارنة بالمحفوظ
  3. استخدام is_same_person() من Rust (threshold: 0.75)
  4. تطابق → فتح | فشل 3 مرات → intruder snapshot
الملفات:
  - lib/features/auth/presentation/screens/lock_screen.dart
  - lib/features/auth/presentation/bloc/auth_bloc.dart
```

#### 0.5 — إصلاح 91 تحذير Lint
```
المشكلة: 91 تحذير deprecated APIs في Flutter 3.31+
الحل:
  - withOpacity(x) → withValues(alpha: x)
  - MaterialStateProperty → WidgetStateProperty
  - deprecated background → surface
  - activeColor → activeThumbColor
الملفات: ~20 ملف في lib/
```

#### 0.6 — تنظيف TODO comments
```
المشكلة: تعليقات TODO قديمة لم تعد تعكس الواقع
الحل:
  - حذف/تحديث التعليقات المنتهية
  - توحيد الصيغة: // TODO: أو // FIXME:
```

---

## 🟠 المرحلة 1 — إكمال الميزات الناقصة (Complete Existing Features)

> **الهدف:** كل ميزة مخطط لها تعمل بالكامل end-to-end بلا استثناء.

### المهام

| # | المهمة | الأولوية | التبعية | الحالة |
|:-:|--------|:--------:|:-------:|:------:|
| 1.1 | **المشاركة المشفرة** — Edge Function + X25519 + رابط مؤقت | 🟠 P1 | — | 🔵 لم تبدأ |
| 1.2 | **FIDO2/WebAuthn Flow** — registration + authentication ceremonies | 🟠 P1 | — | 🔵 لم تبدأ |
| 1.3 | **Anti-Spoofing / Liveness** — blink + head motion + texture | 🟠 P1 | 0.3, 0.4 | 🔵 لم تبدأ |
| 1.4 | **مركز إشعارات FCM حقيقي** — foreground/background + تصنيف | 🟠 P1 | — | 🔵 لم تبدأ |
| 1.5 | **Duress Vault بمحتوى** — 5-10 حسابات وهمية مقنعة | 🟠 P1 | — | 🔵 لم تبدأ |
| 1.6 | **Recovery Key Flow كامل** — شاشة 12/24 كلمة → MEK → فتح | 🟠 P1 | 0.2 | 🔵 لم تبدأ |
| 1.7 | **Browser Extension كامل** — Manifest v3 + content + popup + sync | 🟠 P1 | — | 🔵 لم تبدأ |
| 1.8 | **Geo-Fencing حقيقي** — geolocator + مناطق آمنة + قفل تلقائي | 🔵 P2 | — | 🔵 لم تبدأ |

### التفاصيل التقنية

#### 1.1 — المشاركة المشفرة (Encrypted Sharing)
```
المشكلة: SharingScreen يعرض بيانات تجريبية ثابتة (_sharedItems)
الحل:
  1. إنشاء Supabase Edge Function share-item/ (X25519 ECDH + AES-256-GCM)
  2. ربط SharingScreen بـ VaultBloc لاختيار عنصر حقيقي
  3. توليد رابط مشفر → TinyURL → انتهاء صلاحية
  4. دعم: One-time use, PIN protection, Expiry timer
  5. استبدال _sharedItems ببيانات حقيقية
الملفات:
  - supabase/functions/share-item/ (جديد)
  - lib/features/sharing/
```

#### 1.2 — FIDO2/WebAuthn Authentication Flow
```
المشكلة: Fido2CredentialService يخزن credentials لكن لا authentication flow
الحل:
  1. registration ceremony (تسجيل مفتاح أمان)
  2. authentication ceremony (المصادقة)
  3. ربط بشاشة Lock
  4. دعم Yubikey, Google Titan, platform passkeys
الملفات:
  - lib/features/auth/
  - lib/core/services/fido2_credential_service.dart
```

#### 1.3 — Anti-Spoofing / Liveness Detection
```
المشكلة: لا كشف حيوية — يمكن خداعه بصورة
الحل:
  1. Blink detection (عدد الرمشات خلال فترة)
  2. Head motion challenge (حرك رأسك يميناً/يساراً)
  3. Texture analysis للتمييز بين صورة ووجه حقيقي
الملفات:
  - lib/core/services/face_detector_service.dart
  - lib/features/face_track/
```

#### 1.4 — مركز إشعارات FCM حقيقي
```
المشكلة: مركز الإشعارات يستخدم SharedPreferences فقط
الحل:
  1. استبدال SharedPreferences ببيانات FCM حقيقية
  2. ربط Edge Function send-notification/ بالأحداث
  3. foreground + background notification handling
  4. تصنيف: اختراق، تسجيل دخول، تذكير، نصيحة أمنية
الملفات:
  - lib/features/notifications/
  - lib/core/services/fcm_service.dart
```

#### 1.5 — Duress Vault بمحتوى واختبار
```
المشكلة: منطق duress موجود لكن الخزنة المزيفة فارغة
الحل:
  1. إنشاء 5-10 حسابات وهمية مقنعة عند التفعيل
  2. اختبار التدفق: كلمة مرور إكراه → خزنة مزيفة → لا أثر
  3. إشعار صامت لجهة الطوارئ (بعد Emergency Access)
الملفات:
  - lib/features/auth/
```

#### 1.6 — Recovery Key Flow الكامل
```
المشكلة: مسار Recovery موجود في Router لكن غير مكتمل
الحل:
  1. شاشة استعادة: إدخال 12/24 كلمة
  2. التحقق ضد BIP39 wordlist (Rust)
  3. اشتقاق MEK من seed phrase
  4. فتح القفل بنجاح
الملفات:
  - lib/features/auth/presentation/screens/recovery_screen.dart
```

#### 1.7 — Browser Extension كامل
```
المشكلة: manifest.json + 3 مجلدات فارغة — لا كود حقيقي
الحل:
  1. Manifest v3 Chrome/Edge/Firefox متوافق
  2. Background service worker: Supabase اتصال + sync
  3. Content script: اكتشاف حقول تسجيل الدخول + ملء تلقائي
  4. Popup UI: قائمة حسابات + بحث + توليد كلمة مرور
  5. Communication مع التطبيق عبر shared encryption key
الملفات:
  - browser_extension/src/
```

#### 1.8 — Geo-Fencing الحقيقي
```
المشكلة: GeofenceBloc موجود لكن UI = placeholder فارغ
الحل:
  1. ربط geolocator package
  2. تعريف مناطق آمنة (بيت، مكتب) بنصف قطر
  3. قفل تلقائي عند الخروج من المنطقة الآمنة
الملفات:
  - lib/features/geofence/
```

---

## ✨ المرحلة 2 — الميزات الجديدة (New Features)

> **الهدف:** 8 ميزات تجعل CipherOwl استثنائياً ومنافساً عالمياً.

### المهام

| # | المهمة | الأولوية | التبعية | الحالة |
|:-:|--------|:--------:|:-------:|:------:|
| 2.1 | **Password Health Dashboard** — pie chart + reuse + old + breached | 🟠 P1 | 0.1 | 🔵 لم تبدأ |
| 2.2 | **Emergency Access** — trusted contact + delayed access + X25519 | 🟠 P1 | — | 🔵 لم تبدأ |
| 2.3 | **Vault Item Versioning** — history table + rollback + auto-cleanup | 🟠 P1 | — | 🔵 لم تبدأ |
| 2.4 | **Secure Notes + مرفقات مشفرة** — PDF/صور + AES-256-GCM + Storage | 🟠 P1 | — | 🔵 لم تبدأ |
| 2.5 | **Passwordless Login (Magic Link)** — Supabase Auth + Master Password | 🔵 P2 | — | 🔵 لم تبدأ |
| 2.6 | **Multi-device Sync: 3-Way Merge** — base version + field-level merge | 🟠 P1 | — | 🔵 لم تبدأ |
| 2.7 | **Offline Mode + Queue** — pending_operations + retry + مؤشر بصري | 🟠 P1 | 2.6 | 🔵 لم تبدأ |
| 2.8 | **Accessibility WCAG 2.1 AA** — Semantics + contrast + TalkBack/VoiceOver | 🟠 P1 | — | 🔵 لم تبدأ |

### التفاصيل التقنية

#### 2.1 — Password Health Dashboard المتقدم
```
الوصف: لوحة بصرية شاملة لصحة كلمات المرور
المكونات:
  - Pie chart: ضعيفة / متوسطة / قوية (يعتمد على zxcvbn)
  - Reuse detection: كلمات مرور مكررة
  - Age tracking: كلمات مرور قديمة >90 يوم
  - Breach check: HaveIBeenPwned (API موجود)
  - Health score: 0-100 إجمالي
  - توصيات مخصصة مع أولوية
  - XP rewards عند إصلاح مشاكل
الملفات:
  - lib/features/security_center/ (توسيع)
  - lib/features/security_center/presentation/screens/password_health_screen.dart (جديد)
```

#### 2.2 — Emergency Access (وصول الطوارئ)
```
الوصف: السماح لشخص موثوق بالوصول للخزنة في حالات الطوارئ
المكونات:
  1. تسجيل trusted contact بـ email/phone
  2. نظام وصول مؤجل: طلب → مهلة X أيام → إذا لم يُرفض → وصول
  3. مستويات: قراءة فقط / قراءة + تعديل / كامل
  4. تشفير Vault key بـ X25519 key exchange
  5. Supabase: emergency_contacts, emergency_requests tables
  6. Edge Function: إشعار عند طلب وصول
الملفات:
  - lib/features/emergency/ (جديد — BLoC + screens + repository)
  - supabase/migrations/007_emergency_access.sql
  - supabase/functions/emergency-request/ (جديد)
```

#### 2.3 — Vault Item Versioning
```
الوصف: تاريخ تعديلات كلمات المرور مع إمكانية الاسترجاع
المكونات:
  1. جدول vault_item_versions في Drift (item_id, version, encrypted_snapshot, changed_at, change_type)
  2. حفظ snapshot مشفر عند كل تعديل
  3. عرض تاريخ التعديلات في VaultItemDetailScreen
  4. Rollback لأي نسخة سابقة
  5. تنظيف تلقائي بعد 90 يوم (configurable)
  6. مزامنة سحابية ضمن zero-knowledge sync
الملفات:
  - lib/core/database/smartvault_database.dart (migration)
  - lib/features/vault/
```

#### 2.4 — Secure Notes مع مرفقات مشفرة
```
الوصف: ملاحظات آمنة مع إمكانية إرفاق ملفات مشفرة
المكونات:
  1. فئة secureNote في VaultItems
  2. دعم مرفقات: PDF, صور, نصوص (max 10MB per file)
  3. تشفير المرفقات بـ AES-256-GCM قبل التخزين
  4. تخزين محلي في app_documents/encrypted_attachments/
  5. مزامنة عبر Supabase Storage bucket (مشفر)
  6. معاينة مرفقات + فك تشفير on-demand
الملفات:
  - lib/features/vault/ (توسيع)
  - supabase/ (storage bucket)
  - Drift migration
```

#### 2.5 — Passwordless Login (Magic Link)
```
الوصف: تسجيل دخول بدون كلمة مرور عبر رابط بريدي
المكونات:
  1. Supabase Auth Magic Link
  2. الضغط على الرابط → فتح التطبيق → Master Password
  3. لا يلغي Master Password — قناة إضافية
الملفات:
  - lib/features/auth/
  - Supabase Auth config
```

#### 2.6 — Multi-device Sync: 3-Way Merge
```
الوصف: استبدال "last write wins" بـ 3-way merge ذكي
المكونات:
  1. حفظ base version عند آخر sync
  2. مقارنة: base vs local vs remote
  3. تعارض حقل واحد → field-level merge
  4. تعارض نفس الحقل → UI للاختيار (مقارنة جنباً لجنب)
  5. Sync status indicators في VaultListScreen
الملفات:
  - lib/features/sync/ (إعادة كتابة)
  - lib/core/database/ (migration لـ base_version)
```

#### 2.7 — Offline Mode كامل مع Queue
```
الوصف: عمل كامل بدون اتصال مع مزامنة لاحقة
المكونات:
  1. جدول pending_operations في Drift (operation_type, payload, retry_count, status)
  2. Queue تخزن كل عملية عند عدم الاتصال
  3. عودة الاتصال → تنفيذ بالترتيب + conflict resolution
  4. مؤشر بصري (أيقونة offline + عدد المعلق)
  5. حد أقصى 3 محاولات retry
الملفات:
  - lib/features/sync/
  - lib/core/database/smartvault_database.dart
```

#### 2.8 — Accessibility (WCAG 2.1 AA)
```
الوصف: إتاحة كاملة لذوي الاحتياجات الخاصة
المكونات:
  1. Semantics widgets لجميع العناصر التفاعلية
  2. Contrast ratio 4.5:1 minimum
  3. TalkBack (Android) + VoiceOver (iOS) support
  4. Keyboard navigation (Web/Desktop)
  5. Min font size 14sp
  6. Focus indicators واضحة
  7. اختبار accessibility لكل شاشة
الملفات:
  - جميع lib/features/*/presentation/screens/
```

---

## 🌍 المرحلة 3 — توسيع المنصات (Platform Expansion)

> **الهدف:** CipherOwl يعمل على جميع المنصات بجودة متساوية.

### المهام

| # | المهمة | الأولوية | التبعية | الحالة |
|:-:|--------|:--------:|:-------:|:------:|
| 3.1 | **Web Platform (PWA)** — WASM crypto + WebRTC + responsive | 🟠 P1 | — | 🔵 لم تبدأ |
| 3.2 | **macOS Platform** — dylib FFI + Keychain + menu bar | 🔵 P2 | — | 🔵 لم تبدأ |
| 3.3 | **Windows Platform (إكمال)** — DLL FFI + Windows Hello + tray | 🔵 P2 | — | 🔵 لم تبدأ |
| 3.4 | **Linux Platform** — .so FFI + GNOME Keyring | ⬜ P3 | — | 🔵 لم تبدأ |

### التفاصيل التقنية

#### 3.1 — Web Platform (PWA)
```
المكونات:
  1. إعادة تفعيل Web في pubspec.yaml
  2. إنشاء web/index.html مع PWA support (service worker)
  3. Rust crypto → compile to WASM (wasm-bindgen)
  4. Platform abstractions:
     - flutter_secure_storage → Web Crypto API + IndexedDB
     - camera → WebRTC getUserMedia
     - local_auth → Web Credential Management API
  5. Responsive layout لجميع الشاشات
الملفات:
  - web/ (جديد)
  - lib/core/platform/ (platform abstractions)
```

#### 3.2 — macOS Platform
```
المكونات:
  1. flutter create --platforms=macos .
  2. Rust FFI via dylib (.dylib)
  3. Native keychain integration
  4. Menu bar integration
الملفات: macos/ (جديد)
```

#### 3.3 — Windows Platform (إكمال)
```
المكونات:
  1. Rust FFI via DLL (.dll) — التأكد من الربط
  2. Windows Hello integration
  3. System tray icon + autofill hotkey
الملفات: windows/
```

#### 3.4 — Linux Platform
```
المكونات:
  1. flutter create --platforms=linux .
  2. Rust FFI via shared object (.so)
  3. GNOME Keyring integration
الملفات: linux/ (جديد)
```

---

## 🧪 المرحلة 4 — الاختبارات وضمان الجودة (Testing & QA)

> **الهدف:** تغطية 95%+ · OWASP MASVS L2 كامل · استعداد لتدقيق خارجي.
> **ملاحظة:** تبدأ بالتوازي مع المراحل 1-3.

### المهام

| # | المهمة | الأولوية | التبعية | الحالة |
|:-:|--------|:--------:|:-------:|:------:|
| 4.1 | **Unit Tests حقيقية** — جميع BLoCs + Repos + Services (95%+) | 🔴 P0 | — | 🔵 لم تبدأ |
| 4.2 | **Integration Tests شاملة** — 8 user journeys كاملة | 🔴 P0 | — | 🔵 لم تبدأ |
| 4.3 | **Widget Tests** — كل شاشة جديدة + accessibility | 🟠 P1 | — | 🔵 لم تبدأ |
| 4.4 | **Rust Crypto Tests** — NIST/IETF vectors + fuzzing + memory | 🔴 P0 | — | 🔵 لم تبدأ |
| 4.5 | **OWASP MASVS L2** — cert pinning + root detect + screenshot prevent | 🔴 P0 | — | 🔵 لم تبدأ |
| 4.6 | **Penetration Testing** — SAST + DAST + dependency audit | 🟠 P1 | — | 🔵 لم تبدأ |
| 4.7 | **Performance Testing** — Argon2id + face + vault + memory | 🔵 P2 | — | 🔵 لم تبدأ |

### التفاصيل التقنية

#### 4.1 — Unit Tests (95%+ coverage)
```
الاختبارات المطلوبة:
  - vault_bloc_test.dart — CRUD + search + filter + travel mode
  - security_bloc_test.dart — score calculation + recommendations
  - settings_bloc_test.dart — preferences persistence
  - generator_bloc_test.dart — password/passphrase generation
  - gamification_bloc_test.dart — XP + badges + streaks
  - face_enrollment_bloc_test.dart — enrollment flow
  - sync_service_test.dart — zero-knowledge sync + conflict
  - vault_crypto_service_test.dart — encryption/decryption
  - auth_repository_test.dart — master password + duress
  - vault_repository_test.dart — CRUD operations
الملفات: test/unit/
```

#### 4.2 — Integration Tests شاملة
```
User Journeys:
  1. First launch → onboarding → setup → vault → add item → sync
  2. Lock → unlock (password, face, FIDO2)
  3. Sharing → receive → decrypt
  4. Emergency access request → approval → access
  5. Offline operations → reconnect → sync
  6. Import/Export CSV
  7. Recovery key flow
  8. Duress password flow
الملفات: test/integration/
```

#### 4.4 — Rust Crypto Tests
```
المكونات:
  1. NIST SP 800-38D test vectors لـ AES-GCM
  2. RFC 7748 test vectors لـ X25519
  3. RFC 8032 test vectors لـ Ed25519
  4. Fuzzing (cargo-fuzz) لكل دالة تشفير
  5. Memory leak tests لـ SecureBytes
الملفات: native/smartvault_core/tests/
```

#### 4.5 — OWASP MASVS L2 Compliance
```
Checklist:
  [ ] MASVS-STORAGE: No plaintext secrets anywhere
  [ ] MASVS-CRYPTO: Approved algorithms only (AES-256-GCM, Argon2id, X25519, Ed25519)
  [ ] MASVS-AUTH: Multi-factor, session management, biometric
  [ ] MASVS-NETWORK: Certificate pinning, TLS 1.3 only
  [ ] MASVS-PLATFORM: No 3rd-party keyboard, screenshot prevention
  [ ] MASVS-CODE: Obfuscation (R8/ProGuard), root/jailbreak detection
  [ ] MASVS-RESILIENCE: Anti-tampering, debugger detection
التنفيذ:
  - Certificate pinning (Supabase endpoints)
  - Root/jailbreak detection
  - Screenshot prevention (FLAG_SECURE)
  - Debugger detection
الملفات: lib/core/security/
```

#### 4.6 — Penetration Testing
```
المكونات:
  1. SAST: Semgrep + CodeQL static analysis
  2. DAST: Supabase API endpoint scanning
  3. Dependency audit: cargo audit + flutter pub audit
  4. Reverse engineering resistance test
الملفات: .github/workflows/security.yml
```

#### 4.7 — Performance Testing
```
المعايير:
  - Argon2id: <3 ثوان على أضعف جهاز مدعوم
  - Face detection: <300ms per frame
  - Vault load: <100ms لـ 1000 عنصر
  - Sync: <5 ثوان لـ 500 عنصر
  - Memory: لا memory leaks (profiling)
الملفات: test/performance/ (جديد)
```

---

## 🚀 المرحلة 5 — البنية التحتية للإنتاج (Production Infrastructure)

> **الهدف:** CI/CD + monitoring + legal = جاهز للإطلاق العالمي.

### المهام

| # | المهمة | الأولوية | التبعية | الحالة |
|:-:|--------|:--------:|:-------:|:------:|
| 5.1 | **CI/CD Pipeline (GitHub Actions)** — 8 workflows | 🔴 P0 | — | 🔵 لم تبدأ |
| 5.2 | **Monitoring & Analytics** — Sentry + privacy-first analytics | 🟠 P1 | — | 🔵 لم تبدأ |
| 5.3 | **Legal & Compliance** — Privacy Policy + ToS + GDPR | 🟠 P1 | — | 🔵 لم تبدأ |
| 5.4 | **Store Listings & ASO** — Google Play + App Store + Chrome | 🔵 P2 | — | 🔵 لم تبدأ |
| 5.5 | **Documentation** — API + User guide + Security whitepaper | 🔵 P2 | — | 🔵 لم تبدأ |

### التفاصيل التقنية

#### 5.1 — CI/CD Pipeline
```
Workflows:
  1. flutter_test.yml — دورة اختبارات كاملة على كل PR
  2. flutter_analyze.yml — lint + static analysis
  3. rust_test.yml — cargo test + cargo clippy + cargo audit
  4. build_android.yml — بناء APK + AAB تلقائي
  5. build_ios.yml — بناء IPA (macOS runner)
  6. build_web.yml — بناء PWA
  7. security_scan.yml — CodeQL + Semgrep + dependency audit
  8. release.yml — tag → build → sign → upload to stores
الملفات: .github/workflows/ (جديد)
```

#### 5.2 — Monitoring & Analytics
```
المكونات:
  1. Sentry/Crashlytics (لا بيانات حساسة!)
  2. Privacy-first analytics (Plausible أو Posthog self-hosted)
  3. Health check endpoint لـ Edge Functions
  4. Uptime monitoring لـ Supabase
الملفات: lib/core/services/analytics_service.dart (جديد)
```

#### 5.3 — Legal & Compliance
```
المكونات:
  1. Privacy Policy (AR + EN)
  2. Terms of Service (AR + EN)
  3. GDPR: data export + account deletion
  4. SOC 2 Type I readiness (documentation)
الملفات: docs/legal/ (جديد)
```

#### 5.4 — Store Listings & ASO
```
المكونات:
  1. Google Play: screenshots (6+), feature graphic, description (AR+EN)
  2. Apple App Store: screenshots (6.7"), description, keywords
  3. Chrome Web Store: listing for browser extension
الملفات: store/ (توسيع)
```

#### 5.5 — Documentation
```
المكونات:
  1. API documentation (Rust + Dart)
  2. User guide (AR + EN)
  3. Security whitepaper
  4. Architecture decision records (ADRs)
الملفات: docs/
```

---

## 🔗 مخطط التبعيات

```
المرحلة 0 ══════════════════════════════════════════
  ┌─ [0.1 zxcvbn]     ─┐
  ├─ [0.2 BIP39]       ├─ متوازي
  ├─ [0.3 Face Enroll] ─┤
  ├─ [0.5 Lint]        ─┤
  └─ [0.6 TODOs]       ─┘
     [0.4 Face Auth]   ←── يعتمد على 0.3
     [5.1 CI/CD]       ←── يبدأ مبكراً بالتوازي
                         │
المرحلة 1 ══════════════╪═══════════════════════════
  ┌─ [1.1 Sharing]     ─┐
  ├─ [1.2 FIDO2]       ─┤
  ├─ [1.4 FCM]         ─┤ متوازي
  ├─ [1.5 Duress]      ─┤
  ├─ [1.7 Browser Ext] ─┤
  └─ [1.8 Geofence]    ─┘
     [1.3 Anti-Spoof]  ←── يعتمد على 0.3 + 0.4
     [1.6 Recovery]    ←── يعتمد على 0.2
                         │
المرحلة 2 ══════════════╪═══════════════════════════
     [2.1 Health]      ←── يعتمد على 0.1
  ┌─ [2.2 Emergency]   ─┐
  ├─ [2.3 Versioning]  ─┤
  ├─ [2.4 Secure Notes]─┤ متوازي
  ├─ [2.5 Magic Link]  ─┤
  ├─ [2.6 3-Way Merge] ─┤
  └─ [2.8 Accessibility]┘
     [2.7 Offline Queue]←── يعتمد على 2.6
                         │
المرحلة 3 ══════════════╪═══════════════════════════
  ┌─ [3.1 Web]   ─┐
  ├─ [3.2 macOS]  ─┤ متوازي
  ├─ [3.3 Windows]─┤
  └─ [3.4 Linux]  ─┘
                         │
المرحلة 4 ═══ مستمرة بالتوازي مع 1-3 ══════════════
المرحلة 5 ═══ بعد اكتمال 0-4 ═══════════════════════
```

---

## ✅ معايير القبول (Acceptance Criteria)

### بعد كل مرحلة:
- [ ] `flutter analyze` — صفر أخطاء وتحذيرات
- [ ] `flutter test` — 100% pass
- [ ] `cargo test` — 100% pass (Rust)
- [ ] `flutter build apk --release` — بناء ناجح
- [ ] اختبار يدوي على جهاز حقيقي (Android)
- [ ] تحديث TASKS.md + ROADMAP_V2.md بالحالة الحقيقية

### قبل الإطلاق العالمي:
- [ ] تغطية اختبارات ≥95% (lcov report)
- [ ] OWASP MASVS L2 checklist — 100% مطبق
- [ ] Penetration test report — نظيف
- [ ] 3rd party security audit — تم + إصلاح الملاحظات
- [ ] Performance benchmarks — مقبولة على أضعف جهاز
- [ ] Privacy Policy + Terms of Service — منشورة (AR + EN)
- [ ] Store listings — مكتملة (AR + EN)
- [ ] جميع المنصات تعمل: Android, iOS, Web, Windows, macOS, Linux, Browser Extension
- [ ] `git tag v1.0.0 && git push --tags`

---

## 📈 الإحصائيات

| المؤشر | القيمة |
|--------|--------|
| مهام تصحيح أخطاء (مرحلة 0) | 6 |
| مهام إكمال ناقص (مرحلة 1) | 8 |
| ميزات جديدة (مرحلة 2) | 8 |
| منصات جديدة (مرحلة 3) | 4 |
| مهام اختبارات (مرحلة 4) | 7 |
| مهام إنتاج (مرحلة 5) | 5 |
| **المجموع** | **38 مهمة** |

---

## 🔑 القرارات التقنية

| القرار | الخيار المختار | السبب | البديل |
|--------|---------------|-------|--------|
| zxcvbn | Rust crate | أداء أفضل + أمان | Dart package كـ fallback |
| BIP39 | Rust crate | أمان أقوى + memory safety | Dart package الموجود |
| Sync | 3-way merge | دقة + لا فقدان بيانات | Last-write-wins الحالي |
| Web Crypto | Rust → WASM | كود موحد | إعادة كتابة بـ JS |
| FIDO2 | Passkeys + hardware | تغطية أوسع | Hardware keys فقط |
| Accessibility | WCAG 2.1 AA | كافي للإطلاق العالمي | AAA (مكلف) |
| Monitoring | Sentry + Plausible | Privacy-first | Google Analytics |

---

*آخر تحديث: 2026-03-06*
