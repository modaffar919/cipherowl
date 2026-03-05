part of 'gamification_bloc.dart';

// ── Badge model ────────────────────────────────────────────────────────────────

/// One of the 25 gamification badges.
class GamificationBadge {
  final String id;

  /// Arabic display name.
  final String nameAr;

  /// Arabic description of how to earn it.
  final String descriptionAr;

  /// Flutter icon code point (Icons.xxx.codePoint).
  final int iconCodePoint;

  /// Color value (0xAARRGGBB).
  final int colorValue;

  /// Whether the user has unlocked this badge.
  final bool isUnlocked;

  const GamificationBadge({
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.iconCodePoint,
    required this.colorValue,
    this.isUnlocked = false,
  });

  GamificationBadge copyWith({bool? isUnlocked}) => GamificationBadge(
        id: id,
        nameAr: nameAr,
        descriptionAr: descriptionAr,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );
}

// ── States ─────────────────────────────────────────────────────────────────────

abstract class GamificationState {
  const GamificationState();
}

/// Before data is loaded.
class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

/// Fully loaded and ready.
class GamificationLoaded extends GamificationState {
  /// Total XP accumulated.
  final int xp;

  /// Current level (1–50).
  final int level;

  /// XP needed to reach the next level.
  final int xpToNextLevel;

  /// Progress toward next level (0.0–1.0).
  final double levelProgress;

  /// All 25 badges with their unlock state.
  final List<GamificationBadge> badges;

  /// Consecutive daily check-in streak.
  final int streak;

  /// Whether today's daily challenge is completed.
  final bool dailyChallengeCompleted;

  /// Last check-in date (used for streak calc).
  final DateTime? lastCheckIn;

  const GamificationLoaded({
    required this.xp,
    required this.level,
    required this.xpToNextLevel,
    required this.levelProgress,
    required this.badges,
    required this.streak,
    required this.dailyChallengeCompleted,
    this.lastCheckIn,
  });

  /// Unlocked badge count.
  int get unlockedCount => badges.where((b) => b.isUnlocked).length;

  GamificationLoaded copyWith({
    int? xp,
    int? level,
    int? xpToNextLevel,
    double? levelProgress,
    List<GamificationBadge>? badges,
    int? streak,
    bool? dailyChallengeCompleted,
    DateTime? lastCheckIn,
  }) =>
      GamificationLoaded(
        xp: xp ?? this.xp,
        level: level ?? this.level,
        xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
        levelProgress: levelProgress ?? this.levelProgress,
        badges: badges ?? this.badges,
        streak: streak ?? this.streak,
        dailyChallengeCompleted:
            dailyChallengeCompleted ?? this.dailyChallengeCompleted,
        lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      );
}
