// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CipherOwl';

  @override
  String get appTagline => 'Your Digital Guardian';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get skipNow => 'Skip for Now';

  @override
  String get later => 'Later';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get copy => 'Copy';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get copiedSuccess => 'Copied ✓';

  @override
  String get savedSecurely => 'Saved securely ✓';

  @override
  String get excellent => 'Excellent! ✓';

  @override
  String get pageNotFound => '404 - Page not found';

  @override
  String get onboardingTitle1 => 'Military-Grade Protection';

  @override
  String get onboardingDesc1 =>
      'AES-256-GCM military encryption protects all your data';

  @override
  String get onboardingTitle2 => 'Continuous Face-Track AI';

  @override
  String get onboardingDesc2 =>
      'Continuous biometric monitoring locks your vault when you walk away';

  @override
  String get onboardingTitle3 => 'Protected Everywhere';

  @override
  String get onboardingDesc3 =>
      'Secure sync across your devices with Zero-Knowledge encryption';

  @override
  String get getStarted => 'Get Started';

  @override
  String get learnAndEarnPoints => 'Learn & Earn Points';

  @override
  String get openVault => 'Open Vault 🔓';

  @override
  String get enterVault => 'Enter Your Vault 🔓';

  @override
  String get createUnbreakablePasswords => 'Create unbreakable passwords';

  @override
  String get masterPassword => 'Master Password';

  @override
  String get enterMasterPassword => 'Enter master password';

  @override
  String get verificationCode2FA => 'Verification Code (2FA)';

  @override
  String get biometricPrompt => 'Use face or fingerprint to unlock';

  @override
  String get setupMasterPassword => 'Set Up Master Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password too short (12 chars minimum)';

  @override
  String get vaultTitle => 'Vault';

  @override
  String get addItem => 'Add Item';

  @override
  String get editItem => 'Edit Item';

  @override
  String get itemDetails => 'Account Details';

  @override
  String get category => 'Category';

  @override
  String get copyPassword => 'Copy Password';

  @override
  String get passwordCopied => 'Password copied ✓';

  @override
  String get passwordCopiedWillClear =>
      'Password copied — clears in 30 seconds';

  @override
  String get deleteAccount => 'Delete Account?';

  @override
  String get deleteAllData => 'Delete All Data?';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get deleteAccountWarning =>
      'All your data will be permanently deleted with no possibility of recovery.';

  @override
  String get irreversibleAction => 'This action cannot be undone.';

  @override
  String get generatorTitle => 'Password Generator';

  @override
  String get generateStrongPassword => 'Generate Strong Password';

  @override
  String get length => 'Length';

  @override
  String get wordCount => 'Word Count';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get securityCenter => 'Security Center';

  @override
  String get overallSecurityScore => 'Overall Security Score';

  @override
  String get securityInfo => 'Security Info';

  @override
  String get faceTrackSetup => 'Set Up Face-Track';

  @override
  String get faceTrackActive =>
      'Face-Track is now active.\nVault will lock automatically if you walk away.';

  @override
  String get faceTrackHowItWorks => 'How does Face-Track work?';

  @override
  String get placeFaceInCircle =>
      'Place your face inside the circle and look directly at the screen';

  @override
  String get capture => 'Capture';

  @override
  String captureProgress(int current, int total) {
    return 'Capture $current / $total';
  }

  @override
  String get faceSavedSuccess => 'Your face was registered successfully!';

  @override
  String get autoLockTimeout => 'Auto-Lock Timeout';

  @override
  String minuteUnit(int minutes) {
    return '$minutes min';
  }

  @override
  String get settings => 'Settings';

  @override
  String get academyTitle => 'Threat Academy';

  @override
  String get sharingTitle => 'Secure Sharing';

  @override
  String get activeLinks => 'Active Links';

  @override
  String get createSecureLink => 'Create Secure Link';

  @override
  String get createShareLink => 'Create Share Link';

  @override
  String get linkCreated => 'Link Created';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get linkCopied => 'Copied';

  @override
  String get expiryDuration => 'Expiry Duration';

  @override
  String get enterpriseTitle => 'Enterprise Mode';

  @override
  String get enterpriseFeatures => 'Enterprise Features';

  @override
  String get enterpriseProtection =>
      'Comprehensive protection for teams and enterprises';

  @override
  String get enterprisePricing => 'Contact us for a custom enterprise price';

  @override
  String get contactSales => 'Contact Sales Team';

  @override
  String get teamSize => 'How many employees are on your team?';

  @override
  String get enterpriseMode => 'Enterprise Mode';

  @override
  String get proBadge => 'PRO';

  @override
  String gotItXP(int xp) {
    return 'Got it! (+$xp XP)';
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
