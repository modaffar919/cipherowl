part of 'gamification_bloc.dart';

abstract class GamificationEvent {
  const GamificationEvent();
}

/// Load saved gamification data from storage on startup.
class GamificationStarted extends GamificationEvent {
  const GamificationStarted();
}

/// Award XP points for a user action (e.g. adding a strong password).
class GamificationXpEarned extends GamificationEvent {
  final int amount;

  /// Short Arabic description of the reason (shown in feed).
  final String reason;
  const GamificationXpEarned({required this.amount, required this.reason});
}

/// Unlock a badge by id.
class GamificationBadgeUnlocked extends GamificationEvent {
  final String badgeId;
  const GamificationBadgeUnlocked(this.badgeId);
}

/// Called daily (or on app resume) to handle streak logic.
class GamificationDailyCheckIn extends GamificationEvent {
  const GamificationDailyCheckIn();
}

/// Reset all gamification data (used for testing or account wipe).
class GamificationReset extends GamificationEvent {
  const GamificationReset();
}
