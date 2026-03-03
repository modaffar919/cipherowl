import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

/// Threat Academy — 10 security education cards with quiz
class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  static const _topics = [
    _ThreatCard(emoji: '🎣', title: 'التصيد الاحتيالي', titleEn: 'Phishing', body: 'رسائل مزيفة تسرق بياناتك. تحقق دائماً من المرسل والرابط.', xp: 10, color: Color(0xFFFF6B6B)),
    _ThreatCard(emoji: '🦠', title: 'البرامج الخبيثة', titleEn: 'Malware', body: 'برامج تُثبّت نفسها خفية. لا تحمّل من مصادر غير موثوقة.', xp: 10, color: Color(0xFFFF8C42)),
    _ThreatCard(emoji: '🔑', title: 'هجمات كلمات المرور', titleEn: 'Password Attacks', body: 'القاموس، القوة الغاشمة، Credential Stuffing. استخدم كلمات مرور فريدة.', xp: 15, color: Color(0xFFFFD166)),
    _ThreatCard(emoji: '🕵️', title: 'هندسة اجتماعية', titleEn: 'Social Engineering', body: 'استغلال الثقة لسرقة المعلومات. لا تعطِ بياناتك لأي شخص.', xp: 15, color: Color(0xFF06D6A0)),
    _ThreatCard(emoji: '📡', title: 'الاعتراض الشبكي', titleEn: 'MITM / Sniffing', body: 'التجسس على الشبكة العامة. استخدم VPN دائماً في الأماكن العامة.', xp: 20, color: Color(0xFF118AB2)),
    _ThreatCard(emoji: '💻', title: 'برامج الفدية', titleEn: 'Ransomware', body: 'تشفير ملفاتك مقابل فدية. النسخ الاحتياطي درعك الأول.', xp: 20, color: Color(0xFFEF476F)),
    _ThreatCard(emoji: '🤖', title: 'تزييف عميق', titleEn: 'Deepfake', body: 'فيديوهات مزيفة بالذكاء الاصطناعي. تحقق من المصادر قبل المشاركة.', xp: 25, color: Color(0xFF7B2FBE)),
    _ThreatCard(emoji: '🌐', title: 'الويب المظلم', titleEn: 'Dark Web Leaks', body: 'بياناتك قد تُباع هناك. فعّل المراقبة المستمرة.', xp: 25, color: Color(0xFF3D348B)),
    _ThreatCard(emoji: '⚡', title: 'ثغرات يوم الصفر', titleEn: 'Zero-Day Exploits', body: 'ثغرات غير مكتشفة. حافظ على تحديث تطبيقاتك دائماً.', xp: 30, color: Color(0xFFFF2D55)),
    _ThreatCard(emoji: '☁️', title: 'هجمات السحابة', titleEn: 'Cloud-Native Attacks', body: 'استهداف بيانات السحابة. استخدم تشفير Zero-Knowledge.', xp: 30, color: Color(0xFF00CEC9)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppConstants.backgroundDark,
            pinned: true,
            title: const Text('أكاديمية التهديدات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    const Text('تعلّم وأكسب نقاطاً', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppConstants.accentGold.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppConstants.accentGold.withOpacity(0.3))),
                      child: const Row(children: [
                        Text('⭐', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text('150 XP', style: TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ThreatTile(card: _topics[i]),
                childCount: _topics.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatCard {
  final String emoji, title, titleEn, body;
  final int xp;
  final Color color;
  const _ThreatCard({required this.emoji, required this.title, required this.titleEn, required this.body, required this.xp, required this.color});
}

class _ThreatTile extends StatelessWidget {
  final _ThreatCard card;
  const _ThreatTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppConstants.surfaceDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _ThreatDetail(card: card),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card.color.withOpacity(0.2)),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [card.color.withOpacity(0.05), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 36)),
            const Spacer(),
            Text(card.title, style: TextStyle(color: card.color, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(card.titleEn, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppConstants.accentGold.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text('+${card.xp} XP', style: const TextStyle(color: AppConstants.accentGold, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreatDetail extends StatelessWidget {
  final _ThreatCard card;
  const _ThreatDetail({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(card.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(card.titleEn, style: const TextStyle(color: Colors.white38, fontSize: 13)),
            ]),
          ]),
          const SizedBox(height: 20),
          Text(card.body, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle_outline),
            label: Text('فهمت! (+${card.xp} XP)'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

