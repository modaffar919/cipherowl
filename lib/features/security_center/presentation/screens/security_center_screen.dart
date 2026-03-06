import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/security_center/presentation/bloc/security_bloc.dart';
import '../../../vault/presentation/bloc/vault_bloc.dart';

/// Security Center � interactive shield showing real security score from SecurityBloc.
class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});
  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _rotCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    // Seed SecurityBloc with current vault data on first render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vaultState = context.read<VaultBloc>().state;
      if (vaultState is VaultLoaded) {
        context
            .read<SecurityBloc>()
            .add(SecurityVaultUpdated(vaultState.allItems));
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultBloc, VaultState>(
      listener: (context, vaultState) {
        if (vaultState is VaultLoaded) {
          context
              .read<SecurityBloc>()
              .add(SecurityVaultUpdated(vaultState.allItems));
        }
      },
      child: BlocBuilder<SecurityBloc, SecurityState>(
        builder: (context, secState) {
          // Keep item count for display label (read-only, no rebuild needed).
          final vaultState = context.read<VaultBloc>().state;
          final itemCount =
              vaultState is VaultLoaded ? vaultState.allItems.length : 0;

          // Show spinner while SecurityBloc is computing.
          if (secState is! SecurityLoaded) {
            return Scaffold(
              backgroundColor: AppConstants.backgroundDark,
              appBar: AppBar(
                backgroundColor: AppConstants.backgroundDark,
                title: const Text('���� ������',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // Map SecurityBloc types to local display models.
          final score = secState.score;

          final layers = secState.layers
              .map((l) => _SecurityLayer(
                    l.nameAr,
                    l.maxPoints,
                    l.earnedPoints,
                    IconData(l.iconCodePoint, fontFamily: 'MaterialIcons'),
                  ))
              .toList();

          final recommendations = secState.recommendations
              .map((r) => _RecommendData(
                    icon: IconData(r.iconCodePoint, fontFamily: 'MaterialIcons'),
                    title: r.titleAr,
                    body: r.bodyAr,
                    xp: r.xpReward,
                    color: Color(r.colorValue),
                  ))
              .toList();

          return Scaffold(
            backgroundColor: AppConstants.backgroundDark,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppConstants.backgroundDark,
                  pinned: true,
                  title: const Text('���� ������',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  centerTitle: false,
                ),

                // Shield Score
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      _SecurityShield(
                          score: score,
                          pulse: _pulseCtrl,
                          rotation: _rotCtrl),
                      const SizedBox(height: 8),
                      const Text('���� ������ ������',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        secState.grade,
                        style: TextStyle(
                          color: Color(secState.gradeColor),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (itemCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$itemCount ���� �����',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ),
                    ]),
                  ),
                ),

                // Security Layers
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _LayerCard(layer: layers[i]),
                      childCount: layers.length,
                    ),
                  ),
                ),

                // Recommendations
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('��������',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ...recommendations.map((r) => _RecommendCard(
                              icon: r.icon,
                              title: r.title,
                              body: r.body,
                              xp: r.xp,
                              color: r.color,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ), // BlocBuilder
    ); // BlocListener
  }
}

class _SecurityLayer {
  final String name;
  final int max;
  final int current;
  final IconData icon;
  const _SecurityLayer(this.name, this.max, this.current, this.icon);
}

class _SecurityShield extends StatelessWidget {
  final int score;
  final AnimationController pulse;
  final AnimationController rotation;

  const _SecurityShield(
      {required this.score, required this.pulse, required this.rotation});

  Color get _color => score >= 80
      ? AppConstants.successGreen
      : score >= 50
          ? AppConstants.warningAmber
          : AppConstants.errorRed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: rotation,
            builder: (_, __) => Transform.rotate(
              angle: rotation.value * 2 * math.pi,
              child: CustomPaint(
                  size: const Size(200, 200), painter: _RingPainter(_color)),
            ),
          ),
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: 140 + pulse.value * 10,
              height: 140 + pulse.value * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _color.withValues(alpha: 0.1 + pulse.value * 0.15),
                      blurRadius: 30,
                      spreadRadius: 5)
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$score',
                  style: TextStyle(
                      color: _color,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'SpaceMono')),
              Text('/ 100',
                  style:
                      TextStyle(color: _color.withValues(alpha: 0.5), fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  const _RingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const segments = 12;
    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(x, y),
        i % 3 == 0 ? 3.0 : 1.5,
        Paint()..color = color.withValues(alpha: i % 3 == 0 ? 0.8 : 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LayerCard extends StatelessWidget {
  final _SecurityLayer layer;
  const _LayerCard({required this.layer});

  Color get _color {
    final ratio = layer.current / layer.max;
    if (ratio >= 0.9) return AppConstants.successGreen;
    if (ratio >= 0.6) return AppConstants.warningAmber;
    return AppConstants.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = layer.current / layer.max;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(layer.icon, color: _color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(layer.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppConstants.borderDark,
                    color: _color,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${layer.current}/${layer.max}',
              style: TextStyle(
                  color: _color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _RecommendData {
  final IconData icon;
  final String title;
  final String body;
  final int xp;
  final Color color;
  const _RecommendData(
      {required this.icon,
      required this.title,
      required this.body,
      required this.xp,
      required this.color});
}

class _RecommendCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final int xp;
  final Color color;
  const _RecommendCard(
      {required this.icon,
      required this.title,
      required this.body,
      required this.xp,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(body,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppConstants.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text('+$xp XP',
                style: const TextStyle(
                    color: AppConstants.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
