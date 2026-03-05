import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// Captures a front-camera still when an intruder is detected (3 failed login
/// attempts) and stores it to the app's private documents directory.
///
/// The path is returned so callers (e.g. SecurityCenterScreen) can display or
/// upload the snapshot later.
///
/// This service is intentionally lightweight — no UI, no BLoC dependency.
/// Security note: images are stored in the app sandbox (not accessible to
/// other apps). No network upload occurs without explicit user consent.
class IntruderSnapshotService {
  /// Capture a snapshot asynchronously. Errors are swallowed so the
  /// authentication flow is never interrupted by a camera failure.
  void captureAsync() {
    _capture().ignore();
  }

  /// Capture and save a snapshot. Returns the saved file path, or null on
  /// failure (no camera / permission denied / error).
  Future<String?> capture() => _capture();

  // ── Implementation ─────────────────────────────────────────────────────────

  Future<String?> _capture() async {
    CameraController? controller;
    try {
      // Find the front camera
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      // Take the picture
      final xFile = await controller.takePicture();

      // Save to app documents directory with timestamp
      final docsDir = await getApplicationDocumentsDirectory();
      final snapshotDir = Directory('${docsDir.path}/intruder_snapshots');
      if (!snapshotDir.existsSync()) {
        snapshotDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${snapshotDir.path}/snapshot_$timestamp.jpg';
      await File(xFile.path).copy(destPath);

      return destPath;
    } catch (_) {
      // Camera unavailable, permission denied, or any other error — silently fail
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  /// List all saved intruder snapshot paths, sorted newest-first.
  static Future<List<String>> listSnapshots() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final snapshotDir = Directory('${docsDir.path}/intruder_snapshots');
      if (!snapshotDir.existsSync()) return [];
      final files = snapshotDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      return files.map((f) => f.path).toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete all saved snapshots.
  static Future<void> clearSnapshots() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final snapshotDir = Directory('${docsDir.path}/intruder_snapshots');
      if (snapshotDir.existsSync()) snapshotDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
