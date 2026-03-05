import 'dart:ui' show Rect;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Extracts 128-dimensional face embeddings via TFLite MobileFaceNet.
///
/// The model is loaded from `assets/models/mobile_facenet.tflite`.
/// Input tensor:  [1, 112, 112, 3] float32, pixel values in [-1.0, 1.0].
/// Output tensor: [1, 128] float32 L2-normalised embedding.
///
/// NOTE: The `assets/models/mobile_facenet.tflite` model file must be placed
/// in the assets folder. Download MobileFaceNet from the official repository:
/// https://github.com/sirius-ai/MobileFaceNet_TF
class FaceEmbeddingService {
  static const String _modelAsset = 'assets/models/mobile_facenet.tflite';
  static const int inputSize = 112;
  static const int embeddingDim = 128;

  Interpreter? _interpreter;

  bool get isInitialized => _interpreter != null;

  /// Loads the TFLite model from assets. Must be called before [getEmbedding].
  Future<void> initialize() async {
    if (_interpreter != null) return;
    _interpreter = await Interpreter.fromAsset(_modelAsset);
  }

  /// Extracts a 128-dim embedding from a [CameraImage] given a face [boundingBox].
  ///
  /// Runs on an isolate to avoid blocking the UI thread.
  /// Returns null if the crop area is out of bounds or image conversion fails.
  Future<List<double>?> getEmbeddingFromCamera({
    required CameraImage cameraImage,
    required Rect boundingBox,
  }) async {
    if (_interpreter == null) await initialize();
    final faceBytes = await compute(
      _prepareInputIsolate,
      _PrepareInputArgs(
        planes: cameraImage.planes
            .map((p) => _PlaneData(p.bytes, p.bytesPerRow, p.bytesPerPixel))
            .toList(),
        width: cameraImage.width,
        height: cameraImage.height,
        boundingBox: boundingBox,
        planeCount: cameraImage.planes.length,
      ),
    );
    if (faceBytes == null) return null;
    return _runInference(faceBytes);
  }

  /// Runs TFLite inference on pre-prepared [inputTensor] bytes.
  List<double> _runInference(List<List<List<List<double>>>> inputTensor) {
    final output = List.generate(1, (_) => List.filled(embeddingDim, 0.0));
    _interpreter!.run(inputTensor, output);
    return List<double>.from(output[0] as List);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

// ---------------------------------------------------------------------------
// Isolate helpers — must be top-level functions for compute()
// ---------------------------------------------------------------------------

class _PlaneData {
  final Uint8List bytes;
  final int bytesPerRow;
  final int? bytesPerPixel;
  const _PlaneData(this.bytes, this.bytesPerRow, this.bytesPerPixel);
}

class _PrepareInputArgs {
  final List<_PlaneData> planes;
  final int width;
  final int height;
  final Rect boundingBox;
  final int planeCount;
  const _PrepareInputArgs({
    required this.planes,
    required this.width,
    required this.height,
    required this.boundingBox,
    required this.planeCount,
  });
}

List<List<List<List<double>>>>? _prepareInputIsolate(_PrepareInputArgs args) {
  img.Image? fullImage;

  if (args.planeCount == 1) {
    // BGRA8888 (iOS)
    fullImage = img.Image.fromBytes(
      width: args.width,
      height: args.height,
      bytes: args.planes.first.bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  } else {
    // YUV420_888 (Android)
    fullImage = _yuv420ToRgb(args);
  }

  // fullImage is always non-null at this point (both branches assign one).
  final bx = args.boundingBox;
  final x = bx.left.toInt().clamp(0, fullImage.width - 1);
  final y = bx.top.toInt().clamp(0, fullImage.height - 1);
  final w = bx.width.toInt().clamp(1, fullImage.width - x);
  final h = bx.height.toInt().clamp(1, fullImage.height - y);

  final cropped = img.copyCrop(fullImage, x: x, y: y, width: w, height: h);
  final resized = img.copyResize(
    cropped,
    width: FaceEmbeddingService.inputSize,
    height: FaceEmbeddingService.inputSize,
  );

  // Build [1][112][112][3] normalised float tensor.
  return [
    List.generate(FaceEmbeddingService.inputSize, (py) {
      return List.generate(FaceEmbeddingService.inputSize, (px) {
        final pixel = resized.getPixel(px, py);
        return [
          (pixel.r / 127.5) - 1.0,
          (pixel.g / 127.5) - 1.0,
          (pixel.b / 127.5) - 1.0,
        ];
      });
    }),
  ];
}

img.Image _yuv420ToRgb(_PrepareInputArgs args) {
  final w = args.width;
  final h = args.height;
  final yPlane = args.planes[0];
  final uPlane = args.planes[1];
  final vPlane = args.planes[2];
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final result = img.Image(width: w, height: h);
  for (int py = 0; py < h; py++) {
    for (int px = 0; px < w; px++) {
      final yVal = yPlane.bytes[py * yPlane.bytesPerRow + px];
      final uvIndex = (py ~/ 2) * uPlane.bytesPerRow + (px ~/ 2) * uvPixelStride;
      final u = uPlane.bytes[uvIndex] - 128;
      final v = vPlane.bytes[uvIndex] - 128;
      final r = (yVal + 1.370705 * v).round().clamp(0, 255);
      final g = (yVal - 0.337633 * u - 0.698001 * v).round().clamp(0, 255);
      final b = (yVal + 1.732446 * u).round().clamp(0, 255);
      result.setPixelRgba(px, py, r, g, b, 255);
    }
  }
  return result;
}
