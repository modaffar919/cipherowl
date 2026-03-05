part of 'security_bloc.dart';

abstract class SecurityEvent {
  const SecurityEvent();
}

/// Compute score and recommendations from the current vault items.
class SecurityScoreRequested extends SecurityEvent {
  final List<VaultEntry> items;
  const SecurityScoreRequested(this.items);
}

/// Refresh score whenever vault changes (called from VaultBloc listener).
class SecurityVaultUpdated extends SecurityEvent {
  final List<VaultEntry> items;
  const SecurityVaultUpdated(this.items);
}

/// Mark a recommendation as completed and award [xpReward] points.
///
/// The SecurityBloc removes the recommendation from its list and increments
/// [SecurityLoaded.sessionXpEarned]. The UI should then dispatch
/// [GamificationXpEarned] to the GamificationBloc with the returned XP.
class SecurityRecommendationCompleted extends SecurityEvent {
  final String recommendationId;
  final int xpReward;
  const SecurityRecommendationCompleted({
    required this.recommendationId,
    required this.xpReward,
  });
}
