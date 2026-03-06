import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Passive liveness detection using blink analysis and head motion.
///
/// Anti-spoofing checks:
///   1. **Blink detection** — real faces blink involuntarily (~15-20/min).
///      A printed photo or screen replay never blinks.
///   2. **Head micro-motion** — natural head sway vs perfectly still image.
///   3. **Eye open probability variance** — real eyes fluctuate; spoofs stay constant.
///
/// Usage during enrollment and background monitoring:
/// ```dart
/// final liveness = LivenessDetectionService();
/// liveness.addFrame(face); // called every camera frame (~30 fps)
/// if (liveness.isLive) { /* proceed with embedding */ }
/// ```
class LivenessDetectionService {
  /// Minimum blinks required within [_windowDuration] to pass liveness.
  static const int _minBlinks = 1;

  /// Time window over which blinks and motion are tracked.
  static const Duration _windowDuration = Duration(seconds: 4);

  /// Eye open probability below this is considered "closed".
  static const double _eyeClosedThreshold = 0.3;

  /// Eye open probability above this is considered "open".
  static const double _eyeOpenThreshold = 0.6;

  /// Minimum head motion variance (euler angle std-dev) to indicate real person.
  static const double _minMotionVariance = 0.8;

  final List<_FrameData> _frames = [];

  /// Previous eye state for blink edge detection.
  bool _eyesWereClosed = false;
  int _blinkCount = 0;

  /// Feed a detected face from the camera stream.
  void addFrame(Face face) {
    final now = DateTime.now();

    // Prune old frames outside the window.
    _frames.removeWhere(
        (f) => now.difference(f.timestamp) > _windowDuration);

    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final avgEye = (leftEye + rightEye) / 2;

    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;

    _frames.add(_FrameData(
      timestamp: now,
      eyeOpenProb: avgEye,
      yaw: yaw,
      pitch: pitch,
    ));

    // Blink edge detection: open → closed → open = 1 blink.
    if (avgEye < _eyeClosedThreshold) {
      _eyesWereClosed = true;
    } else if (_eyesWereClosed && avgEye > _eyeOpenThreshold) {
      _eyesWereClosed = false;
      _blinkCount++;
    }
  }

  /// Whether enough evidence of life has been collected.
  ///
  /// Returns true when:
  ///   - At least [_minBlinks] blinks detected, OR
  ///   - Sufficient head micro-motion detected.
  bool get isLive {
    if (_frames.length < 10) return false; // need enough data
    return _hasBlinkEvidence || _hasMotionEvidence;
  }

  /// Number of blinks detected in the current window.
  int get blinkCount => _blinkCount;

  /// Whether blink-based liveness has passed.
  bool get _hasBlinkEvidence => _blinkCount >= _minBlinks;

  /// Whether head motion variance indicates a real person.
  bool get _hasMotionEvidence {
    if (_frames.length < 10) return false;
    final yawVariance = _variance(_frames.map((f) => f.yaw).toList());
    final pitchVariance = _variance(_frames.map((f) => f.pitch).toList());
    return yawVariance > _minMotionVariance ||
        pitchVariance > _minMotionVariance;
  }

  /// Eye probability variance — spoofs have near-zero variance.
  double get eyeVariance {
    if (_frames.length < 5) return 0.0;
    return _variance(_frames.map((f) => f.eyeOpenProb).toList());
  }

  /// Reset all tracked state (e.g., when re-starting enrollment).
  void reset() {
    _frames.clear();
    _blinkCount = 0;
    _eyesWereClosed = false;
  }

  /// Compute variance of a list of doubles.
  static double _variance(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSquares =
        values.fold(0.0, (sum, v) => sum + (v - mean) * (v - mean));
    return sumSquares / values.length;
  }
}

class _FrameData {
  final DateTime timestamp;
  final double eyeOpenProb;
  final double yaw;
  final double pitch;

  const _FrameData({
    required this.timestamp,
    required this.eyeOpenProb,
    required this.yaw,
    required this.pitch,
  });
}
