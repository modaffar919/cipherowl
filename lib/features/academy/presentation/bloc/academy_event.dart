part of 'academy_bloc.dart';

abstract class AcademyEvent {
  const AcademyEvent();
}

/// Load academy state (completed ids) from persistent storage.
class AcademyStarted extends AcademyEvent {
  const AcademyStarted();
}

/// User opened a module to study.
class AcademyModuleOpened extends AcademyEvent {
  final String moduleId;
  const AcademyModuleOpened(this.moduleId);
}

/// User submitted an answer to question [questionIndex].
class AcademyQuizAnswered extends AcademyEvent {
  final int questionIndex;
  final int selectedChoice;
  const AcademyQuizAnswered({
    required this.questionIndex,
    required this.selectedChoice,
  });
}

/// User finished the quiz for a module.
class AcademyModuleCompleted extends AcademyEvent {
  final String moduleId;
  const AcademyModuleCompleted(this.moduleId);
}

/// User opened the daily challenge.
class AcademyDailyChallengeOpened extends AcademyEvent {
  const AcademyDailyChallengeOpened();
}

/// User answered today's daily challenge.
class AcademyDailyChallengeAnswered extends AcademyEvent {
  final int selectedChoice;
  const AcademyDailyChallengeAnswered(this.selectedChoice);
}
