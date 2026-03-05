// Unit tests for FaceEnrollmentBloc â€” cipherowl-gbw (EPIC-15)
//
// All platform services (ML Kit, TFLite, SecureStorage) are mocked so these
// tests run on any host without a physical device or native libraries.
// Written as plain async tests (no blocTest) to avoid mocktail argument-matcher
// leaks across setUp callbacks.

import 'dart:ui' show Rect;

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipherowl/features/face_track/data/services/face_detector_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_embedding_service.dart';
import 'package:cipherowl/features/face_track/data/services/face_verification_service.dart';
import 'package:cipherowl/features/face_track/presentation/bloc/face_enrollment_bloc.dart';

// â”€â”€ Mocks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class MockFaceDetectorService extends Mock implements FaceDetectorService {}

class MockFaceEmbeddingService extends Mock implements FaceEmbeddingService {}

class MockFaceVerificationService extends Mock
    implements FaceVerificationService {}

// Using a Fake avoids constructing a real CameraImage (platform-dependent).
class _FakeCameraImage extends Fake implements CameraImage {}

const _kBox = Rect.fromLTWH(100, 100, 200, 200);

List<double> _embedding() => List.filled(128, 0.1);

// â”€â”€ Helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Creates fresh mocks with dispose stubs always set, builds the bloc.
({FaceEnrollmentBloc bloc, MockFaceDetectorService detector,
    MockFaceEmbeddingService embedding,
    MockFaceVerificationService verification})
    _freshMocks() {
  final detector = MockFaceDetectorService();
  final embedding = MockFaceEmbeddingService();
  final verification = MockFaceVerificationService();
  when(() => detector.dispose()).thenAnswer((_) async {});
  when(() => embedding.dispose()).thenReturn(null);
  final bloc = FaceEnrollmentBloc(
    detector: detector,
    embedding: embedding,
    verification: verification,
  );
  return (bloc: bloc, detector: detector, embedding: embedding,
      verification: verification);
}

// â”€â”€ Tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCameraImage());
    registerFallbackValue(_kBox);
    registerFallbackValue(<List<double>>[]);
  });

  group('FaceEnrollmentBloc', () {
    // â”€â”€ Initial state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    test('initial state is FaceEnrollmentInitial', () async {
      final m = _freshMocks();
      expect(m.bloc.state, isA<FaceEnrollmentInitial>());
      await m.bloc.close();
    });

    // â”€â”€ FaceEnrollmentInitialized â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('FaceEnrollmentInitialized', () {
      test('emits [Loading, Ready] when services initialise successfully',
          () async {
        final m = _freshMocks();
        when(() => m.detector.initialize()).thenAnswer((_) async {});
        when(() => m.embedding.initialize()).thenAnswer((_) async {});

        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        m.bloc.add(const FaceEnrollmentInitialized());
        await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentReady);

        expect(states[0], isA<FaceEnrollmentLoading>());
        final ready = states[1] as FaceEnrollmentReady;
        expect(ready.capturesDone, 0);
        expect(ready.targetPose, FacePose.front);

        await sub.cancel();
        await m.bloc.close();
      });

      test('emits [Loading, Error] when detector.initialize throws', () async {
        final m = _freshMocks();
        when(() => m.detector.initialize())
            .thenThrow(Exception('camera unavailable'));
        when(() => m.embedding.initialize()).thenAnswer((_) async {});

        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        m.bloc.add(const FaceEnrollmentInitialized());
        await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentError);

        expect(states[0], isA<FaceEnrollmentLoading>());
        expect(states[1], isA<FaceEnrollmentError>());

        await sub.cancel();
        await m.bloc.close();
      });
    });

    // â”€â”€ FaceEnrollmentCaptureRequested â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('FaceEnrollmentCaptureRequested', () {
      test('emits [Capturing, Ready(done=1)] after first successful capture',
          () async {
        final m = _freshMocks();
        when(() => m.embedding.getEmbeddingFromCamera(
              cameraImage: any(named: 'cameraImage'),
              boundingBox: any(named: 'boundingBox'),
            )).thenAnswer((_) async => _embedding());
        m.bloc.emit(const FaceEnrollmentReady(capturesDone: 0));

        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        m.bloc.add(FaceEnrollmentCaptureRequested(
          cameraImage: _FakeCameraImage(),
          faceBox: _kBox,
        ));
        await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentReady);

        expect(states.first, isA<FaceEnrollmentCapturing>());
        final ready = states.last as FaceEnrollmentReady;
        expect(ready.capturesDone, 1);
        expect(ready.targetPose, FacePose.left);

        await sub.cancel();
        await m.bloc.close();
      });

      test('emits [Capturing, Error] when embedding returns null', () async {
        final m = _freshMocks();
        when(() => m.embedding.getEmbeddingFromCamera(
              cameraImage: any(named: 'cameraImage'),
              boundingBox: any(named: 'boundingBox'),
            )).thenAnswer((_) async => null);
        m.bloc.emit(const FaceEnrollmentReady(capturesDone: 0));

        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        m.bloc.add(FaceEnrollmentCaptureRequested(
          cameraImage: _FakeCameraImage(),
          faceBox: _kBox,
        ));
        await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentError);

        expect(states.first, isA<FaceEnrollmentCapturing>());
        expect(states.last, isA<FaceEnrollmentError>());

        await sub.cancel();
        await m.bloc.close();
      });

      test('emits [Capturing, Error] when faceBox is null', () async {
        final m = _freshMocks();
        m.bloc.emit(const FaceEnrollmentReady(capturesDone: 0));

        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        m.bloc.add(FaceEnrollmentCaptureRequested(
          cameraImage: _FakeCameraImage(),
          faceBox: null,
        ));
        await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentError);

        expect(states.last, isA<FaceEnrollmentError>());
        expect((states.last as FaceEnrollmentError).message, isNotEmpty);

        await sub.cancel();
        await m.bloc.close();
      });

      test('completes enrollment after 5 captures â†’ emits Success', () async {
        final m = _freshMocks();
        when(() => m.embedding.getEmbeddingFromCamera(
              cameraImage: any(named: 'cameraImage'),
              boundingBox: any(named: 'boundingBox'),
            )).thenAnswer((_) async => _embedding());
        when(() => m.verification.enroll(any()))
            .thenAnswer((_) async {});

        m.bloc.emit(const FaceEnrollmentReady());

        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        // Chain 4 captures, waiting for Ready state between each.
        for (int i = 0; i < 4; i++) {
          m.bloc.add(FaceEnrollmentCaptureRequested(
            cameraImage: _FakeCameraImage(),
            faceBox: _kBox,
          ));
          await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentReady);
        }
        // 5th capture completes enrollment.
        m.bloc.add(FaceEnrollmentCaptureRequested(
          cameraImage: _FakeCameraImage(),
          faceBox: _kBox,
        ));
        await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentSuccess);

        expect(states.any((s) => s is FaceEnrollmentCapturing), isTrue);
        expect(states.any((s) => s is FaceEnrollmentProcessing), isTrue);
        expect(states.last, isA<FaceEnrollmentSuccess>());

        await sub.cancel();
        await m.bloc.close();
      });

      test('ignores capture when state is not FaceEnrollmentReady', () async {
        final m = _freshMocks();
        // Bloc is in FaceEnrollmentInitial state.
        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        m.bloc.add(FaceEnrollmentCaptureRequested(
          cameraImage: _FakeCameraImage(),
          faceBox: _kBox,
        ));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states, isEmpty);

        await sub.cancel();
        await m.bloc.close();
      });
    });

    // â”€â”€ FaceEnrollmentResetRequested â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    group('FaceEnrollmentResetRequested', () {
      test('emits Ready(capturesDone=0) and clears captures', () async {
        final m = _freshMocks();
        m.bloc.emit(const FaceEnrollmentReady(capturesDone: 3));

        final states = <FaceEnrollmentState>[];
        final sub = m.bloc.stream.listen(states.add);

        m.bloc.add(const FaceEnrollmentResetRequested());
        await m.bloc.stream.firstWhere((s) => s is FaceEnrollmentReady);

        final ready = states.single as FaceEnrollmentReady;
        expect(ready.capturesDone, 0);
        expect(ready.targetPose, FacePose.front);

        await sub.cancel();
        await m.bloc.close();
      });
    });
  });
}

