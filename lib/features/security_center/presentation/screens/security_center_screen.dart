import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

/// Security Center — interactive shield showing security score
class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});
  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotCtrl;

  // Computed from real vault data in build()
  static int _computeScore(List<VaultEntry> items) {
    if (items.isEmpty) return 100; // empty vault = no weak passwords
    final total = items.length;

    // Password strength (50 pts): % with strengthScore >= 3
    final scored = items.where((i) => i.strengthScore >= 0);
    final strong = scored.where((i) => i.strengthScore >= 3).length;
    final pwdPts = scored.isEmpty ? 40 : (strong / scored.length * 50).round();

    // 2FA (20 pts): % with totp category
    final with2fa = items.where((i) => i.category == VaultCategory.totp || i.encryptedTotpSecret != null).length;
    final totpPts = total == 0 ? 0 : (with2fa / total * 20).round();

    // Updates (15 pts): % updated in last 90 days
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final fresh = items.where((i) => i.updatedAt.isAfter(cutoff)).length;
    final updatePts = total == 0 ? 15 : (fresh / total * 15).round();

    // Encryption always 15 (AES-256-GCM active)
    const encPts = 15;

    return (pwdPts + totpPts + updatePts + encPts).clamp(0, 100);
  }

  static List<_SecurityLayer> _buildLayers(List<VaultEntry> items) {
    final total = items.length;
    final cutoff = DateTime.now().subtract(const Duration(days: 90));

    final scored = items.where((i) => i.strengthScore >= 0).toList();
    final strong = scored.where((i) => i.strengthScore >= 3).length;
    final with2fa = items.where((i) =>
        i.category == VaultCategory.totp || i.encryptedTotpSecret != null).length;
    final fresh = items.where((i) => i.updatedAt.isAfter(cutoff)).length;

    return [
      _SecurityLayer('كلمات المرور', 50,
          scored.isEmpty ? 40 : (strong / scored.length * 50).round(), Icons.lock),
      _SecurityLayer('المصادقة الثنائية', 20,
          total == 0 ? 0 : (with2fa / total * 20).round(), Icons.security),
      _SecurityLayer('التحديثات', 15,
          total == 0 ? 15 : (fresh / total * 15).round(), Icons.update),
      const _SecurityLayer('التشفير', 15, 15, Icons.shield),
      const _SecurityLayer('المشاركة الآمنة', 10, 3, Icons.share),
    ];
  }

  static List<_RecommendData> _buildRecommendations(List<VaultEntry> items) {
    final recs = <_RecommendData>[];
    final weak = items.where((i) => i.strengthScore >= 0 && i.strengthScore <= 1);
    if (weak.isNotEmpty) {
      recs.add(_RecommendData(
        icon: Icons.lock_outline,
        title: 'كلمات مرور ضعيفة (${weak.length})',
        body: 'استخدم مولّد كلمات المرور لتحسينها',
        xp: 20,
        color: AppConstants.errorRed,
      ));
    }
    final with2fa = items.where((i) =>
        i.category == VaultCategory.totp || i.encryptedTotpSecret != null).length;
    if (with2fa < items.length && items.isNotEmpty) {
      recs.add(_RecommendData(
        icon: Icons.security,
        title: 'فعّل المصادقة الثنائية',
        body: '${items.length - with2fa} حسابات بدون 2FA',
        xp: 30,
        color: AppConstants.warningAmber,
      ));
    }
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final old = items.where((i) => i.updatedAt.isBefore(cutoff)).length;
    if (old > 0) {
      recs.add(_RecommendData(
        icon: Icons.update,
        title: 'حدّث كلمات المرور القديمة',
        body: '$old حسابات لم تُحدَّث منذ أكثر من سنة',
        xp: 25,
        color: AppConstants.primaryCyan,
      ));
    }
    if (recs.isEmpty) {
      recs.add(_RecommendData(
        icon: Icons.verified_user,
        title: 'أمان ممتاز!',
        body: 'خزنتك محمية بالكامل 🛡️',
        xp: 50,
        color: AppConstants.successGreen,
      ));
    }
    return recs;
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _rotCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultBloc, VaultState>(
      builder: (context, state) {
        final items = state is VaultLoaded ? state.allItems : <VaultEntry>[];
        final score = _computeScore(items);
        final layers = _buildLayers(items);
        final recommendations = _buildRecommendations(items);

        return Scaffold(
          backgroundColor: AppConstants.backgroundDark,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppConstants.backgroundDark,
                pinned: true,
                title: const Text('مركز الأمان',
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
                    const Text('درجة الأمان الكلية',
                        style: TextStyle(color: Colors.white60, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      score >= 80
                          ? 'ممتاز! خزنتك محمية جيداً 🛡️'
                          : score >= 50
                              ? 'جيد — يمكن تحسينه'
                              : 'تحذير: مستوى الحماية منخفض',
                      style: TextStyle(
                        color: score >= 80
                            ? AppConstants.successGreen
                            : score >= 50
                                ? AppConstants.warningAmber
                                : AppConstants.errorRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${items.length} حساب محفوظ',
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
                      const Text('التوصيات',
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
    );
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

  const _SecurityShield({required this.score, required this.pulse, required this.rotation});

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
          // Rotating outer ring
          AnimatedBuilder(
            animation: rotation,
            builder: (_, __) => Transform.rotate(
              angle: rotation.value * 2 * math.pi,
              child: CustomPaint(size: const Size(200, 200), painter: _RingPainter(_color)),
            ),
          ),

          // Pulsing glow
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: 140 + pulse.value * 10,
              height: 140 + pulse.value * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _color.withOpacity(0.1 + pulse.value * 0.15), blurRadius: 30, spreadRadius: 5)],
              ),
            ),
          ),

          // Score text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$score', style: TextStyle(color: _color, fontSize: 52, fontWeight: FontWeight.w800, fontFamily: 'SpaceMono')),
              Text('/ 100', style: TextStyle(color: _color.withOpacity(0.5), fontSize: 14)),
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
        Paint()..color = color.withOpacity(i % 3 == 0 ? 0.8 : 0.3),
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
          Container(width: 40, height: 40, decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(layer.icon, color: _color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(layer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: ratio, backgroundColor: AppConstants.borderDark, color: _color, minHeight: 4, borderRadius: BorderRadius.circular(2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${layer.current}/${layer.max}', style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 13)),
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
  const _RecommendData({required this.icon, required this.title, required this.body, required this.xp, required this.color});
}

class _RecommendCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final int xp;
  final Color color;
  const _RecommendCard({required this.icon, required this.title, required this.body, required this.xp, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppConstants.accentGold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('+$xp XP', style: const TextStyle(color: AppConstants.accentGold, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

