import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Passive liveness detection using blink analysis, head motion, and texture.
///
/// Anti-spoofing checks:
///   1. **Blink detection** — real faces blink involuntarily (~15-20/min).
///      A printed photo or screen replay never blinks.
///   2. **Head micro-motion** — natural head sway vs perfectly still image.
///   3. **Texture analysis** — Laplacian variance and edge density distinguish
///      real faces from printed photos (blurry) and screen replays (pixel grid).
///
/// Usage during enrollment and background monitoring:
/// ```dart
/// final liveness = LivenessDetectionService();
/// liveness.addFrameWithTexture(face, grayscale, w, h);
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

  /// Laplacian variance below this → likely a printed photo (too blurry).
  static const double _minLaplacianVariance = 50.0;

  /// Laplacian variance above this → suspicious (too sharp / synthetic).
  static const double _maxLaplacianVariance = 500.0;

  /// Edge density below this → flat / blurry image.
  static const double _minEdgeDensity = 0.05;

  /// Edge density above this → screen pixel grid pattern.
  static const double _maxEdgeDensity = 0.5;

  /// Fraction of frames that must pass texture check.
  static const double _texturePassRatio = 0.6;

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

  /// Feed a detected face with grayscale pixel data for texture analysis.
  ///
  /// [grayscalePixels] is the luminance plane from the camera YUV frame,
  /// cropped to the face bounding box. [width] and [height] are the dimensions
  /// of the cropped region.
  void addFrameWithTexture(
    Face face,
    Uint8List grayscalePixels,
    int width,
    int height,
  ) {
    final now = DateTime.now();
    _frames.removeWhere(
        (f) => now.difference(f.timestamp) > _windowDuration);

    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final avgEye = (leftEye + rightEye) / 2;

    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;

    final laplacian = _laplacianVariance(grayscalePixels, width, height);
    final edges = _edgeDensity(grayscalePixels, width, height);

    _frames.add(_FrameData(
      timestamp: now,
      eyeOpenProb: avgEye,
      yaw: yaw,
      pitch: pitch,
      laplacianVariance: laplacian,
      edgeDensity: edges,
    ));

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
  ///   - Sufficient head micro-motion detected,
  /// AND:
  ///   - Texture analysis passes (if texture data was provided).
  bool get isLive {
    if (_frames.length < 10) return false; // need enough data
    final motionOrBlink = _hasBlinkEvidence || _hasMotionEvidence;
    // If no texture data was supplied (legacy addFrame path), skip texture check.
    final hasAnyTexture = _frames.any((f) => f.laplacianVariance != null);
    if (!hasAnyTexture) return motionOrBlink;
    return motionOrBlink && _hasTextureEvidence;
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

  /// Whether texture analysis indicates a real face.
  ///
  /// Printed photos: low Laplacian variance (blurry / flat).
  /// Screen replays: high edge density (pixel grid artefacts).
  /// Real faces: moderate Laplacian + moderate edge density.
  bool get _hasTextureEvidence {
    final textureFrames =
        _frames.where((f) => f.laplacianVariance != null).toList();
    if (textureFrames.isEmpty) return false;

    int passed = 0;
    for (final f in textureFrames) {
      final lap = f.laplacianVariance!;
      final edge = f.edgeDensity!;
      if (lap >= _minLaplacianVariance &&
          lap <= _maxLaplacianVariance &&
          edge >= _minEdgeDensity &&
          edge <= _maxEdgeDensity) {
        passed++;
      }
    }
    return passed / textureFrames.length >= _texturePassRatio;
  }

  /// Whether texture evidence is available.
  bool get hasTextureData =>
      _frames.any((f) => f.laplacianVariance != null);

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

  // ── Texture analysis helpers ─────────────────────────────────────────────

  /// Compute Laplacian variance of a grayscale image.
  ///
  /// Uses the 3×3 Laplacian kernel `[[0,1,0],[1,-4,1],[0,1,0]]` and returns
  /// the variance of the convolution output. Low variance ⇒ blurry (photo).
  static double _laplacianVariance(
      Uint8List pixels, int width, int height) {
    if (width < 3 || height < 3) return 0.0;
    final int count = (width - 2) * (height - 2);
    double sum = 0;
    double sumSq = 0;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final lap = -4 * pixels[y * width + x] +
            pixels[(y - 1) * width + x] +
            pixels[(y + 1) * width + x] +
            pixels[y * width + (x - 1)] +
            pixels[y * width + (x + 1)];
        final d = lap.toDouble();
        sum += d;
        sumSq += d * d;
      }
    }
    final mean = sum / count;
    return (sumSq / count) - mean * mean;
  }

  /// Compute edge density using Sobel operator.
  ///
  /// Returns the ratio of pixels whose gradient magnitude exceeds a threshold.
  /// Screen replays have high density (pixel grid); photos are lower.
  static double _edgeDensity(
      Uint8List pixels, int width, int height) {
    if (width < 3 || height < 3) return 0.0;
    const threshold = 50;
    int edgeCount = 0;
    final int count = (width - 2) * (height - 2);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        // Sobel X
        final gx = -pixels[(y - 1) * width + (x - 1)] +
            pixels[(y - 1) * width + (x + 1)] -
            2 * pixels[y * width + (x - 1)] +
            2 * pixels[y * width + (x + 1)] -
            pixels[(y + 1) * width + (x - 1)] +
            pixels[(y + 1) * width + (x + 1)];
        // Sobel Y
        final gy = -pixels[(y - 1) * width + (x - 1)] -
            2 * pixels[(y - 1) * width + x] -
            pixels[(y - 1) * width + (x + 1)] +
            pixels[(y + 1) * width + (x - 1)] +
            2 * pixels[(y + 1) * width + x] +
            pixels[(y + 1) * width + (x + 1)];
        final mag = math.sqrt((gx * gx + gy * gy).toDouble());
        if (mag > threshold) edgeCount++;
      }
    }
    return edgeCount / count;
  }
}

class _FrameData {
  final DateTime timestamp;
  final double eyeOpenProb;
  final double yaw;
  final double pitch;
  final double? laplacianVariance;
  final double? edgeDensity;

  const _FrameData({
    required this.timestamp,
    required this.eyeOpenProb,
    required this.yaw,
    required this.pitch,
    this.laplacianVariance,
    this.edgeDensity,
  });
}
