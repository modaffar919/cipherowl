import 'package:flutter_test/flutter_test.dart';

import 'package:cipherowl/features/auth/data/services/recovery_key_service.dart';

/// Tests for the static / pure helpers in [RecoveryKeyService].
///
/// The core async methods (generateMnemonic, deriveKey, verifyMnemonic) depend
/// on the bip39 package and a Rust FFI call (apiDeriveKeyPbkdf2), so they are
/// exercised in integration tests.
void main() {
  group('RecoveryKeyService.splitWords', () {
    test('splits simple space-delimited mnemonic into 12 words', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final words = RecoveryKeyService.splitWords(mnemonic);
      expect(words.length, 12);
      expect(words.first, 'abandon');
      expect(words.last, 'about');
    });

    test('handles leading and trailing whitespace', () {
      const mnemonic = '  word1  word2  word3  ';
      final words = RecoveryKeyService.splitWords(mnemonic);
      expect(words, ['word1', 'word2', 'word3']);
    });

    test('handles multiple spaces between words', () {
      const mnemonic = 'alpha   beta   gamma';
      final words = RecoveryKeyService.splitWords(mnemonic);
      expect(words, ['alpha', 'beta', 'gamma']);
    });

    test('handles tabs and newlines', () {
      const mnemonic = 'one\ttwo\nthree';
      final words = RecoveryKeyService.splitWords(mnemonic);
      expect(words, ['one', 'two', 'three']);
    });
  });

  group('RecoveryKeyService.validateWords', () {
    test('returns true for valid 12-word BIP39 mnemonic', () {
      const words = [
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'abandon',
        'about',
      ];
      expect(RecoveryKeyService.validateWords(words), isTrue);
    });

    test('returns false for invalid word list', () {
      const words = ['not', 'a', 'valid', 'mnemonic'];
      expect(RecoveryKeyService.validateWords(words), isFalse);
    });

    test('returns false for empty list', () {
      expect(RecoveryKeyService.validateWords([]), isFalse);
    });
  });
}
