import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

/// Result of a successful TOTP QR scan.
class TotpImportResult {
  /// Human-readable label (e.g. "alice@example.com" or "GitHub:alice").
  final String label;

  /// Base32-encoded TOTP secret.
  final String secret;

  /// Issuer from the URI (e.g. "GitHub"), may be empty.
  final String issuer;

  /// Hash algorithm — "SHA1" (default), "SHA256", or "SHA512".
  final String algorithm;

  /// Code length — 6 (default) or 8.
  final int digits;

  /// Time period in seconds — 30 (default).
  final int period;

  const TotpImportResult({
    required this.label,
    required this.secret,
    required this.issuer,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
  });
}

/// Full-screen QR code scanner that accepts `otpauth://totp/...` URIs.
///
/// Push this screen and `await` the result:
/// ```dart
/// final result = await Navigator.push<TotpImportResult?>(
///   context,
///   MaterialPageRoute(builder: (_) => const TotpQrScannerScreen()),
/// );
/// if (result != null) { /* use result.secret */ }
/// ```
class TotpQrScannerScreen extends StatefulWidget {
  const TotpQrScannerScreen({super.key});

  @override
  State<TotpQrScannerScreen> createState() => _TotpQrScannerScreenState();
}

class _TotpQrScannerScreenState extends State<TotpQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final result = _parseOtpAuth(rawValue);
    if (result == null) {
      setState(() => _errorMessage = 'رمز QR غير متوافق — يجب أن يكون otpauth://totp/...');
      return;
    }

    _processed = true;
    _controller.stop();
    Navigator.of(context).pop(result);
  }

  /// Parse an `otpauth://totp/<label>?secret=XXX[&issuer=YYY...]` URI.
  static TotpImportResult? _parseOtpAuth(String raw) {
    Uri uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return null;
    }

    // Validate scheme and host
    if (uri.scheme != 'otpauth') return null;
    if (uri.host != 'totp') return null; // only TOTP (not HOTP)

    // Extract secret (required)
    final secret = uri.queryParameters['secret'];
    if (secret == null || secret.isEmpty) return null;

    // Label: strip leading slash, decode percent-encoding
    var label = uri.path.replaceAll(RegExp(r'^/+'), '');
    if (label.isEmpty) label = 'حساب غير معروف';

    // Optional parameters with RFC 6238 defaults
    final issuer = uri.queryParameters['issuer'] ?? '';
    final algorithm = uri.queryParameters['algorithm']?.toUpperCase() ?? 'SHA1';
    final digits = int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6;
    final period = int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30;

    return TotpImportResult(
      label: label,
      secret: secret.toUpperCase().replaceAll(RegExp(r'[\s\-]'), ''),
      issuer: issuer,
      algorithm: algorithm,
      digits: digits.clamp(6, 8),
      period: period.clamp(15, 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'مسح رمز TOTP',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white54),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'تبديل الفلاش',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera viewfinder
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan-area overlay
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppConstants.primaryCyan, width: 2.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instruction / error banner
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _errorMessage != null
                  ? _StatusBadge(
                      key: const ValueKey('error'),
                      message: _errorMessage!,
                      color: AppConstants.errorRed,
                      icon: Icons.error_outline,
                    )
                  : _StatusBadge(
                      key: const ValueKey('hint'),
                      message: 'وجّه الكاميرا نحو رمز QR للتطبيق',
                      color: AppConstants.primaryCyan,
                      icon: Icons.qr_code_scanner,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
