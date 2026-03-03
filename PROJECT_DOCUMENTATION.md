# CipherOwl Security — توثيق المشروع الشامل

> **لمبرمج الاستمرار:** هذا الملف يحتوي على كامل تفاصيل المشروع من الصفر حتى حالته الراهنة. اقرأه كاملاً قبل لمس أي سطر كود.

---

## 1. نظرة عامة على المشروع

| الحقل | القيمة |
|---|---|
| **اسم المشروع** | CipherOwl Security / الخزنة الذكية |
| **النوع** | مشروع تخرج — مدير كلمات مرور احترافي |
| **Package ID** | `com.cipherowl.app` |
| **الإصدار الحالي** | 1.0.0+1 |
| **الإطار** | Flutter (Dart) |
| **المنصات المستهدفة** | Android, iOS (أولوية)، ثم Web + Desktop |
| **لغة الواجهة الأساسية** | العربية (RTL) مع دعم كامل للإنجليزية |
| **الثيم** | Dark Only — لا يوجد Light Mode |
| **تاريخ آخر تحديث للتوثيق** | 3 مارس 2026 |

### الرسالة الجوهرية
> CipherOwl هو أكثر من مجرد مدير كلمات مرور — هو **حارس رقمي يقظ 24/7** يدمج التشفير العسكري مع المراقبة البيومترية المستمرة ونظام تحفيزي (Gamification) يجعل الأمان ممتعاً.

---

## 2. الميزة الرئيسية المميزة: Face-Track Lock

هذه الميزة هي **قلب المشروع وعنصر اختلافه**:

- **ما تفعله:** تراقب وجه المستخدم كل **300ms** باستمرار أثناء استخدام التطبيق
- **إذا ابتعد الوجه أو اختفى:** يُقفل التطبيق **فوراً** دون أي تأخير
- **التقنية:** `google_mlkit_face_detection` لاكتشاف الوجه + نموذج `MobileFaceNet` (TFLite) لتحليل الـ embedding (128 بُعد)
- **الخصوصية:** كل المعالجة **محلية** على الجهاز 100% — لا يُرسل أي بيانات بيومترية للسحابة
- **الأمان:** بيانات الوجه مشفرة بـ AES-256-GCM ومخزنة في `flutter_secure_storage`

---

## 3. البنية التقنية الكاملة (Tech Stack)

### Frontend
| الطبقة | الأداة | الغرض |
|---|---|---|
| Framework | Flutter 3.x / Dart 3.3+ | التطبيق كاملاً |
| State Management | `flutter_bloc ^8.1.6` | إدارة الحالة بنمط BLoC |
| Navigation | `go_router ^14.2.7` | التنقل بين الشاشات |
| Responsive Design | `flutter_screenutil ^5.9.3` | تصميم متجاوب (Base: 390×844) |
| Animations | `rive ^0.13.13` + `lottie ^3.1.2` | الشاشة الانتقالية والتحريكات |
| Arabic Font | Cairo (300, 400, 500, 600, 700) | خط عربي احترافي |
| Mono Font | SpaceMono | عرض كلمات المرور والكودات |

### Backend
| الطبقة | الأداة | الغرض |
|---|---|---|
| Cloud Backend | Supabase (PostgreSQL + RLS) | قاعدة بيانات السحابة |
| Cloud Functions | Supabase Edge Functions (Deno) | منطق السيرفر |
| Push Notifications | Firebase Cloud Messaging | إشعارات الأمان |
| Auth | Supabase Auth + Zero-Knowledge | تسجيل الدخول بدون معرفة كلمة المرور |

### Local Database
| الأداة | الغرض |
|---|---|
| `drift ^2.20.2` + `drift_flutter` | قاعدة بيانات محلية مشفرة (ORM type-safe) |
| `sqlite3_flutter_libs` | SQLite المضمّن |
| SQLCipher | تشفير ملف قاعدة البيانات (مخطط للتكامل) |

### Cryptography Core (Rust)
| الطبقة | التفاصيل |
|---|---|
| حزمة Rust | `native/smartvault_core/` (لم يُنفَّذ بعد) |
| الجسر | `flutter_rust_bridge ^2.3.0` |
| خوارزمية Hash كلمة المرور | **Argon2id** — `t=3, m=65536 KB, p=4` |
| تشفير البيانات | **AES-256-GCM** |
| مفتاح التشفير | MEK (Master Encryption Key) 256-bit |
| تبادل المفاتيح | **X25519** (Diffie-Hellman) للمشاركة الآمنة |
| التوقيع الرقمي | **Ed25519** للتحقق من النزاهة |
| التجزئة الإضافية | PBKDF2 — 600,000 تكرار |
| مسح الذاكرة الآمن | `zeroize` crate (Rust) |
| قفل الذاكرة | `mlock` syscall لمنع Swap إلى القرص |

### Biometric / AI
| الأداة | الغرض |
|---|---|
| `google_mlkit_face_detection` | اكتشاف الوجه في الوقت الفعلي |
| `tflite_flutter ^0.10.4` | تشغيل MobileFaceNet محلياً |
| MobileFaceNet | استخراج 128-dim face embedding |
| `local_auth ^2.3.0` | بصمة إصبع + Face ID نظام |
| `camera ^0.11.0+2` | الوصول للكاميرا للـ Face-Track |

---

## 4. هيكل المجلدات الكامل

```
cipherowl/
├── lib/
│   ├── main.dart                           ← نقطة الدخول
│   ├── app.dart                            ← CipherOwlApp widget
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart          ← ✅ كامل
│   │   ├── theme/
│   │   │   └── app_theme.dart              ← ✅ كامل
│   │   ├── router/
│   │   │   └── app_router.dart             ← ✅ كامل
│   │   ├── localization/
│   │   │   └── app_localizations.dart      ← ❌ مطلوب الإنشاء
│   │   ├── security/                       ← ❌ مطلوب الإنشاء
│   │   └── utils/                          ← ❌ مطلوب الإنشاء
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/repositories/          ← ❌ مطلوب
│   │   │   ├── domain/entities/            ← ❌ مطلوب
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── splash_screen.dart  ← ✅ كامل
│   │   │       │   ├── lock_screen.dart    ← ✅ كامل (UI فقط)
│   │   │       │   └── setup_screen.dart   ← ✅ كامل (UI فقط)
│   │   │       └── bloc/                   ← ❌ مطلوب
│   │   │
│   │   ├── vault/
│   │   │   ├── data/repositories/          ← ❌ مطلوب
│   │   │   ├── domain/entities/            ← ❌ مطلوب
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── dashboard_screen.dart      ← ✅ كامل
│   │   │       │   ├── vault_list_screen.dart      ← ✅ (demo data)
│   │   │       │   ├── vault_item_detail_screen.dart ← ✅ (demo data)
│   │   │       │   └── add_edit_item_screen.dart   ← ✅ (UI فقط)
│   │   │       ├── bloc/                   ← ❌ مطلوب
│   │   │       └── widgets/                ← ❌ مطلوب
│   │   │
│   │   ├── security_center/
│   │   │   └── presentation/screens/
│   │   │       └── security_center_screen.dart ← ✅ (static data)
│   │   │
│   │   ├── face_track/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── face_setup_screen.dart  ← ✅ (UI فقط)
│   │   │       └── bloc/                       ← ❌ مطلوب
│   │   │
│   │   ├── generator/
│   │   │   └── presentation/
│   │   │       └── generator_screen.dart   ← ✅ كامل (منطق حقيقي)
│   │   │
│   │   ├── academy/
│   │   │   └── presentation/screens/
│   │   │       └── academy_screen.dart     ← ✅ كامل
│   │   │
│   │   ├── settings/
│   │   │   └── presentation/screens/
│   │   │       └── settings_screen.dart    ← ✅ (UI فقط)
│   │   │
│   │   ├── onboarding/
│   │   │   └── presentation/screens/
│   │   │       └── onboarding_screen.dart  ← ✅ كامل
│   │   │
│   │   ├── sharing/
│   │   │   └── presentation/screens/
│   │   │       └── sharing_screen.dart     ← ✅ (UI فقط)
│   │   │
│   │   └── enterprise/
│   │       └── presentation/screens/
│   │           └── enterprise_screen.dart  ← ✅ كامل (UI)
│   │
│   └── shared/
│       ├── widgets/
│       │   └── cipherowl_logo.dart         ← ✅ كامل (CustomPainter)
│       └── animations/                     ← ❌ مطلوب
│
├── assets/
│   ├── animations/      ← Rive (.riv) و Lottie (.json) — لم تُضَف بعد
│   ├── images/
│   │   ├── logo_owl.png ← ضع هنا صورة الشعار PNG
│   │   └── brands/      ← أيقونات المواقع (Facebook, Google, إلخ)
│   ├── fonts/
│   │   ├── Cairo-*.ttf  ← يجب تحميلها وإضافتها
│   │   └── SpaceMono-*.ttf
│   ├── models/          ← MobileFaceNet TFLite model هنا
│   ├── icons/
│   └── l10n/
│       ├── app_ar.arb   ← ❌ مطلوب الإنشاء (نصوص عربية)
│       └── app_en.arb   ← ❌ مطلوب الإنشاء (نصوص إنجليزية)
│
├── native/
│   └── smartvault_core/   ← ❌ Rust crate لم يُنشأ بعد
│       └── src/
│           ├── crypto/    ← Argon2id, AES-GCM, X25519
│           ├── memory/    ← zeroize, mlock
│           ├── face/      ← face embedding processing
│           └── password/  ← zxcvbn strength analysis
│
├── supabase/
│   ├── migrations/        ← ❌ SQL migrations لم تُكتب بعد
│   └── functions/         ← ❌ Edge Functions لم تُكتب بعد
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── android/app/src/main/java/com/cipherowl/app/
├── ios/Runner/
├── browser_extension/src/  ← امتداد المتصفح (مستقبلي)
│
├── pubspec.yaml            ← ✅ كامل (143 سطر)
├── PROJECT_DOCUMENTATION.md ← هذا الملف
└── CipherOwl_Logo/         ← على سطح المكتب (مجلد منفصل)
```

---

## 5. ملفات اللوغو (مكتملة)

الملفات في: `C:\Users\user\Desktop\CipherOwl_Logo\`

| الملف | الوصف | الاستخدام |
|---|---|---|
| `cipherowl_icon_dark.svg` | أيقونة البومة — أبيض على #0A0E17 | App Icon (Dark BG) |
| `cipherowl_icon_light.svg` | أيقونة البومة — داكن على أبيض | App Icon (Light BG) |
| `cipherowl_icon_color.svg` | عيون سيان، مفتاح ذهبي، جسم فضي | Marketing |
| `cipherowl_logo_dark.svg` | شعار كامل مع نص CIPHER+OWL | Header |
| `cipherowl_logo_color.svg` | شعار ملون كامل | Marketing |
| `cipherowl_icon_simplified.svg` | مبسّط لـ 48-96px | App Icons |
| `cipherowl_favicon.svg` | عيون + مفتاح فقط، لـ 16-32px | Browser Tab |
| `cipherowl_splash_animated.html` | HTML+CSS: 4 مراحل انتقالية | مرجع للـ Splash Screen |

**الأنيميشن في splash_animated.html (4 مراحل):**
1. `0.0s – 0.5s` → ظهور العيون بتوهج سيان
2. `0.5s – 1.5s` → ظهور الجسم والأجنحة
3. `1.5s – 2.2s` → دوران المفتاح 90°
4. `2.2s – 3.5s` → ظهور النص + "حارسك الرقمي"

---

## 6. ثوابت المشروع الكاملة (`app_constants.dart`)

### الألوان
```dart
backgroundDark   = #0A0E17   // خلفية رئيسية
surfaceDark      = #141824   // خلفية ثانوية (Cards, BottomNav)
cardDark         = #1E2438   // بطاقات العناصر
borderDark       = #2A3250   // حدود البطاقات
primaryCyan      = #00E5FF   // اللون الأساسي (أزرق سماوي)
primaryCyanLight = #4FF8FF
primaryCyanDark  = #00B8D4
accentGold       = #FFD700   // الذهبي (XP، الجوائز، المفتاح)
silver           = #B0BEC5
errorRed         = #FF3D57
successGreen     = #00E676
warningAmber     = #FFAB00
```

### معاملات التشفير
```dart
argon2Iterations  = 3          // زمن المعالجة
argon2Memory      = 65536 KB   // 64 MB استهلاك الذاكرة
argon2Parallelism = 4          // عدد الخيوط
pbkdf2Iterations  = 600,000    // PBKDF2 backup
mekSizeBytes      = 32         // 256-bit MEK
saltSizeBytes     = 16
nonceSizeBytes    = 12         // 96-bit GCM nonce
```

### المهل الزمنية
```dart
clipboardClearDelay     = 30 seconds  // مسح النسخ من الحافظة
inactivityLockDelay     = 5 minutes   // قفل بعد عدم النشاط
faceLockDetectInterval  = 300 ms      // دورة Face-Track
splashDuration          = 4 seconds
```

### المسارات (Routes)
```dart
routeSplash        = '/'
routeOnboarding    = '/onboarding'
routeSetup         = '/setup'
routeLock          = '/lock'
routeDashboard     = '/dashboard'
routeVaultList     = '/vault'         // داخل dashboard nested
routeVaultDetail   = '/vault/:id'
routeAddItem       = '/vault/add'
routeEditItem      = '/vault/edit/:id'
routeGenerator     = '/generator'
routeSecurityCenter= '/security-center'
routeAcademy       = '/academy'
routeSettings      = '/settings'
routeFaceSetup     = '/face-setup'
routeRecoverySetup = '/recovery-setup'
routeSharing       = '/sharing'
routeEnterprise    = '/enterprise'
```

### نظام XP (Gamification)
```dart
create_strong_password  = 10 XP
replace_weak_password   = 15 XP
enable_2fa              = 25 XP
complete_quiz           = 20 XP
daily_checkin           = 5 XP
secure_share            = 10 XP
fix_breach              = 30 XP
enable_face_track       = 25 XP
register_fido2          = 30 XP
save_recovery_key       = 20 XP
import_passwords        = 50 XP
zero_reuse_bonus        = 50 XP
finish_threat_academy   = 40 XP
```

### مستويات اللاعبين
| مستوى | من XP | إنجليزي | عربي |
|---|---|---|---|
| 1 | 0 | Novice | مبتدئ |
| 11 | 500 | Guardian | حارس |
| 21 | 2000 | Sentinel | حارس أمن |
| 31 | 5000 | Cryptographer | مشفّر |
| 41 | 12000 | Vault Master | سيد الخزنة |
| 49 | 30000 | Legendary | أسطوري |

### طبقات الأمان وأوزانها
```dart
master_password    = 20 نقطة
face_biometric     = 15 نقطة
fido2_key          = 15 نقطة
face_track         = 10 نقطة
duress_password    = 10 نقطة
intruder_snapshot  = 5 نقطة
encryption         = 15 نقطة  (دائماً مفعّل)
recovery           = 10 نقطة
// المجموع = 100 نقطة
```

---

## 7. تدفق التطبيق (User Flow)

```
التشغيل الأول:
SplashScreen (4s) → OnboardingScreen (3 pages) → SetupScreen (4 steps)
  → SetupPage1: Master Password + BIP39 Recovery
  → SetupPage2: Recovery Key (24 words مولّدة بـ Rust)
  → SetupPage3: Face-Track Setup (اختياري → FaceSetupScreen)
  → SetupPage4: Done → DashboardScreen

التشغيل العادي:
SplashScreen (4s) → LockScreen
  → أدخل كلمة المرور (Argon2id verify) OR
  → Face Unlock (MobileFaceNet) OR
  → FIDO2 Hardware Key
  → DashboardScreen (IndexedStack: 5 tabs)

داخل Dashboard:
Tab 0: VaultListScreen (قائمة الحسابات)
  → ضغط على عنصر: VaultItemDetailScreen(itemId)
  → ضغط على تعديل: AddEditItemScreen(itemId)
  → FAB: AddEditItemScreen() [جديد]
Tab 1: SecurityCenterScreen (درجة الأمان 0-100)
Tab 2: GeneratorScreen (كلمة مرور / عبارة مرور)
Tab 3: AcademyScreen (10 بطاقات تعليمية)
Tab 4: SettingsScreen
  → Face-Track: FaceSetupScreen
  → Enterprise: EnterpriseScreen
  → Sharing: SharingScreen
```

---

## 8. حالة كل شاشة بالتفصيل

### ✅ `SplashScreen`
- **الملف:** `lib/features/auth/presentation/screens/splash_screen.dart`
- **الحالة:** UI كامل، أنيميشن مبني بـ AnimationController يدوي
- **المطلوب:** ربط بمنطق التحقق (هل أول تشغيل؟ → onboarding : lock)
- **TODO:** `context.go(routeOnboarding)` إذا `!prefs.getBool('setup_done')`

### ✅ `LockScreen`
- **الملف:** `lib/features/auth/presentation/screens/lock_screen.dart`
- **الحالة:** UI كامل + shake animation عند الخطأ
- **المطلوب:** ربط فعلي مع Rust Argon2id verify
- **TODO:** استدعاء `RustBridge.verifyMasterPassword(input, storedHash)`
- **TODO:** Face unlock: تشغيل Face-Track للمقارنة مع المحفوظ
- **بعد 3 محاولات فاشلة:** يلتقط صورة الدخيل (Intruder Snapshot)

### ✅ `SetupScreen`
- **الملف:** `lib/features/auth/presentation/screens/setup_screen.dart`
- **الحالة:** 4 صفحات UI كاملة
- **المطلوب:**
  1. `SetupPage1`: ربط zxcvbn لقياس القوة الحقيقية، ثم `RustBridge.hashPassword()` بـ Argon2id، حفظ الهاش في `flutter_secure_storage`
  2. `SetupPage2`: توليد BIP39 mnemonic حقيقي عبر Rust crate `bip39`، تشفيره وحفظه
  3. `SetupPage3`: التوجيه لـ FaceSetupScreen

### ✅ `OnboardingScreen`
- **الملف:** `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- **الحالة:** كاملة — 3 صفحات مع PageView وحركة
- **المطلوب:** استبدال الـ Emoji بـ Rive animations

### ✅ `DashboardScreen`
- **الملف:** `lib/features/vault/presentation/screens/dashboard_screen.dart`
- **الحالة:** IndexedStack مع 5 Tabs + Bottom Navigation مخصص
- **الـ 5 شاشات:** VaultList, SecurityCenter, Generator, Academy, Settings
- **ملاحظة:** يستورد الشاشات بشكل مباشر (ليس ShellRoute)

### ✅ `VaultListScreen`
- **الملف:** `lib/features/vault/presentation/screens/vault_list_screen.dart`
- **الحالة:** UI كامل مع Demo Data
- **المطلوب:** ربط بـ `drift` database — استبدال `_demoItems` بـ `VaultRepository.watchAll()`
- **الفئات:** social, work, finance, entertainment, other
- **البحث:** يعمل محلياً على الـ demo data (يحتاج ربط بـ BLoC)

### ✅ `VaultItemDetailScreen`
- **الملف:** `lib/features/vault/presentation/screens/vault_item_detail_screen.dart`
- **المُعامل:** `itemId: String`
- **الحالة:** UI كامل مع Demo Data
- **يعرض:** Username, Password (مخفية/ظاهرة), URL, Notes, TOTP (ثابت الآن), Security Info
- **المطلوب:** ربط بـ drift بـ `itemId`، TOTP countdown حقيقي بـ `otp` package

### ✅ `AddEditItemScreen`
- **الملف:** `lib/features/vault/presentation/screens/add_edit_item_screen.dart`
- **المعامل:** `itemId: String?` — null = إضافة جديدة، قيمة = تعديل
- **الحالة:** Form كامل، strength bar، فئات
- **المطلوب:** ربط بـ drift CRUD، ربط zxcvbn، ربط مولّد كلمة المرور

### ✅ `GeneratorScreen`
- **الملف:** `lib/features/generator/presentation/generator_screen.dart`
- **الحالة:** **منطق حقيقي يعمل** باستخدام `Random.secure()`
- **Tab 1 - Password:** طول 8-64، خيارات أحرف كبيرة/صغيرة/أرقام/رموز، استبعاد متشابه
- **Tab 2 - Passphrase:** 3-8 كلمات، فاصل قابل للتخصيص
- **المطلوب:** استبدال `Random.secure()` بـ Rust CSPRNG، ربط zxcvbn الحقيقي

### ✅ `SecurityCenterScreen`
- **الملف:** `lib/features/security_center/presentation/screens/security_center_screen.dart`
- **الحالة:** رسم دائري متحرك (CustomPainter) + قائمة طبقات الأمان
- **الدرجة الحالية:** 87/100 (Static — يحتاج حساب ديناميكي)
- **المطلوب:** خدمة `SecurityScoreService` تحسب بناءً على البيانات الفعلية

### ✅ `AcademyScreen`
- **الملف:** `lib/features/academy/presentation/screens/academy_screen.dart`
- **الحالة:** كامل — Grid من 10 بطاقات تهديدات أمنية
- **التهديدات الـ 10:** التصيد، البرامج الخبيثة، هجمات كلمات المرور، الهندسة الاجتماعية، MITM/Sniffing، Ransomware، Deepfake، Dark Web Leaks، Zero-Day، Cloud-Native
- **المطلوب:** حفظ حالة "تمت القراءة" + إضافة XP فعلية عند الضغط "فهمت!"

### ✅ `SettingsScreen`
- **الملف:** `lib/features/settings/presentation/screens/settings_screen.dart`
- **الحالة:** UI كامل مع Switches
- **الإعدادات:** Face-Track, Biometric, Duress Mode, Lock Timeout, Dark Web monitoring, Autofill, Language, Backup, Face reconfigure, Enterprise, Delete all
- **المطلوب:** ربط كل إعداد بـ SharedPreferences/flutter_secure_storage

### ✅ `FaceSetupScreen`
- **الملف:** `lib/features/face_track/presentation/screens/face_setup_screen.dart`
- **الحالة:** 3 مراحل UI — Intro, Capture (5 لقطات), Done
- **يحاكي** التقاط الوجه (Fake delay 1s لكل لقطة)
- **المطلوب:**
  1. تفعيل `camera` package وعرض معاينة الكاميرا الحقيقية
  2. استخدام `google_mlkit_face_detection` لاكتشاف الوجه في كل لقطة
  3. تشغيل TFLite (MobileFaceNet) لاستخراج الـ embedding
  4. متوسط 5 embeddings وحفظها مشفرة في `flutter_secure_storage`

### ✅ `SharingScreen`
- **الملف:** `lib/features/sharing/presentation/screens/sharing_screen.dart`
- **الحالة:** UI كامل مع خيارات (One-time use, PIN, Expiry)
- **المطلوب:** استدعاء Supabase Edge Function لتوليد X25519 encrypted share link

### ✅ `EnterpriseScreen`
- **الملف:** `lib/features/enterprise/presentation/screens/enterprise_screen.dart`
- **الحالة:** UI كامل يعرض 8 ميزات مؤسسية في Grid
- **المطلوب:** تكامل LDAP/AD، SSO (SAML 2.0 / OIDC), Group Management

### ✅ `CipherOwlLogo`
- **الملف:** `lib/shared/widgets/cipherowl_logo.dart`
- **الحالة:** كامل — CustomPainter يرسم البومة + العيون + المفتاح بالأنيميشن
- **يستقبل:** 4 AnimationControllers من SplashScreen

---

## 9. التبعيات (pubspec.yaml) — كاملة

```yaml
# State Management
flutter_bloc: ^8.1.6
equatable: ^2.0.5

# Navigation
go_router: ^14.2.7

# Database
drift: ^2.20.2
drift_flutter: ^0.2.1
sqlite3_flutter_libs: ^0.5.24

# Rust Bridge
flutter_rust_bridge: ^2.3.0

# Cloud
supabase_flutter: ^2.5.9

# Face Detection
google_mlkit_face_detection: ^0.11.0
tflite_flutter: ^0.10.4

# Biometric
local_auth: ^2.3.0
flutter_secure_storage: ^9.2.2

# Animations
rive: ^0.13.13
lottie: ^3.1.2

# Camera
camera: ^0.11.0+2
image: ^4.2.0

# Network
connectivity_plus: ^6.0.5
dio: ^5.7.0
http: ^1.2.2

# Clipboard & Share
flutter_clipboard_manager: ^1.0.0+2
share_plus: ^10.0.2
url_launcher: ^6.3.1

# Notifications
firebase_messaging: ^15.1.4
flutter_local_notifications: ^17.2.3

# UI
cached_network_image: ^3.4.1
flutter_svg: ^2.0.10+1
shimmer: ^3.0.0
google_fonts: ^6.2.1
flutter_screenutil: ^5.9.3
auto_size_text: ^3.0.0
fluttertoast: ^8.2.8

# QR / TOTP
qr_flutter: ^4.1.0
mobile_scanner: ^5.2.3
otp: ^3.1.4

# Password
zxcvbn: ^1.0.0

# Import/Export
csv: ^6.0.0
file_picker: ^8.1.3
path_provider: ^2.1.4
path: ^1.9.0

# Crypto (Dart layer)
pointycastle: ^3.9.1
cryptography: ^2.7.0
bip39: ^1.0.6

# Utils
uuid: ^4.5.1
intl: ^0.19.0
collection: ^1.18.0
freezed_annotation: ^2.4.4
json_annotation: ^4.9.0
logger: ^2.4.0
package_info_plus: ^8.1.1
```

---

## 10. ما تم إنجازه ✅ وما لم يُنجز بعد ❌

### ✅ مكتمل
- [x] هيكل المجلدات الكامل (37+ مجلد)
- [x] `pubspec.yaml` مع جميع التبعيات
- [x] `main.dart` — Supabase init، orientation lock، BlocObserver
- [x] `app.dart` — MaterialApp.router، ScreenUtil، Arabic locale، Dark theme
- [x] `app_constants.dart` — جميع الألوان، المسارات، الثوابت، Gamification، XP
- [x] `app_theme.dart` — Material3 Dark Theme كامل
- [x] `app_router.dart` — GoRouter مع جميع المسارات الـ 15
- [x] جميع الشاشات الـ 15 (UI اكتمل، البيانات demo)
- [x] `cipherowl_logo.dart` — CustomPainter مع 4 أنيميشن
- [x] ملفات اللوغو الـ 8 (SVG + HTML)

### ❌ مطلوب إنشاؤه (بالأولوية)

#### الأولوية القصوى (بلوك الـ compile)
1. **`lib/core/localization/app_localizations.dart`** — مستورد في `app.dart` ولن يُكمبَّل بدونه

#### الأولوية العالية (منطق الأمان)
2. **Rust Crate** — `native/smartvault_core/`
   - `src/crypto/` — Argon2id hash/verify، AES-256-GCM encrypt/decrypt، X25519
   - `src/memory/` — SecureBuffer struct يستخدم zeroize + mlock
   - `src/password/` — zxcvbn strength scorer
   - `src/face/` — CosineSimilarity لمقارنة face embeddings
3. **Drift Database Schema** — تعريف الجداول والـ DAOs
4. **BLoC Classes** — AuthBloc، VaultBloc، FaceTrackBloc، SecurityBloc

#### الأولوية المتوسطة
5. **Localization ARB files** — `assets/l10n/app_ar.arb`، `app_en.arb`
6. **Supabase Migrations** — SQL لجداول `vault_items`، `shared_items`، `user_profile`
7. **Firebase Setup** — `google-services.json` (Android)،`GoogleService-Info.plist` (iOS)
8. **Face-Track Background Service** — Timer.periodic لاستدعاء MLKit كل 300ms
9. **TOTP Logic** — ربط `otp` package مع CountdownTimer

#### الأولوية المنخفضة (مستقبلي)
10. **Rive Animations** — تصميم ملفات `.riv` للشاشة الانتقالية والـ Academy
11. **Browser Extension** — `browser_extension/src/`
12. **FIDO2 Integration** — WebAuthn (يحتاج platform channel)
13. **Dark Web Monitoring** — ربط بـ HaveIBeenPwned API
14. **Enterprise LDAP/SSO** — تكامل SAML 2.0

---

## 11. إعداد البيئة وتشغيل المشروع

### المتطلبات الأساسية
```bash
# 1. Flutter SDK (مطلوب إضافته)
# حمّل من: https://flutter.dev/docs/get-started/install/windows
# افتح PowerShell وأضف:
$env:PATH += ";C:\flutter\bin"

# 2. Rust (للـ native core — مستقبلي)
# حمّل من: https://rustup.rs

# 3. Android Studio أو VS Code + Flutter extension

# 4. Git
winget install Git.Git
```

### تشغيل المشروع
```bash
cd C:\Users\user\OneDrive\Desktop\cipherowl

# تثبيت الحزم
flutter pub get

# تشغيل على جهاز أو محاكي
flutter run

# بناء APK للاختبار
flutter build apk --debug

# بناء APK للإنتاج
flutter build apk --release --obfuscate --split-debug-info=debug_info
```

### إعداد Supabase
1. أنشئ مشروعاً على [supabase.com](https://supabase.com)
2. انسخ `Project URL` و `anon public key`
3. في `lib/core/constants/app_constants.dart` عدّل:
```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### إعداد Firebase (للإشعارات)
1. أنشئ مشروعاً في [console.firebase.google.com](https://console.firebase.google.com)
2. أضف تطبيق Android بـ packageName: `com.cipherowl.app`
3. حمّل `google-services.json` → `android/app/`
4. أضف تطبيق iOS → حمّل `GoogleService-Info.plist` → `ios/Runner/`

---

## 12. كيفية إنشاء `app_localizations.dart` (المطلوب أولاً)

هذا الملف مستورد في `app.dart` وبدونه لن يُكمبَّل المشروع:

```dart
// lib/core/localization/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_name': 'CipherOwl',
      'vault': 'الخزنة',
      'security': 'الأمان',
      'generator': 'المولّد',
      'academy': 'الأكاديمية',
      'settings': 'الإعدادات',
      // أضف المزيد...
    },
    'en': {
      'app_name': 'CipherOwl',
      'vault': 'Vault',
      'security': 'Security',
      'generator': 'Generator',
      'academy': 'Academy',
      'settings': 'Settings',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
```

---

## 13. كيفية إنشاء Drift Database Schema

```dart
// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// ── جدول عناصر الخزنة ─────────────────────────────────
class VaultItems extends Table {
  TextColumn get id => text().withDefault(genRandomUuid())();
  TextColumn get title => text()();
  TextColumn get encryptedUsername => text()();   // مشفر بـ MEK
  TextColumn get encryptedPassword => text()();   // مشفر بـ MEK
  TextColumn get encryptedUrl => text().nullable()();
  TextColumn get encryptedNotes => text().nullable()();
  TextColumn get encryptedTotp => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get strengthScore => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get passwordChangedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

// ── قاعدة البيانات ─────────────────────────────────────
@DriftDatabase(tables: [VaultItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cipherowl_vault');
  }
}
```

---

## 14. كيفية إنشاء VaultBloc

```dart
// lib/features/vault/presentation/bloc/vault_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ── Events ─────────────────────────────────────────────
abstract class VaultEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadVaultItems extends VaultEvent {}
class AddVaultItem extends VaultEvent {
  final String title, username, password;
  // إلخ...
  AddVaultItem({required this.title, required this.username, required this.password});
}
class DeleteVaultItem extends VaultEvent {
  final String id;
  DeleteVaultItem(this.id);
  @override List<Object?> get props => [id];
}
class SearchVaultItems extends VaultEvent {
  final String query;
  SearchVaultItems(this.query);
}

// ── States ─────────────────────────────────────────────
abstract class VaultState extends Equatable {
  @override List<Object?> get props => [];
}
class VaultInitial extends VaultState {}
class VaultLoading extends VaultState {}
class VaultLoaded extends VaultState {
  final List<dynamic> items; // استبدل بـ VaultItem entity
  VaultLoaded(this.items);
  @override List<Object?> get props => [items];
}
class VaultError extends VaultState {
  final String message;
  VaultError(this.message);
}

// ── BLoC ───────────────────────────────────────────────
class VaultBloc extends Bloc<VaultEvent, VaultState> {
  VaultBloc() : super(VaultInitial()) {
    on<LoadVaultItems>(_onLoad);
    on<AddVaultItem>(_onAdd);
    on<DeleteVaultItem>(_onDelete);
  }

  Future<void> _onLoad(LoadVaultItems event, Emitter<VaultState> emit) async {
    emit(VaultLoading());
    try {
      // TODO: final items = await vaultRepository.getAll();
      emit(VaultLoaded([]));
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> _onAdd(AddVaultItem event, Emitter<VaultState> emit) async {
    // TODO: encrypt fields + save to drift + sync supabase
  }

  Future<void> _onDelete(DeleteVaultItem event, Emitter<VaultState> emit) async {
    // TODO: soft delete in drift + sync supabase
  }
}
```

---

## 15. معمارية التشفير (كيف تعمل)

```
المستخدم يكتب Master Password
         ↓
[Rust: Argon2id] ← salt (عشوائي 16 byte، محفوظ في flutter_secure_storage)
         ↓
  Derived Key (32 bytes) = KDF Key
         ↓
[Rust: AES-256-GCM] يفك تشفير MEK المخزّن
         ↓
  Master Encryption Key (MEK) = 256-bit في SecureBuffer (zeroize + mlock)
         ↓
لكل كلمة مرور:
  [Rust: AES-256-GCM] encrypt(plaintext, MEK, random_nonce_12bytes)
  → ciphertext + nonce → يُحفظ في drift database

عند العرض:
  [Rust: AES-256-GCM] decrypt(ciphertext, MEK, stored_nonce)
  → plaintext → يُعرض للمستخدم لـ 30 ثانية ثم يُمسح من الذاكرة بـ zeroize
```

---

## 16. ميزة Face-Track — التنفيذ الكامل

```dart
// الخطوات المطلوبة في lib/features/face_track/

// 1. FaceTrackService — خدمة تعمل في الخلفية
class FaceTrackService {
  Timer? _timer;
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: false,
      enableLandmarks: false,
    ),
  );

  void startMonitoring(CameraController cameraCtrl, VoidCallback onFaceGone) {
    _timer = Timer.periodic(
      const Duration(milliseconds: 300), // AppConstants.faceLockDetectInterval
      (_) async {
        final faces = await _detectFaces(cameraCtrl);
        if (faces.isEmpty) {
          onFaceGone(); // → LockVault event
        }
      },
    );
  }

  void stopMonitoring() => _timer?.cancel();
}

// 2. عند التسجيل (FaceSetupScreen):
//    - التقط 5 صور
//    - استخرج embedding من كل صورة بـ MobileFaceNet TFLite
//    - احسب متوسط الـ 5 embeddings
//    - شفّر الـ embedding بـ MEK واحفظه في flutter_secure_storage

// 3. عند المقارنة (Lock unlock بالوجه):
//    - التقط صورة لحظية
//    - استخرج embedding
//    - احسب cosine similarity مع المحفوظ
//    - إذا similarity > 0.85 → مطابقة (افتح)
//    - إذا < 0.85 → رفض (حاولة فاشلة)
```

---

## 17. Supabase Database Schema

```sql
-- migrations/001_initial.sql

-- ── جدول المستخدمين (Zero-Knowledge) ──────────────────
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  encrypted_vault_key TEXT NOT NULL,  -- MEK مشفر بـ KDF
  salt_hex TEXT NOT NULL,             -- Salt لـ Argon2id
  face_embedding_encrypted TEXT,      -- embedding مشفر (اختياري)
  recovery_key_hash TEXT NOT NULL,    -- hash مفتاح BIP39
  security_score INTEGER DEFAULT 0,
  total_xp INTEGER DEFAULT 0,
  current_level INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── جدول العناصر المشفرة ──────────────────────────────
CREATE TABLE vault_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  encrypted_data TEXT NOT NULL,   -- كل البيانات مشفرة كـ JSON واحد بـ AES-256-GCM
  nonce_hex TEXT NOT NULL,        -- 96-bit GCM nonce
  category TEXT DEFAULT 'other',
  strength_score INTEGER DEFAULT 0,
  is_favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Row Level Security ────────────────────────────────
ALTER TABLE vault_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only see own items"
  ON vault_items FOR ALL
  USING (auth.uid() = user_id);

-- ── جدول المشاركة الآمنة ──────────────────────────────
CREATE TABLE shared_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES user_profiles(id),
  encrypted_share TEXT NOT NULL,    -- مشفر بـ X25519 public key المستلم
  recipient_email TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  is_one_time BOOLEAN DEFAULT TRUE,
  require_pin BOOLEAN DEFAULT FALSE,
  pin_hash TEXT,
  accessed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 18. الميزات المتقدمة (مخططة للتنفيذ)

### كلمة المرور الإكراهية (Duress Password)
- كلمة مرور ثانية مختلفة عن الأساسية
- عند إدخالها يُفتح التطبيق على **خزنة فارغة**
- تُرسل إشعاراً سرياً (Silent Alert) للجهة المثوق بها
- لا يعلم المهاجم أنه يرى خزنة فارغة

### التقاط الدخيل (Intruder Snapshot)
- بعد 3 محاولات دخول فاشلة
- يلتقط صورة من الكاميرا الأمامية
- يحفظها مشفرة محلياً + يرسلها للسحابة
- يُسجّل: وقت المحاولة، عدد المحاولات، موقع GPS (إذا مسموح)

### Travel Mode (وضع السفر)
- يُخفي مؤقتاً فئات معينة من الخزنة
- مفيد عند عبور الحدود ومراقبة الأجهزة
- لا يحذف البيانات — فقط يُخفيها

### Geo-Fencing
- يقفل تلقائياً عند الخروج من منطقة جغرافية محددة
- مثال: يقفل إذا غادر المستخدم مدينته

### مراقبة الويب المظلم
- يربط `HaveIBeenPwned API` (`k-anonymity` — لا يُرسل الـ hash كاملاً)
- يُنبّه فوراً لو ظهر email أو كلمة مرور في قواعد بيانات مسرّبة

---

## 19. نظام Gamification الكامل

### الشارات المخططة (25 شارة)
| الشارة | الشرط |
|---|---|
| 🔒 Fort Knox | درجة أمان 100/100 |
| 🏆 First Vault | إضافة أول كلمة مرور |
| 💎 Crystal Clear | كل كلمات المرور فريدة |
| 🎓 Security Graduate | إتمام 10 دروس الأكاديمية |
| 👁️ All Seeing | تفعيل Face-Track |
| 🔑 Key Master | تسجيل FIDO2 key |
| 🌙 Midnight Guardian | استخدام التطبيق 7 أيام متتالية |
| 🛡️ Breach Slayer | إصلاح 5 كلمات مرور مخترقة |
| 📤 Sharing is Caring | مشاركة كلمة مرور بأمان لأول مرة |
| ⚡ Speed Demon | تغيير كلمة مرور خلال 5 دقائق من التنبيه |

### نظام الـ Streaks
- **يومي:** استخدم التطبيق 7 أيام متتالية → +50 XP bonus
- **الأسبوع الكامل:** درجة أمان ≥ 80 طوال أسبوع → +100 XP

### التحديات اليومية
- مثال: "غيّر كلمة مرور ضعيفة اليوم" → +30 XP
- مثال: "راجع 3 حسابات في الأكاديمية" → +20 XP

---

## 20. تنسيق الشعار ودليل الاستخدام

### الشعار الرسمي
- **رمز البومة:** يمثل اليقظة المستمرة + الحراسة → مرتبط بـ Face-Track
- **المفتاح المدمج:** يمثل التشفير والوصول الآمن
- **الأسلوب الهندسي (Geometric):** مهني + عصري + تقني

### الألوان الأساسية
```
Primary Cyan:    #00E5FF  — ثقة، تقنية، حماية
Accent Gold:     #FFD700  — جوائز، نجاحات، XP
Background Dark: #0A0E17  — عمق، سرية، أمان
```

### استخدامات الشعار
- **App Icon (Google Play / App Store):** `cipherowl_icon_color.svg` أو المبسط
- **Splash Screen:** CustomPainter في `cipherowl_logo.dart` + أنيميشن
- **Header:** `cipherowl_logo_dark.svg` أو `_color.svg`
- **Favicon:** `cipherowl_favicon.svg`

---

## 21. قائمة TODO الأولوية للمبرمج التالي

### 🔴 فوري (بلوك الـ compile)
```
1. أنشئ: lib/core/localization/app_localizations.dart
   → انسخ الكود من القسم 12 في هذا الملف
```

### 🟠 أسبوع أول
```
2. flutter pub get (بعد تثبيت Flutter SDK)
3. إنشاء Drift database schema (QueryسطياCode من القسم 13)
4. إنشاء VaultBloc + AuthBloc (كود من القسم 14)
5. ربط VaultListScreen بـ drift database
6. إنشاء assets/l10n/app_ar.arb و app_en.arb
7. إضافة ملفات Font (Cairo + SpaceMono) إلى assets/fonts/
```

### 🟡 أسبوع ثاني
```
8. إنشاء Supabase project وتحديث المفاتيح في app_constants.dart
9. تنفيذ Rust crate لـ Argon2id + AES-256-GCM (القسم 3)
10. ربط LockScreen بالتحقق الفعلي (Argon2id verify)
11. ربط SetupScreen بـ hash كلمة المرور (Argon2id)
12. تفعيل Camera في FaceSetupScreen
13. تكامل MobileFaceNet TFLite
```

### 🟢 أسبوع ثالث-رابع
```
14. Face-Track background monitoring (Timer.periodic 300ms)
15. TOTP countdown حقيقي في VaultItemDetailScreen
16. Supabase sync للـ vault items
17. مراقبة Websocket لـ Dark Web leaks
18. Intruder Snapshot بعد 3 محاولات فاشلة
19. Duress Password logic
20. Rive animations للـ Splash + Academy
```

---

## 22. معلومات الاتصال وموارد المشروع

| الموضوع | الرابط / الملاحظة |
|---|---|
| موقع ملفات اللوغو | `C:\Users\user\Desktop\CipherOwl_Logo\` |
| موقع المشروع | `C:\Users\user\OneDrive\Desktop\cipherowl\` |
| Supabase | يحتاج إنشاء مشروع جديد |
| Firebase | يحتاج إنشاء مشروع جديد |
| Flutter SDK | يحتاج تثبيت |
| Rust | يحتاج تثبيت (rustup.rs) |

---

> **ملاحظة ختامية للمبرمج:** المشروع مبني بعناية فائقة. كل شاشة لها منطقها الواضح، الكود نظيف ومعلّق، والبنية تتبع Clean Architecture مع BLoC. ابدأ بإنشاء `app_localizations.dart` ثم `flutter pub get`، لتتأكد من compile نظيف قبل إضافة أي منطق.

---

*CipherOwl Security — حارسك الرقمي 🦉*
