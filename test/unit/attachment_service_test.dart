import 'package:flutter_test/flutter_test.dart';

import 'package:cipherowl/features/vault/data/services/attachment_service.dart';

/// Tests for the pure / static helpers and exceptions in [AttachmentService].
///
/// Full-stack tests (encrypt → write → read → decrypt) require the Rust FFI
/// and platform storage, so they live in integration tests.
void main() {
  group('AttachmentService.formatFileSize', () {
    test('formats bytes', () {
      expect(AttachmentService.formatFileSize(512), '512 B');
    });

    test('formats kilobytes', () {
      expect(AttachmentService.formatFileSize(2048), '2.0 KB');
    });

    test('formats megabytes', () {
      expect(AttachmentService.formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });

    test('handles zero bytes', () {
      expect(AttachmentService.formatFileSize(0), '0 B');
    });

    test('rounds fractional KB', () {
      // 1536 bytes = 1.5 KB
      expect(AttachmentService.formatFileSize(1536), '1.5 KB');
    });
  });

  group('kMaxAttachmentBytes', () {
    test('is 10 MB', () {
      expect(kMaxAttachmentBytes, 10 * 1024 * 1024);
    });
  });

  group('AttachmentTooLargeException', () {
    test('toString includes actual and max sizes', () {
      final ex = AttachmentTooLargeException(15 * 1024 * 1024);
      final msg = ex.toString();
      expect(msg, contains('15.0 MB'));
      expect(msg, contains('10.0 MB'));
    });
  });

  group('AttachmentNotFoundException', () {
    test('toString includes attachment id', () {
      final ex = AttachmentNotFoundException('att-123');
      expect(ex.toString(), contains('att-123'));
    });
  });
}
