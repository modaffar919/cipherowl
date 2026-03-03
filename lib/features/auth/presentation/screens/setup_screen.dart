import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

/// First-time setup — creates master password + recovery key
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _BuildProgress(current: _currentPage, total: 4),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _SetupPage1(onNext: _nextPage),   // Create master password
                  _SetupPage2(onNext: _nextPage),   // Recovery key (BIP39)
                  _SetupPage3(onNext: _nextPage),   // Face setup (optional)
                  _SetupPage4(onDone: _complete),   // Done
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _complete() => context.go(AppConstants.routeDashboard);
}

class _BuildProgress extends StatelessWidget {
  final int current;
  final int total;
  const _BuildProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= current;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: active
                    ? AppConstants.primaryCyan
                    : AppConstants.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SetupPage1 extends StatefulWidget {
  final VoidCallback onNext;
  const _SetupPage1({required this.onNext});
  @override
  State<_SetupPage1> createState() => _SetupPage1State();
}

class _SetupPage1State extends State<_SetupPage1> {
  final _ctrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  double _strength = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('🔒', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          const Text(
            'أنشئ كلمة مرور رئيسية',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'هذه الكلمة هي المفتاح الوحيد لخزنتك.\nاجعلها قوية ولا تشاركها مع أحد.',
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _ctrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'SpaceMono'),
            decoration: const InputDecoration(labelText: 'كلمة المرور الرئيسية'),
            onChanged: (v) {
              // TODO: Use zxcvbn for real strength
              setState(() => _strength = (v.length / 20).clamp(0.0, 1.0));
            },
          ),

          const SizedBox(height: 8),
          // Strength bar
          LinearProgressIndicator(
            value: _strength,
            backgroundColor: AppConstants.borderDark,
            color: _strength < 0.4
                ? AppConstants.errorRed
                : _strength < 0.7
                    ? AppConstants.warningAmber
                    : AppConstants.successGreen,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'SpaceMono'),
            decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
          ),

          const Spacer(),
          ElevatedButton(
            onPressed: _ctrl.text.length >= 12 && _ctrl.text == _confirmCtrl.text
                ? widget.onNext
                : null,
            child: const Text('التالي'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SetupPage2 extends StatelessWidget {
  final VoidCallback onNext;
  const _SetupPage2({required this.onNext});

  @override
  Widget build(BuildContext context) {
    // TODO: Generate real BIP39 mnemonic via Rust
    const mnemonic = 'abandon ability able about above absent absorb abstract '
        'absurd abuse access accident account accuse achieve acid '
        'acoustic acquire across act action actor';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('🔑', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          const Text(
            'مفتاح الاسترداد',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'احفظ هذه الكلمات الـ 24 في مكان آمن. هي الطريقة الوحيدة لاسترداد حسابك.',
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.primaryCyan.withOpacity(0.3)),
            ),
            child: Text(
              mnemonic,
              style: const TextStyle(
                color: AppConstants.primaryCyan,
                fontFamily: 'SpaceMono',
                fontSize: 13,
                height: 1.8,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.errorRed.withOpacity(0.3)),
            ),
            child: const Text(
              '⚠️ لا تأخذ لقطة شاشة. احفظها يدوياً أو اطبعها.',
              style: TextStyle(color: AppConstants.errorRed, fontSize: 13),
            ),
          ),

          const Spacer(),
          ElevatedButton(onPressed: onNext, child: const Text('لقد حفظتها بأمان ✓')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SetupPage3 extends StatelessWidget {
  final VoidCallback onNext;
  const _SetupPage3({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('👁️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          const Text(
            'تفعيل Face-Track',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'CipherOwl يراقب وجهك باستمرار. إذا ابتعدت — يقفل فوراً.',
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.go(AppConstants.routeFaceSetup),
            child: const Text('إعداد Face-Track'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onNext,
            child: const Text('تخطي الآن'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SetupPage4 extends StatelessWidget {
  final VoidCallback onDone;
  const _SetupPage4({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text(
            'خزنتك جاهزة!',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'بياناتك محمية بـ AES-256-GCM\nالخزنة مشفرة بالكامل على جهازك',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 48),
          ElevatedButton(onPressed: onDone, child: const Text('ادخل إلى خزنتك 🔓')),
        ],
      ),
    );
  }
}

