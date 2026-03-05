import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import '../../domain/entities/academy_module.dart';
import '../bloc/academy_bloc.dart';

class ModuleDetailScreen extends StatelessWidget {
  final AcademyModule module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final color = Color(module.colorValue);
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppConstants.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.25),
                      AppConstants.backgroundDark,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Text(module.emoji,
                        style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text(
                      module.titleAr,
                      style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      module.titleEn,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── XP Badge ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          AppConstants.accentGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppConstants.accentGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '+${module.xpReward} XP عند الإكمال',
                          style: const TextStyle(
                              color: AppConstants.accentGold,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  BlocBuilder<AcademyBloc, AcademyState>(
                    builder: (context, state) {
                      if (state is! AcademyLoaded) return const SizedBox();
                      if (!state.isCompleted(module.id)) return const SizedBox();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.successGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  AppConstants.successGreen.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: AppConstants.successGreen,
                                size: 14),
                            SizedBox(width: 4),
                            Text(
                              'مكتمل',
                              style: TextStyle(
                                  color: AppConstants.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Lesson Body ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withOpacity(0.15)),
                ),
                child: Text(
                  module.bodyAr.trim(),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.8),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),

          // ── Quiz CTA ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: BlocBuilder<AcademyBloc, AcademyState>(
                builder: (context, state) {
                  final completed = state is AcademyLoaded &&
                      state.isCompleted(module.id);
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: module.quiz.isEmpty
                          ? null
                          : () => context.push(
                                AppConstants.routeAcademyQuiz
                                    .replaceFirst(':id', module.id),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            completed ? AppConstants.cardDark : color,
                        foregroundColor: completed
                            ? AppConstants.successGreen
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: completed
                            ? const BorderSide(
                                color: AppConstants.successGreen,
                                width: 1.5)
                            : BorderSide.none,
                      ),
                      icon: Icon(
                          completed
                              ? Icons.check_circle_outline
                              : Icons.quiz_outlined,
                          size: 20),
                      label: Text(
                        completed ? 'أُكملت الاختبار ✓' : 'ابدأ الاختبار',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
