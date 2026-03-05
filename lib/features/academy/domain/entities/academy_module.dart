import 'package:equatable/equatable.dart';

// ── Quiz Question ─────────────────────────────────────────────────────────────

/// A single multiple-choice question for an academy module quiz.
class QuizQuestion extends Equatable {
  final String questionAr;
  final String questionEn;
  /// Four answer choices (Arabic).
  final List<String> choicesAr;
  /// Index of the correct answer in [choicesAr].
  final int correctIndex;
  /// Brief Arabic explanation shown after answering.
  final String explanationAr;

  const QuizQuestion({
    required this.questionAr,
    required this.questionEn,
    required this.choicesAr,
    required this.correctIndex,
    required this.explanationAr,
  });

  @override
  List<Object?> get props =>
      [questionAr, choicesAr, correctIndex];
}

// ── Academy Module ────────────────────────────────────────────────────────────

/// One of the 10 security-education modules in the academy.
class AcademyModule extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final String emoji;
  final String summaryAr;
  /// Full Arabic lesson content (can be multi-paragraph).
  final String bodyAr;
  /// XP awarded on first completion.
  final int xpReward;
  final int colorValue;
  /// Optional badge id unlocked on quiz completion.
  final String? badgeId;
  final List<QuizQuestion> quiz;

  const AcademyModule({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.emoji,
    required this.summaryAr,
    required this.bodyAr,
    required this.xpReward,
    required this.colorValue,
    this.badgeId,
    this.quiz = const [],
  });

  @override
  List<Object?> get props => [id];
}

// ── Daily Challenge ───────────────────────────────────────────────────────────

/// A daily security quiz challenge (one question + explanation).
class DailyChallenge extends Equatable {
  final String id;
  final String titleAr;
  final String questionAr;
  final List<String> choicesAr;
  final int correctIndex;
  final String explanationAr;
  final int xpReward;
  final DateTime date;

  const DailyChallenge({
    required this.id,
    required this.titleAr,
    required this.questionAr,
    required this.choicesAr,
    required this.correctIndex,
    required this.explanationAr,
    required this.xpReward,
    required this.date,
  });

  @override
  List<Object?> get props => [id, date];
}
