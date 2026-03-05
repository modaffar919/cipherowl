import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'package:cipherowl/features/face_track/data/services/face_detector_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_embedding_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_verification_service.dart';

/// Background Face-Track monitoring service.
///
/// Continuously grabs frames from the front camera, runs face detection →
/// embedding extraction → cosine similarity verification every 300 ms.
///
/// When the face is absent or the similarity score drops below the
/// enrolled threshold, [onVerificationFailed] is invoked after
/// [failureThreshold] consecutive failed frames.  The caller (typically
/// AuthBloc) should respond by dispatching `AuthVaultLocked`.
///
/// Usage:
/// ```dart
/// final monitor = BackgroundFaceMonitor(
///   onVerificationFailed: () => authBloc.add(const AuthVaultLocked()),
/// );
/// await monitor.start();
/// // ... user in session ...
/// await monitor.stop();
/// ```
class BackgroundFaceMonitor {
  /// Callback fired when face verification fails [failureThreshold] times.
  final VoidCallback onVerificationFailed;

  /// Consecutive failed checks before locking. Default 3 (≈900 ms grace).
  final int failureThreshold;

  BackgroundFaceMonitor({
    required this.onVerificationFailed,
    this.failureThreshold = 3,
  });

  CameraController? _cameraCtrl;
  final FaceDetectorService _detector = FaceDetectorService();
  final FaceEmbeddingService _embedding = FaceEmbeddingService();
  final FaceVerificationService _verification = FaceVerificationService();

  Timer? _checkTimer;
  bool _running = false;
  bool _busy = false;
  int _consecutiveFailures = 0;

  // Latest camera frame (updated by imageStream, consumed by _check).
  CameraImage? _latestFrame;
  CameraDescription? _cameraDescription;

  // ── Public API ─────────────────────────────────────────────────────────────

  bool get isRunning => _running;

  /// Initialises camera and services, starts the 300 ms check loop.
  ///
  /// No-ops if already running.
  Future<void> start() async {
    if (_running) return;

    // Nothing to verify if the user hasn't enrolled.
    final hasEnrolled = await _verification.hasEnrolledFace();
    if (!hasEnrolled) return;

    await Future.wait([_detector.initialize(), _embedding.initialize()]);

    final cameras = await availableCameras();
    _cameraDescription = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraCtrl = CameraController(
      _cameraDescription!,
      ResolutionPreset.low, // Low res is enough for face detection.
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cameraCtrl!.initialize();
    _cameraCtrl!.startImageStream((img) => _latestFrame = img);

    _running = true;
    _consecutiveFailures = 0;

    _checkTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _check(),
    );
  }

  /// Stops the monitoring loop and releases camera resources.
  Future<void> stop() async {
    _checkTimer?.cancel();
    _checkTimer = null;
    _running = false;

    await _cameraCtrl?.stopImageStream();
    await _cameraCtrl?.dispose();
    _cameraCtrl = null;

    await _detector.dispose();
    _embedding.dispose();
  }

  // ── Internal check ─────────────────────────────────────────────────────────

  Future<void> _check() async {
    if (!_running || _busy) return;
    final frame = _latestFrame;
    if (frame == null || _cameraDescription == null) return;

    _busy = true;
    try {
      final inputImage = FaceDetectorService.cameraImageToInputImage(
        frame,
        _cameraDescription!,
      );

      final face = await _detector.detectLargestFace(inputImage);
      if (face == null || !_detector.isFaceReady(face)) {
        _handleFailure();
        return;
      }

      final embedding = await _embedding.getEmbeddingFromCamera(
        cameraImage: frame,
        boundingBox: face.boundingBox,
      );
      if (embedding == null) {
        _handleFailure();
        return;
      }

      final verified = await _verification.verify(embedding);
      if (verified) {
        _consecutiveFailures = 0;
      } else {
        _handleFailure();
      }
    } catch (e) {
      debugPrint('[FaceMonitor] check error: $e');
      // On unexpected errors, don't penalise — could be a transient issue.
    } finally {
      _busy = false;
    }
  }

  void _handleFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= failureThreshold) {
      _consecutiveFailures = 0;
      // Avoid calling back from a disposed widget tree.
      if (_running) {
        onVerificationFailed();
      }
    }
  }
}
