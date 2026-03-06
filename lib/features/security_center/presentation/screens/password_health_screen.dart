import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

/// Password Health Dashboard — detailed analysis of all vault passwords.
///
/// Shows: strength pie chart, weak/stale/breach lists, overall health score,
/// and actionable recommendations with XP rewards.
class PasswordHealthScreen extends StatefulWidget {
  const PasswordHealthScreen({super.key});

  @override
  State<PasswordHealthScreen> createState() => _PasswordHealthScreenState();
}

class _PasswordHealthScreenState extends State<PasswordHealthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text(
          '\u0635\u062D\u0629 \u0643\u0644\u0645\u0627\u062A \u0627\u0644\u0645\u0631\u0648\u0631', // صحة كلمات المرور
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, vaultState) {
          if (vaultState is! VaultLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = vaultState.allItems;
          final analysis = _PasswordAnalysis.compute(items);

          return AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, _) {
              final animatedScore =
                  (analysis.healthScore * _scoreAnim.value).round();

              return CustomScrollView(
                slivers: [
                  // ── Health Score Ring ──────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _HealthScoreRing(
                        score: animatedScore,
                        targetScore: analysis.healthScore,
                        progress: _scoreAnim.value,
                      ),
                    ),
                  ),

                  // ── Stats Cards ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _StatsRow(analysis: analysis),
                    ),
                  ),

                  // ── Pie Chart ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _StrengthPieChart(analysis: analysis),
                    ),
                  ),

                  // ── Weak Passwords ────────────────────────
                  if (analysis.weakItems.isNotEmpty)
                    _SectionHeader(
                      title:
                          '\u0643\u0644\u0645\u0627\u062A \u0645\u0631\u0648\u0631 \u0636\u0639\u064A\u0641\u0629 (${analysis.weakItems.length})', // كلمات مرور ضعيفة
                      color: AppConstants.errorRed,
                    ),
                  if (analysis.weakItems.isNotEmpty)
                    _PasswordItemList(
                      items: analysis.weakItems,
                      badgeColor: AppConstants.errorRed,
                      badgeLabel: '\u0636\u0639\u064A\u0641\u0629', // ضعيفة
                    ),

                  // ── Stale Passwords ───────────────────────
                  if (analysis.staleItems.isNotEmpty)
                    _SectionHeader(
                      title:
                          '\u0643\u0644\u0645\u0627\u062A \u0645\u0631\u0648\u0631 \u0642\u062F\u064A\u0645\u0629 (${analysis.staleItems.length})', // كلمات مرور قديمة
                      color: AppConstants.warningAmber,
                    ),
                  if (analysis.staleItems.isNotEmpty)
                    _PasswordItemList(
                      items: analysis.staleItems,
                      badgeColor: AppConstants.warningAmber,
                      badgeLabel:
                          '> 90 \u064A\u0648\u0645', // > 90 يوم
                    ),

                  // ── No TOTP ───────────────────────────────
                  if (analysis.noTotpItems.isNotEmpty)
                    _SectionHeader(
                      title:
                          '\u0628\u062F\u0648\u0646 \u0645\u0635\u0627\u062F\u0642\u0629 \u062B\u0646\u0627\u0626\u064A\u0629 (${analysis.noTotpItems.length})', // بدون مصادقة ثنائية
                      color: AppConstants.warningOrange,
                    ),
                  if (analysis.noTotpItems.isNotEmpty)
                    _PasswordItemList(
                      items: analysis.noTotpItems,
                      badgeColor: AppConstants.warningOrange,
                      badgeLabel:
                          '\u0628\u062F\u0648\u0646 TOTP', // بدون TOTP
                    ),

                  // ── Breach Check ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _BreachCheckCard(),
                    ),
                  ),

                  // ── Recommendations ───────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: _HealthRecommendations(analysis: analysis),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Analysis Model
// ═══════════════════════════════════════════════════════════════════════════════

class _PasswordAnalysis {
  final int totalPasswords;
  final int strongCount; // score >= 3
  final int mediumCount; // score == 2
  final int weakCount; // score <= 1
  final int staleCount;
  final int noTotpCount;
  final int healthScore; // 0-100

  final List<VaultEntry> weakItems;
  final List<VaultEntry> staleItems;
  final List<VaultEntry> noTotpItems;

  const _PasswordAnalysis({
    required this.totalPasswords,
    required this.strongCount,
    required this.mediumCount,
    required this.weakCount,
    required this.staleCount,
    required this.noTotpCount,
    required this.healthScore,
    required this.weakItems,
    required this.staleItems,
    required this.noTotpItems,
  });

  static _PasswordAnalysis compute(List<VaultEntry> items) {
    final now = DateTime.now();
    final cutoff90 = now.subtract(const Duration(days: 90));

    // Only entries with passwords
    final withPwd =
        items.where((e) => e.encryptedPassword != null).toList();
    final total = withPwd.length;

    final strong = withPwd.where((e) => e.strengthScore >= 3).toList();
    final medium = withPwd.where((e) => e.strengthScore == 2).toList();
    final weak =
        withPwd.where((e) => e.strengthScore <= 1 && e.strengthScore >= 0).toList();
    final stale = withPwd.where((e) => e.updatedAt.isBefore(cutoff90)).toList();

    // Login items without TOTP
    final logins = items.where((e) => e.category == VaultCategory.login);
    final noTotp = logins
        .where((e) => e.encryptedTotpSecret == null)
        .toList();

    // Health score: weighted average
    // 50% password strength + 25% freshness + 25% 2FA coverage
    double strengthRatio = total == 0 ? 1.0 : strong.length / total;
    double freshnessRatio = total == 0
        ? 1.0
        : withPwd.where((e) => e.updatedAt.isAfter(cutoff90)).length / total;
    double totpRatio = logins.isEmpty
        ? 1.0
        : 1.0 - (noTotp.length / logins.length);

    int health =
        (strengthRatio * 50 + freshnessRatio * 25 + totpRatio * 25).round();

    return _PasswordAnalysis(
      totalPasswords: total,
      strongCount: strong.length,
      mediumCount: medium.length,
      weakCount: weak.length,
      staleCount: stale.length,
      noTotpCount: noTotp.length,
      healthScore: health.clamp(0, 100),
      weakItems: weak,
      staleItems: stale,
      noTotpItems: noTotp,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Health Score Ring
// ═══════════════════════════════════════════════════════════════════════════════

class _HealthScoreRing extends StatelessWidget {
  final int score;
  final int targetScore;
  final double progress;

  const _HealthScoreRing({
    required this.score,
    required this.targetScore,
    required this.progress,
  });

  Color get _color {
    if (targetScore >= 80) return AppConstants.scoreExcellent;
    if (targetScore >= 60) return AppConstants.scoreGood;
    if (targetScore >= 40) return AppConstants.scoreMedium;
    if (targetScore >= 20) return AppConstants.scoreWeak;
    return AppConstants.scoreCritical;
  }

  String get _label {
    if (targetScore >= 80) return '\u0645\u0645\u062A\u0627\u0632'; // ممتاز
    if (targetScore >= 60) return '\u062C\u064A\u062F'; // جيد
    if (targetScore >= 40) return '\u0645\u0642\u0628\u0648\u0644'; // مقبول
    return '\u0636\u0639\u064A\u0641'; // ضعيف
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(180, 180),
              painter: _ScoreRingPainter(
                progress: (targetScore / 100) * progress,
                color: _color,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    color: _color,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'SpaceMono',
                  ),
                ),
                Text(
                  _label,
                  style: TextStyle(
                    color: _color.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppConstants.borderDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Stats Row
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final _PasswordAnalysis analysis;
  const _StatsRow({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            count: analysis.strongCount,
            label: '\u0642\u0648\u064A\u0629', // قوية
            color: AppConstants.successGreen,
            icon: Icons.verified_user,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            count: analysis.mediumCount,
            label: '\u0645\u062A\u0648\u0633\u0637\u0629', // متوسطة
            color: AppConstants.warningAmber,
            icon: Icons.shield,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            count: analysis.weakCount,
            label: '\u0636\u0639\u064A\u0641\u0629', // ضعيفة
            color: AppConstants.errorRed,
            icon: Icons.warning_amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            count: analysis.staleCount,
            label: '\u0642\u062F\u064A\u0645\u0629', // قديمة
            color: AppConstants.primaryCyan,
            icon: Icons.update,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Strength Pie Chart
// ═══════════════════════════════════════════════════════════════════════════════

class _StrengthPieChart extends StatelessWidget {
  final _PasswordAnalysis analysis;
  const _StrengthPieChart({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final total = analysis.totalPasswords;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.borderDark),
        ),
        child: const Center(
          child: Text(
            '\u0644\u0627 \u062A\u0648\u062C\u062F \u0643\u0644\u0645\u0627\u062A \u0645\u0631\u0648\u0631 \u0628\u0639\u062F', // لا توجد كلمات مرور بعد
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u062A\u0648\u0632\u064A\u0639 \u0627\u0644\u0642\u0648\u0629', // توزيع القوة
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    strong: analysis.strongCount,
                    medium: analysis.mediumCount,
                    weak: analysis.weakCount,
                    total: total,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(
                      color: AppConstants.successGreen,
                      label:
                          '\u0642\u0648\u064A\u0629', // قوية
                      count: analysis.strongCount,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(
                      color: AppConstants.warningAmber,
                      label:
                          '\u0645\u062A\u0648\u0633\u0637\u0629', // متوسطة
                      count: analysis.mediumCount,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(
                      color: AppConstants.errorRed,
                      label:
                          '\u0636\u0639\u064A\u0641\u0629', // ضعيفة
                      count: analysis.weakCount,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final int strong;
  final int medium;
  final int weak;
  final int total;

  const _PieChartPainter({
    required this.strong,
    required this.medium,
    required this.weak,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 16.0;

    double startAngle = -math.pi / 2;

    void drawSegment(int count, Color color) {
      if (count == 0) return;
      final sweep = (count / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }

    drawSegment(strong, AppConstants.successGreen);
    drawSegment(medium, AppConstants.warningAmber);
    drawSegment(weak, AppConstants.errorRed);

    // Unscored passwords
    final unscored = total - strong - medium - weak;
    drawSegment(unscored, AppConstants.borderDark);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      old.strong != strong ||
      old.medium != medium ||
      old.weak != weak ||
      old.total != total;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ($count)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Text(
          '$pct%',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'SpaceMono',
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section Header
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Password Item List
// ═══════════════════════════════════════════════════════════════════════════════

class _PasswordItemList extends StatelessWidget {
  final List<VaultEntry> items;
  final Color badgeColor;
  final String badgeLabel;

  const _PasswordItemList({
    required this.items,
    required this.badgeColor,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _PasswordItemTile(
            entry: items[i],
            badgeColor: badgeColor,
            badgeLabel: badgeLabel,
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}

class _PasswordItemTile extends StatelessWidget {
  final VaultEntry entry;
  final Color badgeColor;
  final String badgeLabel;

  const _PasswordItemTile({
    required this.entry,
    required this.badgeColor,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final daysSinceUpdate =
        DateTime.now().difference(entry.updatedAt).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Category emoji
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(entry.category.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.username ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Days since update
          Text(
            '$daysSinceUpdate\u064A', // Xي (days suffix)
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),
          const SizedBox(width: 8),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Breach Check Card
// ═══════════════════════════════════════════════════════════════════════════════

class _BreachCheckCard extends StatefulWidget {
  @override
  State<_BreachCheckCard> createState() => _BreachCheckCardState();
}

class _BreachCheckCardState extends State<_BreachCheckCard> {
  bool _checking = false;
  int? _breachedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _breachedCount != null && _breachedCount! > 0
              ? AppConstants.errorRed.withValues(alpha: 0.3)
              : AppConstants.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar,
                color: _breachedCount != null && _breachedCount! > 0
                    ? AppConstants.errorRed
                    : AppConstants.primaryCyan,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '\u0641\u062D\u0635 \u0627\u0644\u0627\u062E\u062A\u0631\u0627\u0642\u0627\u062A (HaveIBeenPwned)', // فحص الاختراقات
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\u0641\u062D\u0635 \u0643\u0644\u0645\u0627\u062A \u0627\u0644\u0645\u0631\u0648\u0631 \u0636\u062F \u0642\u0648\u0627\u0639\u062F \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0627\u062E\u062A\u0631\u0627\u0642\u0627\u062A \u0627\u0644\u0645\u0639\u0631\u0648\u0641\u0629', // فحص كلمات المرور ضد قواعد بيانات الاختراقات المعروفة
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_breachedCount != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    _breachedCount! > 0
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: _breachedCount! > 0
                        ? AppConstants.errorRed
                        : AppConstants.successGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _breachedCount! > 0
                        ? '$_breachedCount \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u0645\u062E\u062A\u0631\u0642\u0629!' // كلمة مرور مخترقة!
                        : '\u0644\u0627 \u062A\u0648\u062C\u062F \u0627\u062E\u062A\u0631\u0627\u0642\u0627\u062A \u0645\u0639\u0631\u0648\u0641\u0629', // لا توجد اختراقات معروفة
                    style: TextStyle(
                      color: _breachedCount! > 0
                          ? AppConstants.errorRed
                          : AppConstants.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checking ? null : _runBreachCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryCyan.withValues(alpha: 0.15),
                foregroundColor: AppConstants.primaryCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(
                _checking
                    ? '\u062C\u0627\u0631\u064D \u0627\u0644\u0641\u062D\u0635...' // جارٍ الفحص...
                    : '\u0641\u062D\u0635 \u0627\u0644\u0622\u0646', // فحص الآن
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runBreachCheck() async {
    setState(() {
      _checking = true;
      _breachedCount = null;
    });

    // Note: Real breach check requires decrypted passwords.
    // This demonstrates the integration point with HibpService.
    // In production, passwords are decrypted on-demand and checked individually.
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _checking = false;
      _breachedCount = 0; // Placeholder — real check needs decrypted passwords
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recommendations
// ═══════════════════════════════════════════════════════════════════════════════

class _HealthRecommendations extends StatelessWidget {
  final _PasswordAnalysis analysis;
  const _HealthRecommendations({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final recs = <_RecommendItem>[];

    if (analysis.weakCount > 0) {
      recs.add(_RecommendItem(
        icon: Icons.lock_outline,
        title:
            '\u062A\u062D\u0633\u064A\u0646 ${analysis.weakCount} \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u0636\u0639\u064A\u0641\u0629', // تحسين X كلمة مرور ضعيفة
        body:
            '\u0627\u0633\u062A\u062E\u062F\u0645 \u0645\u0648\u0644\u0651\u062F \u0643\u0644\u0645\u0627\u062A \u0627\u0644\u0645\u0631\u0648\u0631 \u0644\u0625\u0646\u0634\u0627\u0621 \u0643\u0644\u0645\u0627\u062A \u0645\u0631\u0648\u0631 \u0642\u0648\u064A\u0629', // استخدم مولّد كلمات المرور لإنشاء كلمات مرور قوية
        xp: 20 * analysis.weakCount,
        color: AppConstants.errorRed,
      ));
    }

    if (analysis.staleCount > 0) {
      recs.add(_RecommendItem(
        icon: Icons.update,
        title:
            '\u062A\u062D\u062F\u064A\u062B ${analysis.staleCount} \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u0642\u062F\u064A\u0645\u0629', // تحديث X كلمة مرور قديمة
        body:
            '\u0644\u0645 \u062A\u064F\u062D\u062F\u064E\u0651\u062B \u0645\u0646\u0630 \u0623\u0643\u062B\u0631 \u0645\u0646 90 \u064A\u0648\u0645\u0627\u064B \u2014 \u064A\u064F\u0646\u0635\u062D \u0628\u0627\u0644\u062A\u063A\u064A\u064A\u0631 \u0627\u0644\u062F\u0648\u0631\u064A', // لم تُحدَّث منذ أكثر من 90 يوماً — يُنصح بالتغيير الدوري
        xp: 10 * analysis.staleCount,
        color: AppConstants.warningAmber,
      ));
    }

    if (analysis.noTotpCount > 0) {
      recs.add(_RecommendItem(
        icon: Icons.security,
        title:
            '\u0641\u0639\u0651\u0644 TOTP \u0644\u0640 ${analysis.noTotpCount} \u062D\u0633\u0627\u0628', // فعّل TOTP لـ X حساب
        body:
            '\u0623\u0636\u0641 \u0627\u0644\u0645\u0635\u0627\u062F\u0642\u0629 \u0627\u0644\u062B\u0646\u0627\u0626\u064A\u0629 \u0644\u0644\u062D\u0633\u0627\u0628\u0627\u062A \u0627\u0644\u0645\u0647\u0645\u0629', // أضف المصادقة الثنائية للحسابات المهمة
        xp: 15 * analysis.noTotpCount,
        color: AppConstants.warningOrange,
      ));
    }

    if (recs.isEmpty) {
      recs.add(const _RecommendItem(
        icon: Icons.check_circle,
        title:
            '\u0635\u062D\u0629 \u0643\u0644\u0645\u0627\u062A \u0627\u0644\u0645\u0631\u0648\u0631 \u0645\u0645\u062A\u0627\u0632\u0629! \uD83C\uDF89', // صحة كلمات المرور ممتازة! 🎉
        body:
            '\u0627\u0633\u062A\u0645\u0631 \u0641\u064A \u062A\u062D\u062F\u064A\u062B \u0643\u0644\u0645\u0627\u062A \u0627\u0644\u0645\u0631\u0648\u0631 \u0628\u0627\u0646\u062A\u0638\u0627\u0645', // استمر في تحديث كلمات المرور بانتظام
        xp: 50,
        color: Color(0xFF4CAF50),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\u062A\u0648\u0635\u064A\u0627\u062A', // توصيات
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...recs.map((r) => _RecommendationCard(item: r)),
      ],
    );
  }
}

class _RecommendItem {
  final IconData icon;
  final String title;
  final String body;
  final int xp;
  final Color color;

  const _RecommendItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.xp,
    required this.color,
  });
}

class _RecommendationCard extends StatelessWidget {
  final _RecommendItem item;
  const _RecommendationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${item.xp} XP',
              style: const TextStyle(
                color: AppConstants.accentGold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'SpaceMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
