import 'dart:async';
import 'dart:ui' show Rect;

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:cipherowl/features/face_track/data/services/face_detector_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_embedding_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_verification_service.dart';
import 'package:cipherowl/features/face_track/data/services/liveness_detection_service.dart';

part 'face_enrollment_event.dart';
part 'face_enrollment_state.dart';

/// Orchestrates the 5-pose face enrollment flow.
///
/// Dependency: [FaceDetectorService], [FaceEmbeddingService],
/// [FaceVerificationService].
///
/// Flow: init → capture ×5 (one per pose) → enroll (average + store) → success
class FaceEnrollmentBloc
    extends Bloc<FaceEnrollmentEvent, FaceEnrollmentState> {
  final FaceDetectorService _detector;
  final FaceEmbeddingService _embedding;
  final FaceVerificationService _verification;
  final LivenessDetectionService _liveness = LivenessDetectionService();

  static const List<FacePose> _poses = FacePose.values; // front,left,right,up,down
  final List<List<double>> _captures = [];

  FaceEnrollmentBloc({
    required FaceDetectorService detector,
    required FaceEmbeddingService embedding,
    required FaceVerificationService verification,
  }) : _detector = detector,
       _embedding = embedding,
       _verification = verification,
       super(const FaceEnrollmentInitial()) {
    on<FaceEnrollmentInitialized>(_onInitialized);
    on<FaceEnrollmentCaptureRequested>(_onCaptureRequested);
    on<FaceEnrollmentFrameReceived>(_onFrameReceived);
    on<FaceEnrollmentResetRequested>(_onResetRequested);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onInitialized(
    FaceEnrollmentInitialized event,
    Emitter<FaceEnrollmentState> emit,
  ) async {
    emit(const FaceEnrollmentLoading());
    try {
      await Future.wait([_detector.initialize(), _embedding.initialize()]);
      emit(const FaceEnrollmentReady());
    } catch (e) {
      emit(FaceEnrollmentError(message: 'فشل تهيئة الخدمات: $e'));
    }
  }

  Future<void> _onCaptureRequested(
    FaceEnrollmentCaptureRequested event,
    Emitter<FaceEnrollmentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FaceEnrollmentReady) return;

    final done = currentState.capturesDone;
    emit(FaceEnrollmentCapturing(capturesDone: done));

    try {
      Rect? box = event.faceBox;

      // If no box was pre-computed, detect the face now.
      if (box == null) {
        // Screen always provides faceBox from live detection.
        // If somehow it's null, ask the user to retry.
        emit(FaceEnrollmentError(
          message: 'لم يُكشف وجه. تأكد أن الكاميرا تعمل وحاول مجدداً.',
          capturesDone: done,
        ));
        return;
      }

      final embedding = await _embedding.getEmbeddingFromCamera(
        cameraImage: event.cameraImage,
        boundingBox: box,
      );

      if (embedding == null) {
        emit(FaceEnrollmentError(
          message: 'فشل تحليل الوجه. حاول مجدداً.',
          capturesDone: done,
        ));
        return;
      }

      _captures.add(embedding);

      if (_captures.length >= _poses.length) {
        // All 5 captures done — verify liveness before enrolling.
        if (!_liveness.isLive) {
          _captures.removeLast();
          emit(FaceEnrollmentError(
            message: 'فشل التحقق من الحياة — ارمش أو حرّك رأسك قليلاً.',
            capturesDone: _captures.length,
          ));
          return;
        }
        emit(const FaceEnrollmentProcessing());
        await _verification.enroll(_captures);
        emit(const FaceEnrollmentSuccess());
      } else {
        final nextPose = _poses[_captures.length];
        emit(FaceEnrollmentReady(
          capturesDone: _captures.length,
          targetPose: nextPose,
          faceAligned: false,
        ));
      }
    } catch (e) {
      emit(FaceEnrollmentError(
        message: 'خطأ أثناء الالتقاط: $e',
        capturesDone: done,
      ));
    }
  }

  void _onFrameReceived(
    FaceEnrollmentFrameReceived event,
    Emitter<FaceEnrollmentState> emit,
  ) {
    _liveness.addFrame(event.face);
  }

  Future<void> _onResetRequested(
    FaceEnrollmentResetRequested event,
    Emitter<FaceEnrollmentState> emit,
  ) async {
    _captures.clear();
    _liveness.reset();
    emit(const FaceEnrollmentReady());
  }

  @override
  Future<void> close() async {
    await _detector.dispose();
    _embedding.dispose();
    return super.close();
  }
}


