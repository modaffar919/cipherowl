import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

/// Enterprise Screen — LDAP, SSO, Group Management
class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({super.key});

  static const _features = [
    _EnterpriseFeature(icon: Icons.business_center, title: 'نشر المؤسسة', desc: 'إدارة مركزية لجميع الموظفين', color: Color(0xFF3B82F6)),
    _EnterpriseFeature(icon: Icons.people_alt, title: 'مجموعات المستخدمين', desc: 'قسّم الصلاحيات حسب الفريق', color: Color(0xFF8B5CF6)),
    _EnterpriseFeature(icon: Icons.vpn_key, title: 'LDAP / Active Directory', desc: 'تكامل مع بنيتك التحتية', color: Color(0xFF06D6A0)),
    _EnterpriseFeature(icon: Icons.account_circle, title: 'تسجيل دخول موحد (SSO)', desc: 'SAML 2.0 / OAuth 2.0 / OIDC', color: Color(0xFFFF6B6B)),
    _EnterpriseFeature(icon: Icons.policy, title: 'سياسات كلمات المرور', desc: 'أحكم قيود التعقيد والانتهاء', color: Color(0xFFFFD166)),
    _EnterpriseFeature(icon: Icons.bar_chart, title: 'تقارير الامتثال', desc: 'SOC 2, ISO 27001, GDPR', color: Color(0xFF00CEC9)),
    _EnterpriseFeature(icon: Icons.lock_clock, title: 'الوصول في الوقت المناسب', desc: 'Just-In-Time access بدون كلمات مرور ثابتة', color: Color(0xFFFF8C42)),
    _EnterpriseFeature(icon: Icons.devices, title: 'إدارة الأجهزة', desc: 'القائمة البيضاء والحظر عن بُعد', color: Color(0xFF7B2FBE)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text('وضع المؤسسة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF3B82F6).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.2)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.business, color: Color(0xFF3B82F6), size: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                            Text('CipherOwl Enterprise', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('حماية شاملة لفرق العمل والمؤسسات', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppConstants.accentGold.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppConstants.accentGold.withOpacity(0.3))),
                          child: const Text('PRO', style: TextStyle(color: AppConstants.accentGold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('الميزات المؤسسية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Features grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _FeatureCard(feature: _features[i]),
                childCount: _features.length,
              ),
            ),
          ),

          // CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.borderDark),
                    ),
                    child: Column(
                      children: const [
                        Text('كم موظفاً في فريقك؟', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text('تواصل معنا للحصول على سعر مخصص للمؤسسات', style: TextStyle(color: Colors.white60, fontSize: 13), textAlign: TextAlign.center),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('تواصل مع فريق المبيعات'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterpriseFeature {
  final IconData icon; final String title, desc; final Color color;
  const _EnterpriseFeature({required this.icon, required this.title, required this.desc, required this.color});
}

class _FeatureCard extends StatelessWidget {
  final _EnterpriseFeature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppConstants.cardDark,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: feature.color.withOpacity(0.2)),
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [feature.color.withOpacity(0.05), Colors.transparent],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: feature.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(feature.icon, color: feature.color, size: 20)),
        const Spacer(),
        Text(feature.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(feature.desc, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 2),
      ],
    ),
  );
}

