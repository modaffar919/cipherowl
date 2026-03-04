import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// Application name
  ///
  /// In ar, this message translates to:
  /// **'CipherOwl'**
  String get appName;

  /// App tagline shown on splash/onboarding
  ///
  /// In ar, this message translates to:
  /// **'حارسك الرقمي'**
  String get appTagline;

  /// App version label
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String appVersion(String version);

  /// Next button
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// Skip button
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get skip;

  /// Skip now button on onboarding
  ///
  /// In ar, this message translates to:
  /// **'تخطي الآن'**
  String get skipNow;

  /// Later button
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get later;

  /// Cancel button
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// Confirm button
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// Save button
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// Delete button
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// Done button
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// Copy button
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// Add button
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// Edit button
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// Close button
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// Search hint/label
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// Generic loading message
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// Generic error label
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// Generic success label
  ///
  /// In ar, this message translates to:
  /// **'نجاح'**
  String get success;

  /// Snackbar shown after copying to clipboard
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ ✓'**
  String get copiedSuccess;

  /// Confirmation that data is saved securely
  ///
  /// In ar, this message translates to:
  /// **'لقد حفظتها بأمان ✓'**
  String get savedSecurely;

  /// Positive feedback label
  ///
  /// In ar, this message translates to:
  /// **'رائع! ✓'**
  String get excellent;

  /// 404 error page message
  ///
  /// In ar, this message translates to:
  /// **'404 - الصفحة غير موجودة'**
  String get pageNotFound;

  /// First onboarding slide title
  ///
  /// In ar, this message translates to:
  /// **'حماية عسكرية لكلماتك'**
  String get onboardingTitle1;

  /// First onboarding slide description
  ///
  /// In ar, this message translates to:
  /// **'تشفير AES-256 وAES-256-GCM العسكري يحمي كل بياناتك'**
  String get onboardingDesc1;

  /// Second onboarding slide title
  ///
  /// In ar, this message translates to:
  /// **'Face-Track الذكاء المستمر'**
  String get onboardingTitle2;

  /// Second onboarding slide description
  ///
  /// In ar, this message translates to:
  /// **'مراقبة بيومترية مستمرة تقفل الخزنة عند ابتعادك تلقائياً'**
  String get onboardingDesc2;

  /// Third onboarding slide title
  ///
  /// In ar, this message translates to:
  /// **'حمايتك في كل مكان'**
  String get onboardingTitle3;

  /// Third onboarding slide description
  ///
  /// In ar, this message translates to:
  /// **'مزامنة آمنة عبر أجهزتك بتشفير Zero-Knowledge'**
  String get onboardingDesc3;

  /// Get started CTA on onboarding
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسجيل'**
  String get getStarted;

  /// Academy section CTA
  ///
  /// In ar, this message translates to:
  /// **'تعلّم وأكسب نقاطاً'**
  String get learnAndEarnPoints;

  /// Unlock vault button on lock screen
  ///
  /// In ar, this message translates to:
  /// **'فتح الخزنة 🔓'**
  String get openVault;

  /// Enter vault prompt
  ///
  /// In ar, this message translates to:
  /// **'ادخل إلى خزنتك 🔓'**
  String get enterVault;

  /// Generator screen subtitle
  ///
  /// In ar, this message translates to:
  /// **'اصنع كلمات مرور غير قابلة للكسر'**
  String get createUnbreakablePasswords;

  /// Master password field label
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الرئيسية'**
  String get masterPassword;

  /// Master password field hint
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور الرئيسية'**
  String get enterMasterPassword;

  /// 2FA code field label
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق (2FA)'**
  String get verificationCode2FA;

  /// Biometric auth prompt
  ///
  /// In ar, this message translates to:
  /// **'استخدم بصمة الوجه أو البصمة للدخول'**
  String get biometricPrompt;

  /// Setup screen title
  ///
  /// In ar, this message translates to:
  /// **'إعداد كلمة المرور الرئيسية'**
  String get setupMasterPassword;

  /// Confirm password field label
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// Password mismatch error
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordsDoNotMatch;

  /// Password too short error
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور قصيرة جداً (12 حرفاً على الأقل)'**
  String get passwordTooShort;

  /// Vault screen title
  ///
  /// In ar, this message translates to:
  /// **'الخزنة'**
  String get vaultTitle;

  /// Add vault item button
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنصر'**
  String get addItem;

  /// Edit vault item title
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنصر'**
  String get editItem;

  /// Vault item detail screen title
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الحساب'**
  String get itemDetails;

  /// Category field label
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get category;

  /// Copy password action
  ///
  /// In ar, this message translates to:
  /// **'نسخ كلمة المرور'**
  String get copyPassword;

  /// Password copied snackbar
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ كلمة المرور ✓'**
  String get passwordCopied;

  /// Password copied with auto-clear notice
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ كلمة المرور — تمسح خلال 30 ثانية'**
  String get passwordCopiedWillClear;

  /// Delete account confirmation title
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب؟'**
  String get deleteAccount;

  /// Delete all data confirmation title
  ///
  /// In ar, this message translates to:
  /// **'حذف كل البيانات؟'**
  String get deleteAllData;

  /// Permanent delete button
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائياً'**
  String get deletePermanently;

  /// Delete account warning message
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف جميع بياناتك نهائياً بدون إمكانية الاسترداد.'**
  String get deleteAccountWarning;

  /// Warning that action cannot be undone
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذا الإجراء.'**
  String get irreversibleAction;

  /// Password generator screen title
  ///
  /// In ar, this message translates to:
  /// **'مولّد كلمات المرور'**
  String get generatorTitle;

  /// Generate password button
  ///
  /// In ar, this message translates to:
  /// **'توليد كلمة مرور قوية'**
  String get generateStrongPassword;

  /// Password length label
  ///
  /// In ar, this message translates to:
  /// **'الطول'**
  String get length;

  /// Passphrase word count label
  ///
  /// In ar, this message translates to:
  /// **'عدد الكلمات'**
  String get wordCount;

  /// Recommendations section title
  ///
  /// In ar, this message translates to:
  /// **'التوصيات'**
  String get recommendations;

  /// Security center screen title
  ///
  /// In ar, this message translates to:
  /// **'مركز الأمان'**
  String get securityCenter;

  /// Security score section header
  ///
  /// In ar, this message translates to:
  /// **'درجة الأمان الكلية'**
  String get overallSecurityScore;

  /// Security information label
  ///
  /// In ar, this message translates to:
  /// **'معلومات الأمان'**
  String get securityInfo;

  /// Face-Track setup screen title
  ///
  /// In ar, this message translates to:
  /// **'إعداد Face-Track'**
  String get faceTrackSetup;

  /// Face-Track activation success message
  ///
  /// In ar, this message translates to:
  /// **'Face-Track أصبح يعمل الآن.\nستُقفل الخزنة تلقائياً إذا ابتعدت.'**
  String get faceTrackActive;

  /// How Face-Track works label
  ///
  /// In ar, this message translates to:
  /// **'كيف يعمل Face-Track؟'**
  String get faceTrackHowItWorks;

  /// Face capture instruction
  ///
  /// In ar, this message translates to:
  /// **'ضع وجهك داخل الدائرة وانظر مباشرة للشاشة'**
  String get placeFaceInCircle;

  /// Capture button
  ///
  /// In ar, this message translates to:
  /// **'التقاط'**
  String get capture;

  /// Face capture progress indicator
  ///
  /// In ar, this message translates to:
  /// **'التقاط {current} / {total}'**
  String captureProgress(int current, int total);

  /// Face registration success message
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل وجهك بنجاح!'**
  String get faceSavedSuccess;

  /// Auto-lock timeout setting label
  ///
  /// In ar, this message translates to:
  /// **'مهلة القفل التلقائي'**
  String get autoLockTimeout;

  /// Minutes unit label
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String minuteUnit(int minutes);

  /// Settings screen title
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// Academy screen title
  ///
  /// In ar, this message translates to:
  /// **'أكاديمية التهديدات'**
  String get academyTitle;

  /// Sharing screen title
  ///
  /// In ar, this message translates to:
  /// **'المشاركة الآمنة'**
  String get sharingTitle;

  /// Active sharing links section header
  ///
  /// In ar, this message translates to:
  /// **'الروابط النشطة'**
  String get activeLinks;

  /// Create secure link button
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رابط آمن'**
  String get createSecureLink;

  /// Share link creation label
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رابط مشاركة'**
  String get createShareLink;

  /// Share link created success
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الرابط'**
  String get linkCreated;

  /// Copy share link button
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرابط'**
  String get copyLink;

  /// Link copied to clipboard snackbar
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get linkCopied;

  /// Link expiry duration label
  ///
  /// In ar, this message translates to:
  /// **'مدة الصلاحية'**
  String get expiryDuration;

  /// Enterprise screen title
  ///
  /// In ar, this message translates to:
  /// **'وضع المؤسسة'**
  String get enterpriseTitle;

  /// Enterprise features section header
  ///
  /// In ar, this message translates to:
  /// **'الميزات المؤسسية'**
  String get enterpriseFeatures;

  /// Enterprise value proposition subtitle
  ///
  /// In ar, this message translates to:
  /// **'حماية شاملة لفرق العمل والمؤسسات'**
  String get enterpriseProtection;

  /// Enterprise pricing CTA
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا للحصول على سعر مخصص للمؤسسات'**
  String get enterprisePricing;

  /// Contact sales button
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع فريق المبيعات'**
  String get contactSales;

  /// Team size field label
  ///
  /// In ar, this message translates to:
  /// **'كم موظفاً في فريقك؟'**
  String get teamSize;

  /// Enterprise mode badge label
  ///
  /// In ar, this message translates to:
  /// **'وضع المؤسسة'**
  String get enterpriseMode;

  /// PRO badge label
  ///
  /// In ar, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// Academy card dismiss with XP reward
  ///
  /// In ar, this message translates to:
  /// **'فهمت! (+{xp} XP)'**
  String gotItXP(int xp);

  /// XP earned label
  ///
  /// In ar, this message translates to:
  /// **'+{xp} XP'**
  String earnedXP(int xp);

  /// Score suffix out of 100
  ///
  /// In ar, this message translates to:
  /// **'/ 100'**
  String get scoreOutOf100;

  /// Enterprise product name
  ///
  /// In ar, this message translates to:
  /// **'CipherOwl Enterprise'**
  String get cipherowlEnterprise;

  /// Security product variant name
  ///
  /// In ar, this message translates to:
  /// **'CipherOwl Security'**
  String get cipherowlSecurity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
