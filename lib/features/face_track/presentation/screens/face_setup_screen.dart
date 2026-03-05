// REPLACED by EPIC-6 ko8 implementation — full camera + BLoC enrollment.
// See face_enrollment_bloc.dart for state management.
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:meta/meta.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/face_track/data/services/face_detector_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_embedding_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_verification_service.dart';
import 'package:cipherowl/features/face_track/presentation/bloc/face_enrollment_bloc.dart';

/// Entry-point that creates the BLoC and wraps [_FaceSetupView].
///
/// [createBloc] can be supplied in tests to inject a pre-built
/// [FaceEnrollmentBloc] without initialising real camera / TFLite.
class FaceSetupScreen extends StatelessWidget {
  @visibleForTesting
  final FaceEnrollmentBloc Function()? createBloc;

  const FaceSetupScreen({super.key, this.createBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createBloc?.call() ?? FaceEnrollmentBloc(
        detector: FaceDetectorService(),
        embedding: FaceEmbeddingService(),
        verification: FaceVerificationService(),
      ),
      child: const _FaceSetupView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal view widget
// ─────────────────────────────────────────────────────────────────────────────

class _FaceSetupView extends StatefulWidget {
  const _FaceSetupView();

  @override
  State<_FaceSetupView> createState() => _FaceSetupViewState();
}

class _FaceSetupViewState extends State<_FaceSetupView>
    with TickerProviderStateMixin {
  CameraController? _cameraCtrl;
  CameraDescription? _camera;
  bool _cameraReady = false;
  bool _processing = false;
  bool _showIntro = true;

  // Live face detection overlay state
  Face? _currentFace;
  DateTime _lastDetection = DateTime.fromMillisecondsSinceEpoch(0);
  static const _detectionInterval = Duration(milliseconds: 350);
  // Holds the most recent raw CameraImage for the capture tap.
  CameraImage? _latestFrame;

  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    context.read<FaceEnrollmentBloc>().add(const FaceEnrollmentInitialized());
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraCtrl = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraCtrl!.initialize();
      if (!mounted) return;
      _cameraCtrl!.startImageStream(_onCameraImage);
      setState(() => _cameraReady = true);
    } catch (_) {
      // Camera unavailable (e.g. in widget tests or simulator without camera)
    }
  }

  void _onCameraImage(CameraImage image) {
    _latestFrame = image;
    final now = DateTime.now();
    if (now.difference(_lastDetection) < _detectionInterval) return;
    if (_processing) return;
    _lastDetection = now;

    final state = context.read<FaceEnrollmentBloc>().state;
    if (state is! FaceEnrollmentReady) return;

    _detectFaceOverlay(image);
  }

  Future<void> _detectFaceOverlay(CameraImage image) async {
    if (!mounted || _camera == null) return;
    final inputImage = FaceDetectorService.cameraImageToInputImage(
      image,
      _camera!,
    );
    try {
      final detectorSvc = FaceDetectorService();
      await detectorSvc.initialize();
      final face = await detectorSvc.detectLargestFace(inputImage);
      await detectorSvc.dispose();
      if (!mounted) return;
      setState(() => _currentFace = face);
    } catch (_) {
      // Ignore overlay errors.
    }
  }

  Future<void> _capture() async {
    if (_processing) return;
    final frame = _latestFrame;
    if (frame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكاميرا غير جاهزة بعد')),
      );
      return;
    }
    setState(() => _processing = true);
    context.read<FaceEnrollmentBloc>().add(
      FaceEnrollmentCaptureRequested(
        cameraImage: frame,
        faceBox: _currentFace?.boundingBox,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _processing = false);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _cameraCtrl?.stopImageStream();
    _cameraCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text(
          'إعداد Face-Track',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<FaceEnrollmentBloc, FaceEnrollmentState>(
        listener: (context, state) {
          if (state is FaceEnrollmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade800,
              ),
            );
            final bloc = context.read<FaceEnrollmentBloc>();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                bloc.add(const FaceEnrollmentResetRequested());
              }
            });
          }
        },
        builder: (context, state) {
          if (state is FaceEnrollmentInitial || state is FaceEnrollmentLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppConstants.primaryCyan),
                  SizedBox(height: 16),
                  Text(
                    'تهيئة نظام التعرف على الوجه…',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            );
          }
          if (state is FaceEnrollmentSuccess) return _buildDone();
          if (state is FaceEnrollmentProcessing) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppConstants.successGreen),
                  SizedBox(height: 16),
                  Text(
                    'جارٍ حفظ بصمة وجهك…',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            );
          }

          final capturesDone =
              state is FaceEnrollmentReady
                  ? state.capturesDone
                  : state is FaceEnrollmentCapturing
                  ? state.capturesDone
                  : 0;

          final targetPose =
              state is FaceEnrollmentReady ? state.targetPose : FacePose.front;

          if (_showIntro && capturesDone == 0) {
            return _buildIntro();
          }

          return _buildCapture(
            capturesDone: capturesDone,
            targetPose: targetPose,
            isCapturing: state is FaceEnrollmentCapturing || _processing,
          );
        },
      ),
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.primaryCyan.withValues(alpha: 0.3),
                width: 2,
              ),
              gradient: RadialGradient(
                colors: [
                  AppConstants.primaryCyan.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: Text('👁️', style: TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'كيف يعمل Face-Track؟',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _FeatureTile(
            icon: Icons.timer,
            title: 'مراقبة كل 300ms',
            color: AppConstants.primaryCyan,
          ),
          _FeatureTile(
            icon: Icons.lock,
            title: 'يقفل فوراً إذا ابتعدت',
            color: AppConstants.accentGold,
          ),
          _FeatureTile(
            icon: Icons.phone_android,
            title: 'يعمل محلياً بدون إنترنت',
            color: AppConstants.successGreen,
          ),
          _FeatureTile(
            icon: Icons.security,
            title: 'البيانات مشفرة على جهازك',
            color: const Color(0xFF8B5CF6),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _showIntro = false),
            child: const Text('ابدأ التسجيل'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'لاحقاً',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Capture ────────────────────────────────────────────────────────────────

  Widget _buildCapture({
    required int capturesDone,
    required FacePose targetPose,
    required bool isCapturing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i < capturesDone ? 24 : 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i < capturesDone
                      ? AppConstants.primaryCyan
                      : AppConstants.borderDark,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الالتقاط $capturesDone / 5',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _scanCtrl,
                builder: (_, __) {
                  final borderColor = _currentFace != null
                      ? AppConstants.successGreen
                      : AppConstants.primaryCyan;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: borderColor.withValues(
                                alpha: 0.1 + _scanCtrl.value * 0.15,
                              ),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      ClipOval(
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: _cameraReady && _cameraCtrl != null
                              ? CameraPreview(_cameraCtrl!)
                              : Container(
                                  color: AppConstants.surfaceDark,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppConstants.primaryCyan,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Scan line
                      ClipOval(
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: Align(
                            alignment: Alignment(0, (_scanCtrl.value * 2) - 1),
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    borderColor,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 264,
                        height: 264,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor.withValues(
                              alpha: 0.5 + _scanCtrl.value * 0.3,
                            ),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PoseGuidanceCard(
            pose: targetPose,
            faceDetected: _currentFace != null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCapturing ? null : _capture,
              icon: isCapturing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.backgroundDark,
                      ),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(isCapturing ? 'جارٍ التحليل…' : 'التقاط'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              context
                  .read<FaceEnrollmentBloc>()
                  .add(const FaceEnrollmentResetRequested());
              setState(() {
                _currentFace = null;
                _showIntro = true;
              });
            },
            child: const Text(
              'إعادة البدء',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Done ───────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.successGreen.withValues(alpha: 0.1),
              border: Border.all(
                color: AppConstants.successGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle,
                color: AppConstants.successGreen,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'تم تسجيل وجهك بنجاح! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Face-Track أصبح يعمل الآن.\nستُقفل الخزنة تلقائياً إذا ابتعدت.',
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('رائع! ✓'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PoseGuidanceCard extends StatelessWidget {
  final FacePose pose;
  final bool faceDetected;

  const _PoseGuidanceCard({required this.pose, required this.faceDetected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: faceDetected
              ? AppConstants.successGreen.withValues(alpha: 0.4)
              : AppConstants.borderDark,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(pose.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pose.labelAr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  faceDetected
                      ? '✓ وجه مكشوف — اضغط التقاط'
                      : 'ضع وجهك داخل الدائرة',
                  style: TextStyle(
                    color: faceDetected
                        ? AppConstants.successGreen
                        : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    ),
  );
}

