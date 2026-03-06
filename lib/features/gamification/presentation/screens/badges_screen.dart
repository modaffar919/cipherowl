import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'ط¥ظ†ط¬ط§ط²ط§طھظٹ',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<GamificationBloc, GamificationState>(
        builder: (context, state) {
          if (state is! GamificationLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final badges = state.badges;
          final unlocked = badges.where((b) => b.isUnlocked).length;

          return CustomScrollView(
            slivers: [
              // â”€â”€ Summary Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.accentGold.withValues(alpha: 0.15),
                          AppConstants.primaryCyan.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppConstants.accentGold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('ًںڈ†',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlocked / ${badges.length}',
                              style: const TextStyle(
                                  color: AppConstants.accentGold,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800),
                            ),
                            const Text(
                              'ط´ط§ط±ط© ظ…ظپطھظˆط­ط©',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _LevelChip(
                            level: state.level, xp: state.xp),
                      ],
                    ),
                  ),
                ),
              ),

              // â”€â”€ Grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _BadgeTile(badge: badges[i]),
                    childCount: badges.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// â”€â”€ Level chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LevelChip extends StatelessWidget {
  final int level;
  final int xp;
  const _LevelChip({required this.level, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppConstants.primaryCyan, AppConstants.primaryCyanDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryCyan.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(xp / 1000).toStringAsFixed(1)}K XP',
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

// â”€â”€ Single badge tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BadgeTile extends StatelessWidget {
  final GamificationBadge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = Color(badge.colorValue);
    return GestureDetector(
      onTap: badge.isUnlocked
          ? () => _showDetail(context, badge, color)
          : null,
      child: AnimatedOpacity(
        opacity: badge.isUnlocked ? 1.0 : 0.38,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: AppConstants.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: badge.isUnlocked
                  ? color.withValues(alpha: 0.35)
                  : AppConstants.borderDark,
              width: badge.isUnlocked ? 1.5 : 1,
            ),
            boxShadow: badge.isUnlocked
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badge.isUnlocked
                          ? color.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  Icon(
                    IconData(badge.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: badge.isUnlocked ? color : Colors.white24,
                    size: 24,
                  ),
                  if (!badge.isUnlocked)
                    const Icon(Icons.lock,
                        color: Colors.white24, size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                badge.nameAr,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      badge.isUnlocked ? Colors.white : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, GamificationBadge badge, Color color) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppConstants.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(
                IconData(badge.iconCodePoint,
                    fontFamily: 'MaterialIcons'),
                color: color,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.nameAr,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              badge.descriptionAr,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
