import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

part 'gamification_event.dart';
part 'gamification_state.dart';

/// BLoC that drives CipherOwl's security gamification system.
///
/// ## XP & Levels
/// Level is derived from accumulated XP:
/// ```
///   level = floor(sqrt(xp / 100)).clamp(1, 50)
/// ```
/// Level 1 starts at 0 XP; Level 50 is reached at 245,000 XP.
///
/// ## Badges (25 total)
/// Badges are unlocked automatically when certain XP thresholds are crossed
/// or via explicit [GamificationBadgeUnlocked] events.
///
/// ## Daily Streak
/// [GamificationDailyCheckIn] fires on each app open. If the last check-in
/// was exactly yesterday the streak increments; if more than one day has
/// passed the streak resets to 1.
class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  // ── XP thresholds for badge auto-unlock ────────────────────────────────────
  static const Map<String, int> _badgeXpThresholds = {
    'badge_first_password': 10,
    'badge_level_5': 2500,
    'badge_level_10': 10000,
    'badge_level_20': 40000,
    'badge_xp_1k': 1000,
    'badge_xp_5k': 5000,
    'badge_xp_10k': 10000,
    'badge_streak_3': -1, // streak-based, not XP-based
    'badge_streak_7': -1,
    'badge_streak_30': -1,
  };

  GamificationBloc() : super(const GamificationInitial()) {
    on<GamificationStarted>(_onStarted);
    on<GamificationXpEarned>(_onXpEarned);
    on<GamificationBadgeUnlocked>(_onBadgeUnlocked);
    on<GamificationDailyCheckIn>(_onDailyCheckIn);
    on<GamificationReset>(_onReset);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _onStarted(GamificationStarted event, Emitter<GamificationState> emit) {
    // In production this would load from SettingsDao / SharedPreferences.
    // For now initialise a fresh default state.
    emit(_buildState(xp: 0, streak: 0, lastCheckIn: null, unlockedIds: {}));
  }

  void _onXpEarned(
      GamificationXpEarned event, Emitter<GamificationState> emit) {
    if (state is! GamificationLoaded) return;
    final current = state as GamificationLoaded;
    final newXp = current.xp + event.amount.clamp(1, 10000);
    final unlockedIds = _currentUnlockedIds(current);
    // Auto-unlock XP-threshold badges
    for (final entry in _badgeXpThresholds.entries) {
      if (entry.value > 0 && newXp >= entry.value) {
        unlockedIds.add(entry.key);
      }
    }
    emit(_buildState(
      xp: newXp,
      streak: current.streak,
      lastCheckIn: current.lastCheckIn,
      unlockedIds: unlockedIds,
    ));
  }

  void _onBadgeUnlocked(
      GamificationBadgeUnlocked event, Emitter<GamificationState> emit) {
    if (state is! GamificationLoaded) return;
    final current = state as GamificationLoaded;
    final unlockedIds = _currentUnlockedIds(current)..add(event.badgeId);
    emit(_buildState(
      xp: current.xp,
      streak: current.streak,
      lastCheckIn: current.lastCheckIn,
      unlockedIds: unlockedIds,
    ));
  }

  void _onDailyCheckIn(
      GamificationDailyCheckIn event, Emitter<GamificationState> emit) {
    if (state is! GamificationLoaded) return;
    final current = state as GamificationLoaded;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckIn = current.lastCheckIn;

    int newStreak;
    bool challenged = false;

    if (lastCheckIn == null) {
      // First ever check-in
      newStreak = 1;
      challenged = true;
    } else {
      final lastDay = DateTime(
          lastCheckIn.year, lastCheckIn.month, lastCheckIn.day);
      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        // Already checked in today — no change
        return;
      } else if (diff == 1) {
        // Consecutive day — extend streak
        newStreak = current.streak + 1;
        challenged = true;
      } else {
        // Missed a day — reset
        newStreak = 1;
        challenged = true;
      }
    }

    // Unlock streak badges
    final unlockedIds = _currentUnlockedIds(current);
    if (newStreak >= 3) unlockedIds.add('badge_streak_3');
    if (newStreak >= 7) unlockedIds.add('badge_streak_7');
    if (newStreak >= 30) unlockedIds.add('badge_streak_30');

    // Award XP for check-in (10 XP base + streak bonus)
    final bonusXp = math.min(newStreak * 5, 50);
    final newXp = current.xp + 10 + bonusXp;

    // Auto-unlock XP-threshold badges
    for (final entry in _badgeXpThresholds.entries) {
      if (entry.value > 0 && newXp >= entry.value) {
        unlockedIds.add(entry.key);
      }
    }

    emit(_buildState(
      xp: newXp,
      streak: newStreak,
      lastCheckIn: now,
      unlockedIds: unlockedIds,
      dailyChallengeCompleted: challenged,
    ));
  }

  void _onReset(GamificationReset event, Emitter<GamificationState> emit) {
    emit(_buildState(xp: 0, streak: 0, lastCheckIn: null, unlockedIds: {}));
  }

  // ── Level calculation ──────────────────────────────────────────────────────

  /// Computes level (1–50) from accumulated XP.
  /// Formula: level = floor(sqrt(xp / 100)).clamp(1, 50)
  static int _levelFromXp(int xp) =>
      math.sqrt(xp / 100).floor().clamp(1, 50);

  /// XP needed to reach *next* level.
  static int _xpForNextLevel(int level) {
    if (level >= 50) return 0;
    final nextLevel = level + 1;
    return (nextLevel * nextLevel * 100);
  }

  /// XP threshold at which the *current* level was reached.
  static int _xpForLevel(int level) => level * level * 100;

  static double _progress(int xp, int level) {
    if (level >= 50) return 1.0;
    final start = _xpForLevel(level);
    final end = _xpForLevel(level + 1);
    if (end <= start) return 1.0;
    return ((xp - start) / (end - start)).clamp(0.0, 1.0);
  }

  // ── State builder ──────────────────────────────────────────────────────────

  GamificationLoaded _buildState({
    required int xp,
    required int streak,
    required DateTime? lastCheckIn,
    required Set<String> unlockedIds,
    bool dailyChallengeCompleted = false,
  }) {
    final level = _levelFromXp(xp).clamp(1, 50);
    return GamificationLoaded(
      xp: xp,
      level: level,
      xpToNextLevel: _xpForNextLevel(level),
      levelProgress: _progress(xp, level),
      badges: _allBadges(unlockedIds),
      streak: streak,
      dailyChallengeCompleted: dailyChallengeCompleted,
      lastCheckIn: lastCheckIn,
    );
  }

  static Set<String> _currentUnlockedIds(GamificationLoaded state) =>
      state.badges
          .where((b) => b.isUnlocked)
          .map((b) => b.id)
          .toSet();

  // ── Badge catalogue (25 badges) ────────────────────────────────────────────

  static List<GamificationBadge> _allBadges(Set<String> unlockedIds) => [
        // ── Onboarding group ──────────────────────────────────────────────
        GamificationBadge(
          id: 'badge_first_password',
          nameAr: 'كلمة المرور الأولى',
          descriptionAr: 'أضف أول كلمة مرور إلى الخزنة',
          iconCodePoint: Icons.lock.codePoint,
          colorValue: AppConstants.primaryCyan.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_first_password'),
        ),
        GamificationBadge(
          id: 'badge_setup_complete',
          nameAr: 'البداية الآمنة',
          descriptionAr: 'أكمل إعداد CipherOwl كاملاً',
          iconCodePoint: Icons.verified_user.codePoint,
          colorValue: AppConstants.successGreen.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_setup_complete'),
        ),
        GamificationBadge(
          id: 'badge_biometric',
          nameAr: 'الحارس البيومتري',
          descriptionAr: 'فعّل المصادقة البيومترية',
          iconCodePoint: Icons.fingerprint.codePoint,
          colorValue: 0xFF9C27B0,
          isUnlocked: unlockedIds.contains('badge_biometric'),
        ),
        // ── Security group ────────────────────────────────────────────────
        GamificationBadge(
          id: 'badge_totp_first',
          nameAr: 'حماية مزدوجة',
          descriptionAr: 'أضف أول رمز TOTP',
          iconCodePoint: Icons.security.codePoint,
          colorValue: AppConstants.warningAmber.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_totp_first'),
        ),
        GamificationBadge(
          id: 'badge_score_80',
          nameAr: 'درجة ممتازة',
          descriptionAr: 'حقق نقاط أمان ≥ 80',
          iconCodePoint: Icons.shield.codePoint,
          colorValue: AppConstants.successGreen.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_score_80'),
        ),
        GamificationBadge(
          id: 'badge_score_100',
          nameAr: 'درع منيع',
          descriptionAr: 'حقق نقاط أمان 100/100',
          iconCodePoint: Icons.shield_outlined.codePoint,
          colorValue: 0xFFFFD700,
          isUnlocked: unlockedIds.contains('badge_score_100'),
        ),
        GamificationBadge(
          id: 'badge_strong_10',
          nameAr: 'ذخيرة آمنة',
          descriptionAr: 'أضف 10 كلمات مرور قوية',
          iconCodePoint: Icons.lock_outline.codePoint,
          colorValue: AppConstants.primaryCyan.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_strong_10'),
        ),
        GamificationBadge(
          id: 'badge_no_weak',
          nameAr: 'لا نقاط ضعف',
          descriptionAr: 'أزل جميع كلمات المرور الضعيفة',
          iconCodePoint: Icons.block.codePoint,
          colorValue: AppConstants.errorRed.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_no_weak'),
        ),
        // ── Vault group ───────────────────────────────────────────────────
        GamificationBadge(
          id: 'badge_vault_5',
          nameAr: 'مجموعة صغيرة',
          descriptionAr: 'أضف 5 عناصر للخزنة',
          iconCodePoint: Icons.folder.codePoint,
          colorValue: 0xFF2196F3,
          isUnlocked: unlockedIds.contains('badge_vault_5'),
        ),
        GamificationBadge(
          id: 'badge_vault_25',
          nameAr: 'خزنة نشطة',
          descriptionAr: 'أضف 25 عنصراً للخزنة',
          iconCodePoint: Icons.folder_open.codePoint,
          colorValue: 0xFF2196F3,
          isUnlocked: unlockedIds.contains('badge_vault_25'),
        ),
        GamificationBadge(
          id: 'badge_vault_100',
          nameAr: 'خزنة ضخمة',
          descriptionAr: 'أضف 100 عنصر للخزنة',
          iconCodePoint: Icons.storage.codePoint,
          colorValue: 0xFFFFD700,
          isUnlocked: unlockedIds.contains('badge_vault_100'),
        ),
        // ── Streak group ──────────────────────────────────────────────────
        GamificationBadge(
          id: 'badge_streak_3',
          nameAr: 'ثلاثة أيام متوالية',
          descriptionAr: 'افتح التطبيق 3 أيام متتالية',
          iconCodePoint: Icons.local_fire_department.codePoint,
          colorValue: AppConstants.warningAmber.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_streak_3'),
        ),
        GamificationBadge(
          id: 'badge_streak_7',
          nameAr: 'أسبوع الأمان',
          descriptionAr: 'افتح التطبيق 7 أيام متتالية',
          iconCodePoint: Icons.local_fire_department.codePoint,
          colorValue: 0xFFFF5722,
          isUnlocked: unlockedIds.contains('badge_streak_7'),
        ),
        GamificationBadge(
          id: 'badge_streak_30',
          nameAr: 'شهر الحماية',
          descriptionAr: 'افتح التطبيق 30 يوماً متتالياً',
          iconCodePoint: Icons.whatshot.codePoint,
          colorValue: 0xFFFFD700,
          isUnlocked: unlockedIds.contains('badge_streak_30'),
        ),
        // ── XP milestones ─────────────────────────────────────────────────
        GamificationBadge(
          id: 'badge_xp_1k',
          nameAr: 'ألف نقطة',
          descriptionAr: 'اجمع 1,000 نقطة خبرة',
          iconCodePoint: Icons.star.codePoint,
          colorValue: 0xFF9C27B0,
          isUnlocked: unlockedIds.contains('badge_xp_1k'),
        ),
        GamificationBadge(
          id: 'badge_xp_5k',
          nameAr: 'خمسة آلاف نقطة',
          descriptionAr: 'اجمع 5,000 نقطة خبرة',
          iconCodePoint: Icons.star_half.codePoint,
          colorValue: 0xFFE91E63,
          isUnlocked: unlockedIds.contains('badge_xp_5k'),
        ),
        GamificationBadge(
          id: 'badge_xp_10k',
          nameAr: 'عشرة آلاف نقطة',
          descriptionAr: 'اجمع 10,000 نقطة خبرة',
          iconCodePoint: Icons.star_border.codePoint,
          colorValue: 0xFFFFD700,
          isUnlocked: unlockedIds.contains('badge_xp_10k'),
        ),
        // ── Level milestones ──────────────────────────────────────────────
        GamificationBadge(
          id: 'badge_level_5',
          nameAr: 'المستوى الخامس',
          descriptionAr: 'بلغ المستوى 5',
          iconCodePoint: Icons.military_tech.codePoint,
          colorValue: 0xFF607D8B,
          isUnlocked: unlockedIds.contains('badge_level_5'),
        ),
        GamificationBadge(
          id: 'badge_level_10',
          nameAr: 'المستوى العاشر',
          descriptionAr: 'بلغ المستوى 10',
          iconCodePoint: Icons.military_tech.codePoint,
          colorValue: 0xFF2196F3,
          isUnlocked: unlockedIds.contains('badge_level_10'),
        ),
        GamificationBadge(
          id: 'badge_level_20',
          nameAr: 'المستوى العشرون',
          descriptionAr: 'بلغ المستوى 20',
          iconCodePoint: Icons.workspace_premium.codePoint,
          colorValue: AppConstants.successGreen.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_level_20'),
        ),
        GamificationBadge(
          id: 'badge_level_50',
          nameAr: 'الأسطورة',
          descriptionAr: 'بلغ المستوى الأقصى 50',
          iconCodePoint: Icons.emoji_events.codePoint,
          colorValue: 0xFFFFD700,
          isUnlocked: unlockedIds.contains('badge_level_50'),
        ),
        // ── Feature usage ─────────────────────────────────────────────────
        GamificationBadge(
          id: 'badge_generator',
          nameAr: 'المولّد',
          descriptionAr: 'استخدم مولّد كلمات المرور 10 مرات',
          iconCodePoint: Icons.auto_awesome.codePoint,
          colorValue: AppConstants.primaryCyan.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_generator'),
        ),
        GamificationBadge(
          id: 'badge_share',
          nameAr: 'المشارك الآمن',
          descriptionAr: 'شارك عنصراً بشكل آمن',
          iconCodePoint: Icons.share.codePoint,
          colorValue: 0xFF9C27B0,
          isUnlocked: unlockedIds.contains('badge_share'),
        ),
        GamificationBadge(
          id: 'badge_dark_web',
          nameAr: 'حارس الشبكة المظلمة',
          descriptionAr: 'فعّل مراقبة الاختراقات لأول مرة',
          iconCodePoint: Icons.radar.codePoint,
          colorValue: AppConstants.errorRed.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_dark_web'),
        ),
        GamificationBadge(
          id: 'badge_academy',
          nameAr: 'المتعلم',
          descriptionAr: 'أتمم أول درس في أكاديمية الأمان',
          iconCodePoint: Icons.school.codePoint,
          colorValue: AppConstants.successGreen.toARGB32(),
          isUnlocked: unlockedIds.contains('badge_academy'),
        ),
      ];
}
