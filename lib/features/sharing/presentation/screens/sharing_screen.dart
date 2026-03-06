import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

/// Secure Sharing Screen â€” share vault items via X25519 encrypted link
class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});
  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final _emailCtrl = TextEditingController();
  int _expiryHours = 24;
  bool _oneTimeUse = true;
  bool _requirePin = false;
  String? _generatedLink;

  static const _expiryOptions = [1, 6, 24, 48, 168]; // hours
  static const _expiryLabels = {1: 'ط³ط§ط¹ط©', 6: '6 ط³ط§ط¹ط§طھ', 24: 'ظٹظˆظ…', 48: 'ظٹظˆظ…ط§ظ†', 168: 'ط£ط³ط¨ظˆط¹'};

  // Shared items (TODO: load from vault)
  static final _sharedItems = [
    _SharedItem(title: 'Netflix Family', recipient: 'family@email.com', expiry: '2025-02-01', status: 'active'),
    _SharedItem(title: 'WiFi Home', recipient: 'guest@email.com', expiry: '2025-01-15', status: 'expired'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text('ط§ظ„ظ…ط´ط§ط±ظƒط© ط§ظ„ط¢ظ…ظ†ط©', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.primaryCyan.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.primaryCyan.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: AppConstants.primaryCyan, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ظ…ط´ظپط± ط¨ظ€ X25519 â€” ظ„ط§ ظٹظ…ظƒظ† ظ„ط£ط­ط¯ ط±ط¤ظٹط© ظ…ط­طھظˆظ‰ ط§ظ„ط±ط§ط¨ط· ط­طھظ‰ ظ†ط­ظ†',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('ط¥ظ†ط´ط§ط، ط±ط§ط¨ط· ظ…ط´ط§ط±ظƒط©', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          TextField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'ط§ظ„ط¨ط±ظٹط¯ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ ظ„ظ„ظ…ط³طھظ„ظ…',
              hintText: 'friend@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 18, color: Colors.white38),
            ),
          ),

          const SizedBox(height: 16),

          // Expiry
          const Text('ظ…ط¯ط© ط§ظ„طµظ„ط§ط­ظٹط©', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _expiryOptions.map((h) {
                final sel = _expiryHours == h;
                return GestureDetector(
                  onTap: () => setState(() => _expiryHours = h),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppConstants.primaryCyan.withValues(alpha: 0.15) : AppConstants.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppConstants.primaryCyan.withValues(alpha: 0.5) : AppConstants.borderDark),
                    ),
                    child: Text(_expiryLabels[h]!,
                        style: TextStyle(color: sel ? AppConstants.primaryCyan : Colors.white60, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Options
          _OptionSwitch(label: 'ط§ط³طھط®ط¯ط§ظ… ظ„ظ…ط±ط© ظˆط§ط­ط¯ط©', value: _oneTimeUse, color: AppConstants.primaryCyan, onChanged: (v) => setState(() => _oneTimeUse = v)),
          _OptionSwitch(label: 'طھط·ظ„ط¨ ط±ظ…ط² PIN', value: _requirePin, color: AppConstants.accentGold, onChanged: (v) => setState(() => _requirePin = v)),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.link, size: 18),
            label: const Text('ط¥ظ†ط´ط§ط، ط±ط§ط¨ط· ط¢ظ…ظ†'),
          ),

          if (_generatedLink != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.successGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.successGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.check_circle, color: AppConstants.successGreen, size: 16),
                    const SizedBox(width: 6),
                    const Text('طھظ… ط¥ظ†ط´ط§ط، ط§ظ„ط±ط§ط¨ط·', style: TextStyle(color: AppConstants.successGreen, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  Text(_generatedLink!, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'SpaceMono')),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {}, // copy
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('ظ†ط³ط® ط§ظ„ط±ط§ط¨ط·'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          const Text('ط§ظ„ط±ظˆط§ط¨ط· ط§ظ„ظ†ط´ط·ط©', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          ..._sharedItems.map((i) => _SharedItemCard(item: i)),
        ],
      ),
    );
  }

  void _generate() {
    if (_emailCtrl.text.isEmpty) return;
    // TODO: Generate X25519 encrypted share link via Supabase Edge Function
    setState(() => _generatedLink = 'https://cipherowl.app/share/v1/a8f2c3d4e5f6...#key=AbCdEfGh');
  }
}

class _SharedItem {
  final String title, recipient, expiry, status;
  const _SharedItem({required this.title, required this.recipient, required this.expiry, required this.status});
}

class _SharedItemCard extends StatelessWidget {
  final _SharedItem item;
  const _SharedItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final active = item.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: active ? AppConstants.primaryCyan : Colors.white24, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(item.recipient, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: active ? AppConstants.successGreen.withValues(alpha: 0.1) : AppConstants.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(active ? 'ظ†ط´ط·' : 'ظ…ظ†طھظ‡ظٹ',
                style: TextStyle(color: active ? AppConstants.successGreen : AppConstants.errorRed, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  final String label; final bool value; final Color color; final ValueChanged<bool> onChanged;
  const _OptionSwitch({required this.label, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
      Switch(value: value, onChanged: onChanged, activeThumbColor: color),
    ],
  );
}

