part of 'face_enrollment_bloc.dart';

abstract class FaceEnrollmentState {
  const FaceEnrollmentState();
}

/// Initial state before services are ready.
class FaceEnrollmentInitial extends FaceEnrollmentState {
  const FaceEnrollmentInitial();
}

/// Services are initialising.
class FaceEnrollmentLoading extends FaceEnrollmentState {
  const FaceEnrollmentLoading();
}

/// Camera + services ready. Shows live preview and pose guidance.
class FaceEnrollmentReady extends FaceEnrollmentState {
  /// Number of successful captures so far.
  final int capturesDone;

  /// The pose the user needs to achieve for the next capture.
  final FacePose targetPose;

  /// Whether a face satisfying [targetPose] is currently detected.
  final bool faceAligned;

  /// Live bounding box of the detected face (null if no face).
  final Rect? faceBox;

  const FaceEnrollmentReady({
    this.capturesDone = 0,
    this.targetPose = FacePose.front,
    this.faceAligned = false,
    this.faceBox,
  });

  FaceEnrollmentReady copyWith({
    int? capturesDone,
    FacePose? targetPose,
    bool? faceAligned,
    Rect? faceBox,
    bool clearFaceBox = false,
  }) {
    return FaceEnrollmentReady(
      capturesDone: capturesDone ?? this.capturesDone,
      targetPose: targetPose ?? this.targetPose,
      faceAligned: faceAligned ?? this.faceAligned,
      faceBox: clearFaceBox ? null : faceBox ?? this.faceBox,
    );
  }
}

/// A capture is being processed (TFLite inference running).
class FaceEnrollmentCapturing extends FaceEnrollmentState {
  final int capturesDone;
  const FaceEnrollmentCapturing({required this.capturesDone});
}

/// All 5 captures done; computing average embedding.
class FaceEnrollmentProcessing extends FaceEnrollmentState {
  const FaceEnrollmentProcessing();
}

/// Face successfully enrolled and stored.
class FaceEnrollmentSuccess extends FaceEnrollmentState {
  const FaceEnrollmentSuccess();
}

/// An error occurred (service init, TFLite, or storage failure).
class FaceEnrollmentError extends FaceEnrollmentState {
  final String message;
  final int capturesDone;
  const FaceEnrollmentError({required this.message, this.capturesDone = 0});
}
