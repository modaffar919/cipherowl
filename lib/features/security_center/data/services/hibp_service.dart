import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/pointycastle.dart';

/// HaveIBeenPwned k-anonymity breach checker.
///
/// Implements the Range API: only the first 5 hex characters of the SHA-1
/// hash are sent over the network, preserving user privacy.
///
/// Reference: https://haveibeenpwned.com/API/v3#SearchingPwnedPasswordsByRange
class HibpService {
  static const _rangeBase = 'https://api.pwnedpasswords.com/range/';

  final http.Client _client;

  HibpService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns the number of times [password] was found in known breaches.
  ///
  /// Returns `0` if the password was not found or the request fails.
  /// Returns a positive integer indicating the breach count otherwise.
  Future<int> checkPassword(String password) async {
    final hash = _sha1Hex(password);
    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5); // 35 hex chars

    final uri = Uri.parse('$_rangeBase$prefix');
    try {
      final response = await _client.get(uri, headers: {
        'Add-Padding': 'true', // HIBP padding to prevent traffic analysis
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return 0;

      for (final line in response.body.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final colonIdx = trimmed.indexOf(':');
        if (colonIdx < 0) continue;
        final lineSuffix = trimmed.substring(0, colonIdx).toUpperCase();
        if (lineSuffix == suffix) {
          return int.tryParse(trimmed.substring(colonIdx + 1).trim()) ?? 0;
        }
      }
      return 0; // not found — password is clean
    } catch (_) {
      return 0; // network error — fail open (don't block the user)
    }
  }

  /// Batch-check multiple passwords. Returns a map of password → breach count.
  ///
  /// Only unique passwords are queried (deduplication). Callers should avoid
  /// passing plaintext passwords in bulk — decrypt each entry only when needed.
  Future<Map<String, int>> checkPasswords(List<String> passwords) async {
    final results = <String, int>{};
    final unique = passwords.toSet();
    for (final pwd in unique) {
      results[pwd] = await checkPassword(pwd);
    }
    return results;
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Compute SHA-1 of [text] and return the uppercase hex string.
  static String _sha1Hex(String text) {
    final digest = Digest('SHA-1');
    final bytes = digest.process(Uint8List.fromList(utf8.encode(text)));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}
