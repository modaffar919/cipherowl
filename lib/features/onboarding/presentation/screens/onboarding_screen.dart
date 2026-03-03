import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

/// Onboarding - shown only on first install (3 pages)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      emoji: '🦉',
      titleAr: 'حارسك الرقمي',
      titleEn: 'Your Digital Guardian',
      bodyAr: 'CipherOwl يحمي كل كلمات مرورك\nبتشفير عسكري AES-256-GCM',
      color: AppConstants.primaryCyan,
    ),
    _OnboardPage(
      emoji: '👁️',
      titleAr: 'Face-Track Lock',
      titleEn: 'Continuous Face Lock',
      bodyAr: 'يراقب وجهك كل 300ms.\nيقفل فوراً إذا غادرت الشاشة.',
      color: AppConstants.accentGold,
    ),
    _OnboardPage(
      emoji: '🏆',
      titleAr: 'اربح وأنت تحمي نفسك',
      titleEn: 'Earn While Staying Safe',
      bodyAr: 'اكسب نقاط وشارات وارتقِ من\nمبتدئ إلى أسطوري.',
      color: AppConstants.successGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _goSetup,
                child: const Text('تخطي', style: TextStyle(color: Colors.white38)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Dots + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? AppConstants.primaryCyan
                              : AppConstants.borderDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _page < _pages.length - 1 ? _next : _goSetup,
                      child: Text(_page < _pages.length - 1 ? 'التالي' : 'ابدأ الآن'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _ctrl.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goSetup() => context.go(AppConstants.routeSetup);
}

class _OnboardPage extends StatelessWidget {
  final String emoji;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final Color color;

  const _OnboardPage({
    required this.emoji,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area (TODO: replace with Rive animation)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1),
              gradient: RadialGradient(
                colors: [color.withOpacity(0.08), Colors.transparent],
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 80)),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            titleAr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            bodyAr,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
