import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/sync/domain/three_way_merge.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';

/// Displays sync conflicts and lets the user choose local or remote
/// values for each conflicting field.
///
/// Usage (from VaultBloc or sync handler):
/// ```dart
/// final resolved = await Navigator.push<List<VaultEntry>>(
///   context,
///   MaterialPageRoute(builder: (_) => SyncConflictScreen(conflicts: conflicts)),
/// );
/// ```
class SyncConflictScreen extends StatefulWidget {
  final List<MergeConflict> conflicts;
  const SyncConflictScreen({super.key, required this.conflicts});

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

class _SyncConflictScreenState extends State<SyncConflictScreen> {
  // For each conflict index → field name → 'local' or 'remote'
  late final List<Map<String, String>> _choices;

  @override
  void initState() {
    super.initState();
    _choices = widget.conflicts
        .map((c) => {for (final f in c.conflictingFields) f: 'local'})
        .toList();
  }

  List<VaultEntry> _resolve() {
    final resolved = <VaultEntry>[];
    for (var i = 0; i < widget.conflicts.length; i++) {
      final conflict = widget.conflicts[i];
      final picks = _choices[i];
      var entry = conflict.base;

      for (final field in conflict.conflictingFields) {
        final useLocal = picks[field] == 'local';
        final source = useLocal ? conflict.local : conflict.remote;
        entry = _applyField(entry, source, field);
      }

      // Apply non-conflicting changes from both sides
      for (final field in _allMergeableFields) {
        if (!conflict.conflictingFields.contains(field)) {
          // Use whichever side changed (merge engine already resolved these)
          // For simplicity, take whichever differs from base
          final localDiffers = _fieldValue(conflict.local, field) != _fieldValue(conflict.base, field);
          if (localDiffers) {
            entry = _applyField(entry, conflict.local, field);
          } else {
            entry = _applyField(entry, conflict.remote, field);
          }
        }
      }

      final now = DateTime.now();
      resolved.add(entry.copyWith(updatedAt: now, syncedAt: now));
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '\u062A\u0639\u0627\u0631\u0636\u0627\u062A \u0627\u0644\u0645\u0632\u0627\u0645\u0646\u0629 (${widget.conflicts.length})', // تعارضات المزامنة
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _resolve()),
            child: const Text(
              '\u062D\u0641\u0638', // حفظ
              style: TextStyle(color: AppConstants.primaryCyan, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.conflicts.length,
        itemBuilder: (context, i) => _buildConflictCard(i),
      ),
    );
  }

  Widget _buildConflictCard(int index) {
    final conflict = widget.conflicts[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.warningAmber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppConstants.warningAmber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.local.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Conflicting fields
          ...conflict.conflictingFields.map((field) =>
              _buildFieldChoice(index, field, conflict)),
        ],
      ),
    );
  }

  Widget _buildFieldChoice(int index, String field, MergeConflict conflict) {
    final choice = _choices[index][field]!;
    final localVal = _fieldDisplayValue(conflict.local, field);
    final remoteVal = _fieldDisplayValue(conflict.remote, field);
    final label = _fieldLabel(field);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: '\u0627\u0644\u0645\u062D\u0644\u064A', // المحلي
                  value: localVal,
                  selected: choice == 'local',
                  color: AppConstants.primaryCyan,
                  onTap: () => setState(() => _choices[index][field] = 'local'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceCard(
                  label: '\u0627\u0644\u0633\u062D\u0627\u0628\u0629', // السحابة
                  value: remoteVal,
                  selected: choice == 'remote',
                  color: AppConstants.accentGold,
                  onTap: () =>
                      setState(() => _choices[index][field] = 'remote'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────────────────

  static const _allMergeableFields = [
    'title', 'username', 'url', 'category', 'isFavorite',
    'strengthScore', 'encryptedPassword', 'encryptedNotes',
    'encryptedTotpSecret',
  ];

  static String _fieldLabel(String field) => switch (field) {
        'title' => '\u0627\u0644\u0639\u0646\u0648\u0627\u0646', // العنوان
        'username' => '\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645', // اسم المستخدم
        'url' => '\u0627\u0644\u0631\u0627\u0628\u0637', // الرابط
        'category' => '\u0627\u0644\u0641\u0626\u0629', // الفئة
        'isFavorite' => '\u0645\u0641\u0636\u0644\u0629', // مفضلة
        'strengthScore' => '\u062F\u0631\u062C\u0629 \u0627\u0644\u0642\u0648\u0629', // درجة القوة
        'encryptedPassword' => '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', // كلمة المرور
        'encryptedNotes' => '\u0627\u0644\u0645\u0644\u0627\u062D\u0638\u0627\u062A', // الملاحظات
        'encryptedTotpSecret' => '\u0633\u0631 TOTP', // سر TOTP
        _ => field,
      };

  static String _fieldDisplayValue(VaultEntry entry, String field) =>
      switch (field) {
        'title' => entry.title,
        'username' => entry.username ?? '-',
        'url' => entry.url ?? '-',
        'category' => entry.category.labelAr,
        'isFavorite' => entry.isFavorite ? '\u2764\uFE0F' : '-',
        'strengthScore' => '${entry.strengthScore}/4',
        'encryptedPassword' => entry.encryptedPassword != null
            ? '[\u0645\u0634\u0641\u0631]' // [مشفر]
            : '-',
        'encryptedNotes' => entry.encryptedNotes != null
            ? '[\u0645\u0634\u0641\u0631]'
            : '-',
        'encryptedTotpSecret' => entry.encryptedTotpSecret != null
            ? '[\u0645\u0634\u0641\u0631]'
            : '-',
        _ => '-',
      };

  static Object? _fieldValue(VaultEntry entry, String field) =>
      switch (field) {
        'title' => entry.title,
        'username' => entry.username,
        'url' => entry.url,
        'category' => entry.category.name,
        'isFavorite' => entry.isFavorite,
        'strengthScore' => entry.strengthScore,
        'encryptedPassword' => entry.encryptedPassword,
        'encryptedNotes' => entry.encryptedNotes,
        'encryptedTotpSecret' => entry.encryptedTotpSecret,
        _ => null,
      };

  static VaultEntry _applyField(
      VaultEntry target, VaultEntry source, String field) {
    return switch (field) {
      'title' => target.copyWith(title: source.title),
      'username' => target.copyWith(username: source.username),
      'url' => target.copyWith(url: source.url),
      'category' => target.copyWith(category: source.category),
      'isFavorite' => target.copyWith(isFavorite: source.isFavorite),
      'strengthScore' => target.copyWith(strengthScore: source.strengthScore),
      'encryptedPassword' =>
        target.copyWith(encryptedPassword: source.encryptedPassword),
      'encryptedNotes' =>
        target.copyWith(encryptedNotes: source.encryptedNotes),
      'encryptedTotpSecret' =>
        target.copyWith(encryptedTotpSecret: source.encryptedTotpSecret),
      _ => target,
    };
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppConstants.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : AppConstants.borderDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? color : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                      color: selected ? color : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
