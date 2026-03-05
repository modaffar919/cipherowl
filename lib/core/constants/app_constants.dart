import 'package:flutter/material.dart';

/// Central constants for CipherOwl
abstract class AppConstants {
  // ── App Info ────────────────────────────────────────────
  static const String appName = 'CipherOwl';
  static const String appTaglineAr = 'حارسك الرقمي';
  static const String appTaglineEn = 'Your Digital Guardian';
  static const String appVersion = '1.0.0';
  static const String appBundleId = 'com.cipherowl.app';

  // ── Supabase (replace with real values) ─────────────────
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  // ── Brand Colors ─────────────────────────────────────────
  static const Color backgroundDark   = Color(0xFF0A0E17);
  static const Color surfaceDark      = Color(0xFF141824);
  static const Color cardDark         = Color(0xFF1E2438);
  static const Color borderDark       = Color(0xFF2A3250);
  static const Color primaryCyan      = Color(0xFF00E5FF);
  static const Color primaryCyanLight = Color(0xFF4FF8FF);
  static const Color primaryCyanDark  = Color(0xFF00B8D4);
  static const Color accentGold       = Color(0xFFFFD700);
  static const Color accentGoldDark   = Color(0xFFFFA000);
  static const Color silver           = Color(0xFFB0BEC5);
  static const Color errorRed         = Color(0xFFFF3D57);
  static const Color successGreen     = Color(0xFF00E676);
  static const Color warningAmber     = Color(0xFFFFAB00);

  // ── Security Score Colors ─────────────────────────────────
  static const Color scoreExcellent = Color(0xFF00E676); // 80-100
  static const Color scoreGood      = Color(0xFF76FF03); // 60-79
  static const Color scoreMedium    = Color(0xFFFFAB00); // 40-59
  static const Color scoreWeak      = Color(0xFFFF6D00); // 20-39
  static const Color scoreCritical  = Color(0xFFFF3D57); // 0-19

  // ── Typography ──────────────────────────────────────────
  static const String fontFamilyAr = 'Cairo';
  static const String fontFamilyEn = 'SpaceMono';

  // ── Vault Item Templates ─────────────────────────────────
  static const List<String> vaultTemplates = [
    'web_account',
    'bank_card',
    'identity',
    'secure_note',
    'api_key',
    'wifi',
    'software_license',
  ];

  // ── Security Layers (for Security Center) ────────────────
  static const List<String> securityLayers = [
    'master_password',
    'face_biometric',
    'fido2_key',
    'face_track',
    'duress_password',
    'intruder_snapshot',
    'encryption',
    'recovery',
  ];

  // ── Security Score Weights ────────────────────────────────
  static const Map<String, int> securityLayerWeights = {
    'master_password':    20,
    'face_biometric':     15,
    'fido2_key':          15,
    'face_track':         10,
    'duress_password':    10,
    'intruder_snapshot':  5,
    'encryption':         15,  // always active
    'recovery':           10,
  };

  // ── Timeouts ─────────────────────────────────────────────
  static const Duration clipboardClearDelay = Duration(seconds: 30);
  static const Duration inactivityLockDelay = Duration(minutes: 5);
  static const Duration faceLockDetectInterval = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 4);

  // ── Crypto Parameters ────────────────────────────────────
  static const int argon2Iterations  = 3;
  static const int argon2Memory      = 65536; // 64 MB in KB
  static const int argon2Parallelism = 4;
  static const int pbkdf2Iterations  = 600000;
  static const int mekSizeBytes      = 32; // 256-bit MEK
  static const int saltSizeBytes     = 16;
  static const int nonceSizeBytes    = 12;

  // ── Gamification ─────────────────────────────────────────
  static const Map<String, int> xpRewards = {
    'create_strong_password':   10,
    'replace_weak_password':    15,
    'enable_2fa':               25,
    'complete_quiz':            20,
    'daily_checkin':            5,
    'secure_share':             10,
    'fix_breach':               30,
    'enable_face_track':        25,
    'register_fido2':           30,
    'save_recovery_key':        20,
    'import_passwords':         50,
    'zero_reuse_bonus':         50,
    'finish_threat_academy':    40,
  };

  static const Map<int, String> levelTitles = {
    1:  'Novice',
    11: 'Guardian',
    21: 'Sentinel',
    31: 'Cryptographer',
    41: 'Vault Master',
    49: 'Legendary',
  };

  static const Map<int, String> levelTitlesAr = {
    1:  'مبتدئ',
    11: 'حارس',
    21: 'حارس أمن',
    31: 'مشفّر',
    41: 'سيد الخزنة',
    49: 'أسطوري',
  };

  // ── Routes ─────────────────────────────────────────────
  static const String routeSplash        = '/';
  static const String routeOnboarding    = '/onboarding';
  static const String routeSetup         = '/setup';
  static const String routeLock          = '/lock';
  static const String routeDashboard     = '/dashboard';
  static const String routeVaultList     = '/vault';
  static const String routeVaultDetail   = '/vault/:id';
  static const String routeAddItem       = '/vault/add';
  static const String routeEditItem      = '/vault/edit/:id';
  static const String routeGenerator     = '/generator';
  static const String routeSecurityCenter= '/security-center';
  static const String routeAcademy       = '/academy';
  static const String routeSettings      = '/settings';
  static const String routeFaceSetup     = '/face-setup';
  static const String routeRecoverySetup = '/recovery-setup';
  static const String routeSharing       = '/sharing';
  static const String routeEnterprise    = '/enterprise';
  static const String routeImportExport  = '/import-export';
  static const String routeFido2Manage   = '/fido2-manage';
}
