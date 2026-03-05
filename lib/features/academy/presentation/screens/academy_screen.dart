import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../data/academy_content.dart';
import '../bloc/academy_bloc.dart';

/// Threat Academy hub — module grid + quick-access to badges and daily challenge.
class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppConstants.backgroundDark,
            pinned: true,
            title: const Text(
              'أكاديمية CipherOwl',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
            centerTitle: false,
            actions: [
              // Badges button
              IconButton(
                icon: const Icon(Icons.emoji_events_outlined,
                    color: AppConstants.accentGold),
                tooltip: 'الإنجازات',
                onPressed: () =>
                    context.push(AppConstants.routeAcademyBadges),
              ),
            ],
          ),

          // ── Quick-action row (XP + streak + daily) ─────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _QuickActions(),
            ),
          ),

          // ── Module grid ─────────────────────────────────────────────────
          BlocBuilder<AcademyBloc, AcademyState>(
            builder: (context, state) {
              final loaded =
                  state is AcademyLoaded ? state : null;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final module = AcademyContent.modules[i];
                      final done =
                          loaded?.isCompleted(module.id) ?? false;
                      return _ModuleTile(
                          module: module, completed: done);
                    },
                    childCount: AcademyContent.modules.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Quick actions row ─────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademyBloc, AcademyState>(
      builder: (context, state) {
        final loaded = state is AcademyLoaded ? state : null;
        final completed = loaded?.completedCount ?? 0;
        final total = AcademyContent.modules.length;
        final dailyDone = loaded?.dailyChallengeAnswered ?? false;

        return Row(
          children: [
            // Progress pill
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppConstants.borderDark),
                ),
                child: Row(
                  children: [
                    const Text('📚',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completed / $total',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        const Text(
                          'درس مكتمل',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Daily challenge pill
            GestureDetector(
              onTap: () => context
                  .push(AppConstants.routeAcademyDaily),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: dailyDone
                      ? AppConstants.cardDark
                      : AppConstants.warningAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dailyDone
                        ? AppConstants.borderDark
                        : AppConstants.warningAmber
                            .withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      dailyDone ? '✅' : '🔥',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dailyDone ? 'أُنجز' : 'تحدي اليوم',
                      style: TextStyle(
                        color: dailyDone
                            ? Colors.white38
                            : AppConstants.warningAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Module tile ───────────────────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  final dynamic module; // AcademyModule
  final bool completed;
  const _ModuleTile({required this.module, required this.completed});

  @override
  Widget build(BuildContext context) {
    final color = Color(module.colorValue as int);

    return GestureDetector(
      onTap: () {
        context.read<AcademyBloc>().add(AcademyModuleOpened(module.id as String));
        context.push(
          AppConstants.routeAcademyModule
              .replaceFirst(':id', module.id as String),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? AppConstants.successGreen.withOpacity(0.4)
                : color.withOpacity(0.2),
            width: completed ? 1.5 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.06), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(module.emoji as String,
                    style: const TextStyle(fontSize: 32)),
                const Spacer(),
                if (completed)
                  const Icon(Icons.check_circle,
                      color: AppConstants.successGreen, size: 16),
              ],
            ),
            const Spacer(),
            Text(
              module.titleAr as String,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
              maxLines: 2,
            ),
            const SizedBox(height: 2),
            Text(
              module.titleEn as String,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppConstants.accentGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${module.xpReward} XP',
                    style: const TextStyle(
                        color: AppConstants.accentGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
                if ((module.quiz as List).isNotEmpty)
                  Text(
                    '${(module.quiz as List).length} أسئلة',
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 9),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

