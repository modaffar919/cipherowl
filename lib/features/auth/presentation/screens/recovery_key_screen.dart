import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/auth/data/services/recovery_key_service.dart';

/// Screen that:
///   1. Generates and displays a 12-word BIP39 recovery mnemonic.
///   2. Lets the user copy it to clipboard.
///   3. Proceeds to a verification step (enter back 3 random words).
///   4. On success, persists the verifier via [RecoveryKeyService].
///
/// Usage: push as a modal route during setup or from settings.
class RecoveryKeyScreen extends StatefulWidget {
  const RecoveryKeyScreen({super.key});

  @override
  State<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends State<RecoveryKeyScreen> {
  final _service = RecoveryKeyService();

  late final String _mnemonic;
  late final List<String> _words;

  // Verification step
  bool _showVerification = false;
  bool _verifying = false;
  String? _verifyError;

  // Indices to verify (1-based for display)
  late final List<int> _verifyIndices;
  final _controllers = <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _mnemonic = _service.generateMnemonic();
    _words = RecoveryKeyService.splitWords(_mnemonic);

    // Pick 3 random word positions to verify
    final shuffled = List.generate(_words.length, (i) => i)..shuffle();
    _verifyIndices = shuffled.take(3).toList()..sort();
    for (final idx in _verifyIndices) {
      _controllers[idx] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _mnemonic));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ عبارة الاسترداد — احتفظ بها في مكان آمن'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _verifyError = null;
    });

    // Check the user's entries match their correct positions
    for (final idx in _verifyIndices) {
      final entered = _controllers[idx]!.text.trim().toLowerCase();
      if (entered != _words[idx].toLowerCase()) {
        setState(() {
          _verifyError = 'الكلمة ${idx + 1} غير صحيحة — تأكد من الترتيب';
          _verifying = false;
        });
        return;
      }
    }

    // Derive key and save verifier
    try {
      final key = await _service.deriveKey(_mnemonic);
      await _service.saveVerifier(key);
      if (!mounted) return;
      Navigator.of(context).pop(true); // success
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifyError = 'حدث خطأ: ${e.toString()}';
          _verifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: Text(
          _showVerification ? 'تأكيد عبارة الاسترداد' : 'مفتاح الاسترداد (12 كلمة)',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _showVerification
              ? () => setState(() => _showVerification = false)
              : () => Navigator.of(context).pop(false),
        ),
      ),
      body: _showVerification ? _buildVerification() : _buildWordGrid(),
    );
  }

  // ── Step 1: Display 12 words ───────────────────────────────────────────────

  Widget _buildWordGrid() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Warning banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppConstants.warningAmber.withValues(alpha: 0.12),
            border: Border.all(color: AppConstants.warningAmber.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber, color: AppConstants.warningAmber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'اكتب هذه الكلمات وأحتفظ بها في مكان آمن. '
                  'لن تُعرض مرةً أخرى. تُستخدم لاسترداد الحساب عند فقدان كلمة المرور.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 12-word grid (2 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
          ),
          itemCount: _words.length,
          itemBuilder: (_, i) => _WordTile(index: i + 1, word: _words[i]),
        ),
        const SizedBox(height: 20),

        // Copy button
        OutlinedButton.icon(
          onPressed: _copyAll,
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('نسخ الكل'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryCyan,
            side: const BorderSide(color: AppConstants.primaryCyan),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Continue button
        ElevatedButton(
          onPressed: () => setState(() => _showVerification = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('لقد دوّنت الكلمات — استمر'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 2: Verify 3 random words ─────────────────────────────────────────

  Widget _buildVerification() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'أدخل الكلمات التالية من عبارتك للتأكيد:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        for (final idx in _verifyIndices) ...[
          _VerifyField(
            wordNumber: idx + 1,
            controller: _controllers[idx]!,
          ),
          const SizedBox(height: 12),
        ],
        if (_verifyError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _verifyError!,
              style: const TextStyle(color: AppConstants.errorRed, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ElevatedButton(
          onPressed: _verifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _verifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('تأكيد وحفظ'),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _WordTile extends StatelessWidget {
  final int index;
  final String word;

  const _WordTile({required this.index, required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.borderDark),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index.',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          Text(
            word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'SpaceMono',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyField extends StatelessWidget {
  final int wordNumber;
  final TextEditingController controller;

  const _VerifyField({required this.wordNumber, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontFamily: 'SpaceMono'),
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'الكلمة رقم $wordNumber',
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppConstants.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.primaryCyan),
        ),
      ),
    );
  }
}
