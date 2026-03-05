import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/academy_content.dart';
import '../../domain/entities/academy_module.dart';
import '../../../../features/gamification/presentation/bloc/gamification_bloc.dart';

part 'academy_event.dart';
part 'academy_state.dart';

class AcademyBloc extends Bloc<AcademyEvent, AcademyState> {
  final GamificationBloc _gamificationBloc;

  static const _kCompletedKey = 'academy_completed_modules_v1';
  static const _kDailyChallengeKey = 'academy_daily_challenge_date_v1';

  AcademyBloc({required GamificationBloc gamificationBloc})
      : _gamificationBloc = gamificationBloc,
        super(const AcademyInitial()) {
    on<AcademyStarted>(_onStarted);
    on<AcademyModuleOpened>(_onModuleOpened);
    on<AcademyQuizAnswered>(_onQuizAnswered);
    on<AcademyModuleCompleted>(_onModuleCompleted);
    on<AcademyDailyChallengeOpened>(_onDailyChallengeOpened);
    on<AcademyDailyChallengeAnswered>(_onDailyChallengeAnswered);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onStarted(
      AcademyStarted event, Emitter<AcademyState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList(_kCompletedKey) ?? [];
    final completedIds = completedList.toSet();

    // Check daily challenge — reset if it's a new day
    final savedDate = prefs.getString(_kDailyChallengeKey);
    final today = _todayKey();
    final dailyDone = savedDate == today;

    emit(AcademyLoaded(
      completedModuleIds: completedIds,
      dailyChallengeAnswered: dailyDone,
    ));
  }

  void _onModuleOpened(
      AcademyModuleOpened event, Emitter<AcademyState> emit) {
    if (state is! AcademyLoaded) return;
    emit((state as AcademyLoaded)
        .copyWith(activeModuleId: event.moduleId));
  }

  void _onQuizAnswered(
      AcademyQuizAnswered event, Emitter<AcademyState> emit) {
    if (state is! AcademyLoaded) return;
    final current = state as AcademyLoaded;
    final moduleId = current.activeModuleId;
    if (moduleId == null) return;

    final progress = current.progressFor(moduleId);
    final newAnswers = Map<int, int>.from(progress.answers)
      ..[event.questionIndex] = event.selectedChoice;
    final updated = progress.copyWith(answers: newAnswers);

    emit(current.copyWith(
      quizProgress: Map.from(current.quizProgress)..[moduleId] = updated,
    ));
  }

  Future<void> _onModuleCompleted(
      AcademyModuleCompleted event, Emitter<AcademyState> emit) async {
    if (state is! AcademyLoaded) return;
    final current = state as AcademyLoaded;

    // Only award XP/badge on *first* completion
    if (!current.completedModuleIds.contains(event.moduleId)) {
      final module = AcademyContent.modules
          .firstWhere((m) => m.id == event.moduleId,
              orElse: () => AcademyContent.modules.first);

      // Award XP
      _gamificationBloc.add(
          GamificationXpEarned(amount: module.xpReward, reason: 'أكملت درس ${module.titleAr}'));

      // Unlock badge if module has one
      if (module.badgeId != null) {
        _gamificationBloc.add(GamificationBadgeUnlocked(module.badgeId!));
      }
    }

    final newCompleted = Set<String>.from(current.completedModuleIds)
      ..add(event.moduleId);

    // Mark quiz as submitted
    final progress = current.progressFor(event.moduleId);
    final updated = progress.copyWith(submitted: true);

    emit(current.copyWith(
      completedModuleIds: newCompleted,
      quizProgress: Map.from(current.quizProgress)..[event.moduleId] = updated,
      clearActiveModule: true,
    ));

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCompletedKey, newCompleted.toList());
  }

  void _onDailyChallengeOpened(
      AcademyDailyChallengeOpened event, Emitter<AcademyState> emit) {
    // No-op — event used for route tracking if needed
  }

  Future<void> _onDailyChallengeAnswered(
      AcademyDailyChallengeAnswered event,
      Emitter<AcademyState> emit) async {
    if (state is! AcademyLoaded) return;
    final current = state as AcademyLoaded;
    if (current.dailyChallengeAnswered) return;

    final challenge = AcademyContent.todaysChallenge();
    _gamificationBloc.add(GamificationXpEarned(
        amount: challenge.xpReward, reason: 'تحدي يومي: ${challenge.titleAr}'));

    emit(current.copyWith(
      dailyChallengeAnswered: true,
      dailyChallengeAnswer: event.selectedChoice,
    ));

    // Persist today's date
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDailyChallengeKey, _todayKey());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
