import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Wraps Google ML Kit Face Detection for real-time face detection.
///
/// Detects faces from camera frames and provides helpers to filter for
/// well-aligned, large-enough faces suitable for embedding extraction.
class FaceDetectorService {
  FaceDetector? _detector;

  Future<void> initialize() async {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  bool get isInitialized => _detector != null;

  /// Detects all faces and returns the largest one, or null if none found.
  Future<Face?> detectLargestFace(InputImage inputImage) async {
    assert(_detector != null, 'Call initialize() first');
    final faces = await _detector!.processImage(inputImage);
    if (faces.isEmpty) return null;
    return faces.reduce(
      (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
    );
  }

  /// Returns true if the face is large enough and not too tilted for embedding.
  bool isFaceReady(Face face) {
    final box = face.boundingBox;
    if (box.width < 80 || box.height < 80) return false;
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;
    return yaw.abs() < 40 && pitch.abs() < 40 && roll.abs() < 40;
  }

  /// Checks if the face matches the required [pose] by euler angles.
  ///
  /// Used during enrollment to guide the user to specific head orientations.
  bool isFaceInPose(Face face, FacePose pose) {
    final yaw = face.headEulerAngleY ?? 0.0; // positive = right
    final pitch = face.headEulerAngleX ?? 0.0; // positive = down
    switch (pose) {
      case FacePose.front:
        return yaw.abs() < 15 && pitch.abs() < 15;
      case FacePose.left:
        return yaw < -15 && yaw > -40;
      case FacePose.right:
        return yaw > 15 && yaw < 40;
      case FacePose.up:
        return pitch < -10 && pitch > -35;
      case FacePose.down:
        return pitch > 10 && pitch < 35;
    }
  }

  /// Converts a [CameraImage] to an [InputImage] consumable by ML Kit.
  static InputImage cameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // Merge all planes into a single byte buffer.
    final builder = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      builder.add(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: builder.toBytes(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
  }
}

/// The 5 head orientations captured during face enrollment.
enum FacePose { front, left, right, up, down }

extension FacePoseInfo on FacePose {
  String get labelAr {
    switch (this) {
      case FacePose.front:
        return 'انظر للأمام مباشرة';
      case FacePose.left:
        return 'اتجه يساراً';
      case FacePose.right:
        return 'اتجه يميناً';
      case FacePose.up:
        return 'انظر للأعلى';
      case FacePose.down:
        return 'انظر للأسفل';
    }
  }

  String get emoji {
    switch (this) {
      case FacePose.front:
        return '😐';
      case FacePose.left:
        return '👈';
      case FacePose.right:
        return '👉';
      case FacePose.up:
        return '👆';
      case FacePose.down:
        return '👇';
    }
  }
}
