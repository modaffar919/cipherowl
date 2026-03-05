part of 'security_bloc.dart';

abstract class SecurityState {
  const SecurityState();
}

class SecurityInitial extends SecurityState {
  const SecurityInitial();
}

class SecurityCalculating extends SecurityState {
  const SecurityCalculating();
}

/// Fully calculated security state ready for the UI.
class SecurityLoaded extends SecurityState {
  /// Overall score 0-100.
  final int score;

  /// Arabic grade label.
  final String grade;

  /// Hex colour matching the grade.
  final int gradeColor;

  /// Individual security layers (name, max, earned).
  final List<SecurityLayer> layers;

  /// Prioritised action recommendations.
  final List<SecurityRecommendation> recommendations;

  /// Number of weak passwords (strengthScore <= 1).
  final int weakPasswordCount;

  /// Number of items without TOTP.
  final int noTotpCount;

  /// Number of items not updated in 90+ days.
  final int stalePasswordCount;

  /// IDs of recommendations the user has already completed this session.
  final Set<String> completedRecommendationIds;

  /// Cumulative XP earned from completing recommendations this session.
  final int sessionXpEarned;

  const SecurityLoaded({
    required this.score,
    required this.grade,
    required this.gradeColor,
    required this.layers,
    required this.recommendations,
    required this.weakPasswordCount,
    required this.noTotpCount,
    required this.stalePasswordCount,
    this.completedRecommendationIds = const {},
    this.sessionXpEarned = 0,
  });

  /// Returns a copy of this state with [recommendationId] removed and XP added.
  SecurityLoaded withCompleted(String recommendationId, int xp) {
    final newCompleted = {...completedRecommendationIds, recommendationId};
    final newRecs = recommendations
        .where((r) => !newCompleted.contains(r.id))
        .toList();
    return SecurityLoaded(
      score: score,
      grade: grade,
      gradeColor: gradeColor,
      layers: layers,
      recommendations: newRecs,
      weakPasswordCount: weakPasswordCount,
      noTotpCount: noTotpCount,
      stalePasswordCount: stalePasswordCount,
      completedRecommendationIds: newCompleted,
      sessionXpEarned: sessionXpEarned + xp,
    );
  }
}

/// One security ring / layer in the shield visualisation.
class SecurityLayer {
  final String nameAr;
  final int maxPoints;
  final int earnedPoints;
  final int iconCodePoint; // Icons.xxx.codePoint

  const SecurityLayer({
    required this.nameAr,
    required this.maxPoints,
    required this.earnedPoints,
    required this.iconCodePoint,
  });

  double get ratio => maxPoints == 0 ? 1.0 : earnedPoints / maxPoints;
}

/// A single actionable recommendation card.
class SecurityRecommendation {
  /// Stable identifier used to track completions (e.g. 'weak_passwords').
  final String id;
  final String titleAr;
  final String bodyAr;
  final int xpReward;
  final int iconCodePoint;
  final int colorValue;

  const SecurityRecommendation({
    required this.id,
    required this.titleAr,
    required this.bodyAr,
    required this.xpReward,
    required this.iconCodePoint,
    required this.colorValue,
  });
}
