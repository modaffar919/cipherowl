import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/sharing/data/services/sharing_service.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

/// Secure Sharing Screen — share vault items via AES-256-GCM encrypted link.
class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});
  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  int _expiryHours = 24;
  bool _oneTimeUse = true;
  bool _requirePin = false;
  String? _generatedLink;
  bool _isLoading = false;
  VaultEntry? _selectedItem;

  final _sharingService = SharingService();
  List<SharedItemInfo> _activeShares = [];

  static const _expiryOptions = [1, 6, 24, 48, 168];
  static const _expiryLabels = <int, String>{
    1: '\u0633\u0627\u0639\u0629',
    6: '6 \u0633\u0627\u0639\u0627\u062a',
    24: '\u064a\u0648\u0645',
    48: '\u064a\u0648\u0645\u0627\u0646',
    168: '\u0623\u0633\u0628\u0648\u0639',
  };

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  Future<void> _loadShares() async {
    try {
      final shares = await _sharingService.listMyShares();
      if (mounted) setState(() => _activeShares = shares);
    } catch (_) {
      // Offline or not authenticated
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text(
          '\u0627\u0644\u0645\u0634\u0627\u0631\u0643\u0629 \u0627\u0644\u0622\u0645\u0646\u0629',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
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
                    '\u0645\u0634\u0641\u0631 \u0628\u0640 AES-256-GCM \u2014 \u0644\u0627 \u064a\u0645\u0643\u0646 \u0644\u0623\u062d\u062f \u0631\u0624\u064a\u0629 \u0645\u062d\u062a\u0648\u0649 \u0627\u0644\u0631\u0627\u0628\u0637 \u062d\u062a\u0649 \u0646\u062d\u0646',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            '\u0625\u0646\u0634\u0627\u0621 \u0631\u0627\u0628\u0637 \u0645\u0634\u0627\u0631\u0643\u0629',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          // Vault item selector
          BlocBuilder<VaultBloc, VaultState>(
            builder: (context, state) {
              final items = state is VaultLoaded
                  ? state.filteredItems
                  : <VaultEntry>[];
              return GestureDetector(
                onTap: () => _showItemPicker(context, items),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.borderDark),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedItem != null ? Icons.lock : Icons.add_circle_outline,
                        color: _selectedItem != null ? AppConstants.primaryCyan : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedItem?.title ?? '\u0627\u062e\u062a\u0631 \u0639\u0646\u0635\u0631\u0627\u064b \u0645\u0646 \u0627\u0644\u062e\u0632\u0646\u0629',
                          style: TextStyle(
                            color: _selectedItem != null ? Colors.white : Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white38),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u0644\u0644\u0645\u0633\u062a\u0644\u0645',
              hintText: 'friend@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 18, color: Colors.white38),
            ),
          ),

          const SizedBox(height: 16),

          // Expiry
          Text(
            '\u0645\u062f\u0629 \u0627\u0644\u0635\u0644\u0627\u062d\u064a\u0629',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
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
                    child: Text(
                      _expiryLabels[h]!,
                      style: TextStyle(color: sel ? AppConstants.primaryCyan : Colors.white60, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          _OptionSwitch(
            label: '\u0627\u0633\u062a\u062e\u062f\u0627\u0645 \u0644\u0645\u0631\u0629 \u0648\u0627\u062d\u062f\u0629',
            value: _oneTimeUse,
            color: AppConstants.primaryCyan,
            onChanged: (v) => setState(() => _oneTimeUse = v),
          ),
          _OptionSwitch(
            label: '\u062a\u0637\u0644\u0628 \u0631\u0645\u0632 PIN',
            value: _requirePin,
            color: AppConstants.accentGold,
            onChanged: (v) => setState(() => _requirePin = v),
          ),

          if (_requirePin) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _pinCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '\u0631\u0645\u0632 PIN (4-6 \u0623\u0631\u0642\u0627\u0645)',
                prefixIcon: Icon(Icons.pin, size: 18, color: Colors.white38),
                counterText: '',
              ),
            ),
          ],

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.link, size: 18),
            label: Text(_isLoading
                ? '\u062c\u0627\u0631\u064d \u0627\u0644\u0625\u0646\u0634\u0627\u0621...'
                : '\u0625\u0646\u0634\u0627\u0621 \u0631\u0627\u0628\u0637 \u0622\u0645\u0646'),
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
                  const Row(children: [
                    Icon(Icons.check_circle, color: AppConstants.successGreen, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '\u062a\u0645 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0631\u0627\u0628\u0637',
                      style: TextStyle(color: AppConstants.successGreen, fontWeight: FontWeight.w600),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    _generatedLink!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'SpaceMono'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedLink!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('\u062a\u0645 \u0646\u0633\u062e \u0627\u0644\u0631\u0627\u0628\u0637')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('\u0646\u0633\u062e \u0627\u0644\u0631\u0627\u0628\u0637'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          const Text(
            '\u0627\u0644\u0631\u0648\u0627\u0628\u0637 \u0627\u0644\u0646\u0634\u0637\u0629',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          if (_activeShares.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '\u0644\u0627 \u062a\u0648\u062c\u062f \u0631\u0648\u0627\u0628\u0637 \u0645\u0634\u0627\u0631\u0643\u0629 \u062d\u0627\u0644\u064a\u0627\u064b',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            ..._activeShares.map((s) => _ActiveShareCard(
              share: s,
              onRevoke: () async {
                await _sharingService.revokeShare(s.id);
                _loadShares();
              },
            )),
        ],
      ),
    );
  }

  void _showItemPicker(BuildContext context, List<VaultEntry> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return ListTile(
            leading: const Icon(Icons.lock_outline, color: AppConstants.primaryCyan, size: 20),
            title: Text(item.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              item.username ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () {
              setState(() => _selectedItem = item);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Future<void> _generate() async {
    if (_emailCtrl.text.isEmpty || _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u0627\u062e\u062a\u0631 \u0639\u0646\u0635\u0631\u0627\u064b \u0648\u0623\u062f\u062e\u0644 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a'),
        ),
      );
      return;
    }

    if (_requirePin && _pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u0623\u062f\u062e\u0644 \u0631\u0645\u0632 PIN \u0645\u0646 4-6 \u0623\u0631\u0642\u0627\u0645'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = _selectedItem!;
      final shareData = jsonEncode({
        'title': item.title,
        'username': item.username,
        'url': item.url,
        'category': item.category.name,
      });

      final result = await _sharingService.createShare(
        itemJson: shareData,
        recipientEmail: _emailCtrl.text.trim(),
        expiryHours: _expiryHours,
        isOneTime: _oneTimeUse,
        requirePin: _requirePin,
        pin: _requirePin ? _pinCtrl.text : null,
      );

      setState(() => _generatedLink = result.url);
      _loadShares();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u0641\u0634\u0644 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0631\u0627\u0628\u0637: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }
}

class _ActiveShareCard extends StatelessWidget {
  final SharedItemInfo share;
  final VoidCallback onRevoke;
  const _ActiveShareCard({required this.share, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final active = share.isActive;
    final statusLabel = switch (share.status) {
      'active' => '\u0646\u0634\u0637',
      'expired' => '\u0645\u0646\u062a\u0647\u064a',
      'used' => '\u0645\u0633\u062a\u062e\u062f\u0645',
      'revoked' => '\u0645\u0644\u063a\u0649',
      _ => share.status,
    };
    final statusColor = active ? AppConstants.successGreen : AppConstants.errorRed;
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
              Text(
                share.recipientEmail ?? '\u0628\u062f\u0648\u0646 \u0628\u0631\u064a\u062f',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                '\u064a\u0646\u062a\u0647\u064a: ${share.expiresAt.toLocal().toString().substring(0, 16)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ]),
          ),
          if (active)
            IconButton(
              icon: const Icon(Icons.block, color: Colors.white38, size: 18),
              tooltip: '\u0625\u0644\u063a\u0627\u0621 \u0627\u0644\u0631\u0627\u0628\u0637',
              onPressed: onRevoke,
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _OptionSwitch({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
      Switch(value: value, onChanged: onChanged, activeThumbColor: color),
    ],
  );
}

