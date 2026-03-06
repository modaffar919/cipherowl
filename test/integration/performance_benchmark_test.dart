@Tags(['integration'])
library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipherowl/core/crypto/vault_crypto_service.dart';

/// Performance regression benchmarks for client-side crypto operations.
///
/// These tests require the Rust FFI native library and must be run with
/// the integration test runner or on a device/emulator.
///
/// Usage:
///   flutter test --tags integration test/integration/performance_benchmark_test.dart
///
/// Thresholds (fail if exceeded):
///   - AES-256-GCM encrypt/decrypt 1KB : < 50 ms
///   - AES-256-GCM encrypt 1MB         : < 500 ms
///   - VaultCryptoService round-trip    : < 100 ms
void main() {
  group('Performance Benchmarks', () {
    late VaultCryptoService crypto;

    setUpAll(() async {
      crypto = VaultCryptoService();
    });

    test('AES-256-GCM encrypt 1KB completes under 50ms', () async {
      final payload = Uint8List(1024); // 1 KB of zeros
      final sw = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        await crypto.encryptBytes(payload);
      }
      sw.stop();
      final avgMs = sw.elapsedMilliseconds / 100;
      // ignore: avoid_print
      print('AES-256-GCM encrypt 1KB avg: ${avgMs.toStringAsFixed(2)} ms');
      expect(avgMs, lessThan(50), reason: 'Encrypt 1KB must be < 50ms');
    });

    test('AES-256-GCM decrypt 1KB completes under 50ms', () async {
      final payload = Uint8List(1024);
      final encrypted = await crypto.encryptBytes(payload);

      final sw = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        await crypto.decryptBytes(encrypted);
      }
      sw.stop();
      final avgMs = sw.elapsedMilliseconds / 100;
      // ignore: avoid_print
      print('AES-256-GCM decrypt 1KB avg: ${avgMs.toStringAsFixed(2)} ms');
      expect(avgMs, lessThan(50), reason: 'Decrypt 1KB must be < 50ms');
    });

    test('AES-256-GCM encrypt 1MB completes under 500ms', () async {
      final payload = Uint8List(1024 * 1024); // 1 MB
      final sw = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        await crypto.encryptBytes(payload);
      }
      sw.stop();
      final avgMs = sw.elapsedMilliseconds / 10;
      // ignore: avoid_print
      print('AES-256-GCM encrypt 1MB avg: ${avgMs.toStringAsFixed(2)} ms');
      expect(avgMs, lessThan(500), reason: 'Encrypt 1MB must be < 500ms');
    });

    test('VaultCryptoService round-trip completes under 100ms', () async {
      const input = 'CipherOwl benchmark test string — بيانات اختبارية';
      final sw = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        final encrypted = await crypto.encrypt(input);
        await crypto.decrypt(encrypted);
      }
      sw.stop();
      final avgMs = sw.elapsedMilliseconds / 100;
      // ignore: avoid_print
      print('VaultCrypto round-trip avg: ${avgMs.toStringAsFixed(2)} ms');
      expect(avgMs, lessThan(100),
          reason: 'Encrypt+decrypt round-trip must be < 100ms');
    });
  });
}
