import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

/// Face-Track Setup — enroll user face embeddings via MobileFaceNet
class FaceSetupScreen extends StatefulWidget {
  const FaceSetupScreen({super.key});
  @override
  State<FaceSetupScreen> createState() => _FaceSetupScreenState();
}

class _FaceSetupScreenState extends State<FaceSetupScreen>
    with TickerProviderStateMixin {
  int _step = 0; // 0=intro, 1=capture, 2=done
  bool _isProcessing = false;
  int _captureCount = 0;
  static const _totalCaptures = 5;

  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text('إعداد Face-Track', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          0 => _buildIntro(),
          1 => _buildCapture(),
          _ => _buildDone(),
        },
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.primaryCyan.withOpacity(0.3), width: 2),
              gradient: RadialGradient(colors: [AppConstants.primaryCyan.withOpacity(0.1), Colors.transparent]),
            ),
            child: const Center(child: Text('👁️', style: TextStyle(fontSize: 64))),
          ),
          const SizedBox(height: 32),
          const Text('كيف يعمل Face-Track؟', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _FeatureTile(icon: Icons.timer, title: 'مراقبة كل 300ms', color: AppConstants.primaryCyan),
          _FeatureTile(icon: Icons.lock, title: 'يقفل فوراً إذا ابتعدت', color: AppConstants.accentGold),
          _FeatureTile(icon: Icons.phone_android, title: 'يعمل محلياً بدون إنترنت', color: AppConstants.successGreen),
          _FeatureTile(icon: Icons.security, title: 'البيانات مشفرة على جهازك', color: Color(0xFF8B5CF6)),
          const Spacer(),
          ElevatedButton(onPressed: () => setState(() => _step = 1), child: const Text('ابدأ التسجيل')),
          const SizedBox(height: 12),
          TextButton(onPressed: () => context.pop(), child: const Text('لاحقاً', style: TextStyle(color: Colors.white38))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCapture() {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('التقاط $_captureCount / $_totalCaptures', style: const TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 24),

          // Face frame
          AnimatedBuilder(
            animation: _scanCtrl,
            builder: (_, __) => Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.primaryCyan.withOpacity(0.4 + _scanCtrl.value * 0.4),
                  width: 2,
                ),
                boxShadow: [BoxShadow(color: AppConstants.primaryCyan.withOpacity(0.1 + _scanCtrl.value * 0.1), blurRadius: 20)],
              ),
              child: Stack(
                children: [
                  // Camera placeholder
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.surfaceDark,
                    ),
                    child: const Center(child: Text('📸', style: TextStyle(fontSize: 72))),
                  ),

                  // Scan line
                  Positioned(
                    top: 260 * _scanCtrl.value - 1,
                    left: 20, right: 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          AppConstants.primaryCyan,
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalCaptures, (i) => Container(
              width: i < _captureCount ? 24 : 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i < _captureCount ? AppConstants.primaryCyan : AppConstants.borderDark,
                borderRadius: BorderRadius.circular(6),
              ),
            )),
          ),

          const SizedBox(height: 32),
          const Text('ضع وجهك داخل الدائرة وانظر مباشرة للشاشة', style: TextStyle(color: Colors.white60, fontSize: 14), textAlign: TextAlign.center),
          const Spacer(),

          ElevatedButton(
            onPressed: _isProcessing ? null : _capture,
            child: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.backgroundDark))
                : const Text('التقاط'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.successGreen.withOpacity(0.1),
              border: Border.all(color: AppConstants.successGreen.withOpacity(0.3), width: 2),
            ),
            child: const Center(child: Icon(Icons.check_circle, color: AppConstants.successGreen, size: 56)),
          ),
          const SizedBox(height: 24),
          const Text('تم تسجيل وجهك بنجاح!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Face-Track أصبح يعمل الآن.\nستُقفل الخزنة تلقائياً إذا ابتعدت.', style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: () => context.pop(), child: const Text('رائع! ✓')),
        ],
      ),
    );
  }

  Future<void> _capture() async {
    setState(() => _isProcessing = true);
    // TODO: Use google_mlkit_face_detection + Rust embedding
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _captureCount++;
      if (_captureCount >= _totalCaptures) _step = 2;
    });
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon; final String title; final Color color;
  const _FeatureTile({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    ]),
  );
}
