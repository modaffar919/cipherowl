// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'CipherOwl';

  @override
  String get appTagline => 'حارسك الرقمي';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get next => 'التالي';

  @override
  String get skip => 'تخطي';

  @override
  String get skipNow => 'تخطي الآن';

  @override
  String get later => 'لاحقاً';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get done => 'تم';

  @override
  String get copy => 'نسخ';

  @override
  String get add => 'إضافة';

  @override
  String get edit => 'تعديل';

  @override
  String get close => 'إغلاق';

  @override
  String get search => 'بحث';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get copiedSuccess => 'تم النسخ ✓';

  @override
  String get savedSecurely => 'لقد حفظتها بأمان ✓';

  @override
  String get excellent => 'رائع! ✓';

  @override
  String get pageNotFound => '404 - الصفحة غير موجودة';

  @override
  String get onboardingTitle1 => 'حماية عسكرية لكلماتك';

  @override
  String get onboardingDesc1 =>
      'تشفير AES-256 وAES-256-GCM العسكري يحمي كل بياناتك';

  @override
  String get onboardingTitle2 => 'Face-Track الذكاء المستمر';

  @override
  String get onboardingDesc2 =>
      'مراقبة بيومترية مستمرة تقفل الخزنة عند ابتعادك تلقائياً';

  @override
  String get onboardingTitle3 => 'حمايتك في كل مكان';

  @override
  String get onboardingDesc3 => 'مزامنة آمنة عبر أجهزتك بتشفير Zero-Knowledge';

  @override
  String get getStarted => 'ابدأ التسجيل';

  @override
  String get learnAndEarnPoints => 'تعلّم وأكسب نقاطاً';

  @override
  String get openVault => 'فتح الخزنة 🔓';

  @override
  String get enterVault => 'ادخل إلى خزنتك 🔓';

  @override
  String get createUnbreakablePasswords => 'اصنع كلمات مرور غير قابلة للكسر';

  @override
  String get masterPassword => 'كلمة المرور الرئيسية';

  @override
  String get enterMasterPassword => 'أدخل كلمة المرور الرئيسية';

  @override
  String get verificationCode2FA => 'رمز التحقق (2FA)';

  @override
  String get biometricPrompt => 'استخدم بصمة الوجه أو البصمة للدخول';

  @override
  String get setupMasterPassword => 'إعداد كلمة المرور الرئيسية';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordTooShort => 'كلمة المرور قصيرة جداً (12 حرفاً على الأقل)';

  @override
  String get vaultTitle => 'الخزنة';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get editItem => 'تعديل العنصر';

  @override
  String get itemDetails => 'تفاصيل الحساب';

  @override
  String get category => 'الفئة';

  @override
  String get copyPassword => 'نسخ كلمة المرور';

  @override
  String get passwordCopied => 'تم نسخ كلمة المرور ✓';

  @override
  String get passwordCopiedWillClear =>
      'تم نسخ كلمة المرور — تمسح خلال 30 ثانية';

  @override
  String get deleteAccount => 'حذف الحساب؟';

  @override
  String get deleteAllData => 'حذف كل البيانات؟';

  @override
  String get deletePermanently => 'حذف نهائياً';

  @override
  String get deleteAccountWarning =>
      'سيتم حذف جميع بياناتك نهائياً بدون إمكانية الاسترداد.';

  @override
  String get irreversibleAction => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get generatorTitle => 'مولّد كلمات المرور';

  @override
  String get generateStrongPassword => 'توليد كلمة مرور قوية';

  @override
  String get length => 'الطول';

  @override
  String get wordCount => 'عدد الكلمات';

  @override
  String get recommendations => 'التوصيات';

  @override
  String get securityCenter => 'مركز الأمان';

  @override
  String get overallSecurityScore => 'درجة الأمان الكلية';

  @override
  String get securityInfo => 'معلومات الأمان';

  @override
  String get faceTrackSetup => 'إعداد Face-Track';

  @override
  String get faceTrackActive =>
      'Face-Track أصبح يعمل الآن.\nستُقفل الخزنة تلقائياً إذا ابتعدت.';

  @override
  String get faceTrackHowItWorks => 'كيف يعمل Face-Track؟';

  @override
  String get placeFaceInCircle => 'ضع وجهك داخل الدائرة وانظر مباشرة للشاشة';

  @override
  String get capture => 'التقاط';

  @override
  String captureProgress(int current, int total) {
    return 'التقاط $current / $total';
  }

  @override
  String get faceSavedSuccess => 'تم تسجيل وجهك بنجاح!';

  @override
  String get autoLockTimeout => 'مهلة القفل التلقائي';

  @override
  String minuteUnit(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get academyTitle => 'أكاديمية التهديدات';

  @override
  String get sharingTitle => 'المشاركة الآمنة';

  @override
  String get activeLinks => 'الروابط النشطة';

  @override
  String get createSecureLink => 'إنشاء رابط آمن';

  @override
  String get createShareLink => 'إنشاء رابط مشاركة';

  @override
  String get linkCreated => 'تم إنشاء الرابط';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get linkCopied => 'تم النسخ';

  @override
  String get expiryDuration => 'مدة الصلاحية';

  @override
  String get enterpriseTitle => 'وضع المؤسسة';

  @override
  String get enterpriseFeatures => 'الميزات المؤسسية';

  @override
  String get enterpriseProtection => 'حماية شاملة لفرق العمل والمؤسسات';

  @override
  String get enterprisePricing => 'تواصل معنا للحصول على سعر مخصص للمؤسسات';

  @override
  String get contactSales => 'تواصل مع فريق المبيعات';

  @override
  String get teamSize => 'كم موظفاً في فريقك؟';

  @override
  String get enterpriseMode => 'وضع المؤسسة';

  @override
  String get proBadge => 'PRO';

  @override
  String gotItXP(int xp) {
    return 'فهمت! (+$xp XP)';
  }

  @override
  String earnedXP(int xp) {
    return '+$xp XP';
  }

  @override
  String get scoreOutOf100 => '/ 100';

  @override
  String get cipherowlEnterprise => 'CipherOwl Enterprise';

  @override
  String get cipherowlSecurity => 'CipherOwl Security';
}
