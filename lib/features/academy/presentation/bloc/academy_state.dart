part of 'academy_bloc.dart';

/// Quiz progress for a single module.
class QuizProgress {
  /// Selected choice per question index (null = not yet answered).
  final Map<int, int> answers;
  final bool submitted;

  const QuizProgress({this.answers = const {}, this.submitted = false});

  QuizProgress copyWith({Map<int, int>? answers, bool? submitted}) =>
      QuizProgress(
        answers: answers ?? this.answers,
        submitted: submitted ?? this.submitted,
      );

  int correctCount(List<dynamic> questions) => answers.entries
      .where((e) => e.value == (questions[e.key] as dynamic).correctIndex)
      .length;
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class AcademyState {
  const AcademyState();
}

class AcademyInitial extends AcademyState {
  const AcademyInitial();
}

class AcademyLoaded extends AcademyState {
  /// Set of module IDs the user has completed.
  final Set<String> completedModuleIds;

  /// Quiz progress keyed by module ID.
  final Map<String, QuizProgress> quizProgress;

  /// ID of the module currently being studied (null = overview).
  final String? activeModuleId;

  /// Whether today's daily challenge has been answered.
  final bool dailyChallengeAnswered;

  /// The user's answer for today's challenge (null = not answered yet).
  final int? dailyChallengeAnswer;

  const AcademyLoaded({
    this.completedModuleIds = const {},
    this.quizProgress = const {},
    this.activeModuleId,
    this.dailyChallengeAnswered = false,
    this.dailyChallengeAnswer,
  });

  int get completedCount => completedModuleIds.length;
  bool isCompleted(String moduleId) => completedModuleIds.contains(moduleId);

  QuizProgress progressFor(String moduleId) =>
      quizProgress[moduleId] ?? const QuizProgress();

  AcademyLoaded copyWith({
    Set<String>? completedModuleIds,
    Map<String, QuizProgress>? quizProgress,
    String? activeModuleId,
    bool? dailyChallengeAnswered,
    int? dailyChallengeAnswer,
    bool clearActiveModule = false,
  }) =>
      AcademyLoaded(
        completedModuleIds: completedModuleIds ?? this.completedModuleIds,
        quizProgress: quizProgress ?? this.quizProgress,
        activeModuleId:
            clearActiveModule ? null : (activeModuleId ?? this.activeModuleId),
        dailyChallengeAnswered:
            dailyChallengeAnswered ?? this.dailyChallengeAnswered,
        dailyChallengeAnswer: dailyChallengeAnswer ?? this.dailyChallengeAnswer,
      );
}
