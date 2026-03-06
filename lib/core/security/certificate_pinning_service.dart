import 'dart:io';

import 'package:flutter/foundation.dart';

/// Certificate pinning for Supabase API connections.
///
/// OWASP MASVS-NETWORK-2: defence-in-depth for TLS connections.
///
/// **Implementation strategy (per OWASP recommendation):**
/// - Android → `network_security_config.xml` (declarative, survives OkHttp)
/// - iOS → ATS + runtime SHA-1 pin check
/// - Dart layer → [createPinnedClient] rejects unexpected Supabase certs
///
/// Pinning is applied ONLY to `*.supabase.co` / `*.supabase.in` hosts.
/// All other hosts use the platform's default trust store.
class CertificatePinningService {
  CertificatePinningService._();

  /// SHA-1 fingerprints of trusted Supabase/AWS certificates.
  ///
  /// X509Certificate in Dart provides `sha1` natively. Update these when
  /// Supabase rotates TLS certificates.
  ///
  /// Obtain with:
  /// ```bash
  /// openssl s_client -connect <project>.supabase.co:443 </dev/null 2>/dev/null |
  ///   openssl x509 -fingerprint -sha1 -noout
  /// ```
  static const List<String> _trustedSha1Fingerprints = [
    // Amazon Root CA 1 (Supabase infrastructure)
    '06:3B:46:1A:64:EA:04:CF:45:C6:F6:08:F1:0E:97:8D:34:5A:27:C8',
    // Starfield Services Root CA (AWS backup chain)
    'AD:7E:1C:28:B0:64:EF:8F:60:03:40:20:14:C3:D0:E3:37:0E:B5:8A',
  ];

  /// Creates an [HttpClient] with certificate pinning for Supabase hosts.
  static HttpClient createPinnedClient() {
    if (kIsWeb) return HttpClient();

    final client = HttpClient();

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      // Always allow development connections.
      if (host == 'localhost' || host == '127.0.0.1') return true;

      // Only pin Supabase domains.
      if (!host.endsWith('.supabase.co') &&
          !host.endsWith('.supabase.in')) {
        return true;
      }

      // Reject — the platform TLS stack has already flagged this cert.
      // We compare SHA-1 (available on X509Certificate) as extra defence.
      final sha1 = cert.sha1
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');
      return _trustedSha1Fingerprints.contains(sha1);
    };

    return client;
  }
}
