part of 'face_enrollment_bloc.dart';

abstract class FaceEnrollmentEvent {
  const FaceEnrollmentEvent();
}

/// Initialises the camera and ML services.
class FaceEnrollmentInitialized extends FaceEnrollmentEvent {
  const FaceEnrollmentInitialized();
}

/// User tapped the capture button — processes the current [cameraImage].
class FaceEnrollmentCaptureRequested extends FaceEnrollmentEvent {
  final CameraImage cameraImage;
  final Rect? faceBox;
  const FaceEnrollmentCaptureRequested({
    required this.cameraImage,
    required this.faceBox,
  });
}

/// Feeds a detected [Face] to the liveness service for anti-spoofing analysis.
class FaceEnrollmentFrameReceived extends FaceEnrollmentEvent {
  final Face face;
  const FaceEnrollmentFrameReceived({required this.face});
}

/// User wants to start over.
class FaceEnrollmentResetRequested extends FaceEnrollmentEvent {
  const FaceEnrollmentResetRequested();
}
