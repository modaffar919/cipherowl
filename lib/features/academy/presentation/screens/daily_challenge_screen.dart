import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../data/academy_content.dart';
import '../../../../features/gamification/presentation/bloc/gamification_bloc.dart';
import '../bloc/academy_bloc.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final challenge = AcademyContent.todaysChallenge();

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'طھط­ط¯ظٹ ط§ظ„ظٹظˆظ… ًں”¥',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AcademyBloc, AcademyState>(
        builder: (context, state) {
          final loaded = state is AcademyLoaded ? state : null;
          final answered = loaded?.dailyChallengeAnswered ?? false;
          final selectedChoice = loaded?.dailyChallengeAnswer;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // â”€â”€ Streak + XP header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _StreakHeader(xpReward: challenge.xpReward),
                const SizedBox(height: 24),

                // â”€â”€ Challenge title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Text(
                  challenge.titleAr,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppConstants.primaryCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // â”€â”€ Question card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppConstants.primaryCyan.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    challenge.questionAr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.5),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(height: 16),

                // â”€â”€ Choices â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                ...List.generate(challenge.choicesAr.length, (i) {
                  final isSelected = selectedChoice == i;
                  final isCorrect = i == challenge.correctIndex;
                  Color borderColor = AppConstants.borderDark;
                  Color bgColor = AppConstants.cardDark;
                  Color textColor = Colors.white70;

                  if (answered) {
                    if (isCorrect) {
                      borderColor = AppConstants.successGreen;
                      bgColor = AppConstants.successGreen.withValues(alpha: 0.08);
                      textColor = AppConstants.successGreen;
                    } else if (isSelected && !isCorrect) {
                      borderColor = AppConstants.errorRed;
                      bgColor = AppConstants.errorRed.withValues(alpha: 0.08);
                      textColor = AppConstants.errorRed;
                    }
                  }

                  return GestureDetector(
                    onTap: answered
                        ? null
                        : () => context.read<AcademyBloc>().add(
                            AcademyDailyChallengeAnswered(i)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            answered
                                ? (isCorrect
                                    ? Icons.check_circle
                                    : (isSelected
                                        ? Icons.cancel
                                        : Icons.radio_button_unchecked))
                                : Icons.radio_button_unchecked,
                            color: answered
                                ? (isCorrect
                                    ? AppConstants.successGreen
                                    : (isSelected
                                        ? AppConstants.errorRed
                                        : Colors.white24))
                                : Colors.white24,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              challenge.choicesAr[i],
                              style: TextStyle(
                                  color: textColor, fontSize: 14),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // â”€â”€ Explanation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (answered) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryCyan.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppConstants.primaryCyan.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppConstants.primaryCyan, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            challenge.explanationAr,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.accentGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppConstants.accentGold.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('â­گ',
                            style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          '+${challenge.xpReward} XP ط£ظڈط¶ظٹظپطھ!',
                          style: const TextStyle(
                            color: AppConstants.accentGold,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (!answered) ...[
                  const SizedBox(height: 12),
                  Text(
                    'ط§ط®طھط± ط¥ط¬ط§ط¨ط© ظˆط§ط­ط¯ط©',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€ Streak header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StreakHeader extends StatelessWidget {
  final int xpReward;
  const _StreakHeader({required this.xpReward});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationBloc, GamificationState>(
      builder: (context, state) {
        final streak = state is GamificationLoaded ? state.streak : 0;
        return Row(
          children: [
            _StatPill(
              icon: 'ًں”¥',
              label: '$streak ظٹظˆظ… ظ…طھظˆط§ظ„ظٹ',
              color: AppConstants.warningAmber,
            ),
            const SizedBox(width: 10),
            _StatPill(
              icon: 'â­گ',
              label: '+$xpReward XP',
              color: AppConstants.accentGold,
            ),
          ],
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _StatPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
