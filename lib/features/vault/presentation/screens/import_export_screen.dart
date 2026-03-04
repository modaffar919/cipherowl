import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:zxcvbn/zxcvbn.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/core/crypto/vault_crypto_service.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});
  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _importing = false;
  bool _exporting = false;
  List<_ParsedEntry>? _preview;
  String? _errorMsg;

  static const _uuid = Uuid();

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _pickAndParse() async {
    setState(() { _preview = null; _errorMsg = null; });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    try {
      final csv = utf8.decode(bytes);
      final parsed = _parseCsv(csv);
      setState(() => _preview = parsed);
    } catch (e) {
      setState(() => _errorMsg = 'تعذّر قراءة الملف: $e');
    }
  }

  List<_ParsedEntry> _parseCsv(String csv) {
    final rows = CsvDecoder().convert(csv);
    if (rows.isEmpty) return [];
    final headers = rows.first.map((h) => h.toString().toLowerCase().trim()).toList();

    final entries = <_ParsedEntry>[];
    for (final row in rows.skip(1)) {
      if (row.isEmpty) continue;
      String get(String key) {
        final idx = headers.indexOf(key);
        return idx >= 0 && idx < row.length ? row[idx].toString().trim() : '';
      }

      // Chrome / Firefox / Generic
      final name = get('name').isNotEmpty ? get('name') : get('title');
      final username = get('username');
      final password = get('password');
      final url = get('url').isNotEmpty ? get('url') : get('login_uri');

      // Bitwarden specific
      final bwType = get('type');
      final isSecureNote = bwType == 'note' || bwType == '2';

      if (name.isEmpty && username.isEmpty && password.isEmpty) continue;

      entries.add(_ParsedEntry(
        title: name.isNotEmpty ? name : (url.isNotEmpty ? Uri.tryParse(url)?.host ?? url : 'مستورد'),
        username: username,
        password: password,
        url: url,
        isSecureNote: isSecureNote,
      ));
    }
    return entries;
  }

  Future<void> _confirmImport() async {
    final preview = _preview;
    if (preview == null || preview.isEmpty) return;

    setState(() => _importing = true);
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState is AuthAuthenticated ? authState.userId : 'local_user';
      final crypto = context.read<VaultCryptoService>();
      final zx = Zxcvbn();
      final now = DateTime.now();
      final entries = <VaultEntry>[];

      for (final p in preview) {
        Uint8List? encPwd;
        int strength = -1;
        if (p.password.isNotEmpty) {
          encPwd = await crypto.encrypt(p.password);
          strength = (zx.evaluate(p.password).score ?? 0).toInt();
        }

        entries.add(VaultEntry(
          id: _uuid.v4(),
          userId: userId,
          title: p.title,
          username: p.username.isNotEmpty ? p.username : null,
          encryptedPassword: encPwd,
          url: p.url.isNotEmpty ? p.url : null,
          category: p.isSecureNote ? VaultCategory.secureNote : VaultCategory.login,
          strengthScore: strength,
          createdAt: now,
          updatedAt: now,
        ));
      }

      if (mounted) {
        context.read<VaultBloc>().add(VaultItemsImported(entries));
        setState(() { _importing = false; _preview = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جارٍ استيراد ${entries.length} حساب...'),
            backgroundColor: AppConstants.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _importing = false; _errorMsg = 'خطأ أثناء الاستيراد: $e'; });
      }
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final vaultState = context.read<VaultBloc>().state;
      if (vaultState is! VaultLoaded) {
        setState(() { _exporting = false; _errorMsg = 'الخزنة غير محملة'; });
        return;
      }
      final crypto = context.read<VaultCryptoService>();
      final items = vaultState.allItems;

      final rows = <List<String>>[
        ['name', 'url', 'username', 'password', 'category'],
      ];

      for (final item in items) {
        String pwd = '';
        if (item.encryptedPassword != null && item.encryptedPassword!.isNotEmpty) {
          try { pwd = await crypto.decrypt(item.encryptedPassword!); } catch (_) {}
        }
        rows.add([
          item.title,
          item.url ?? '',
          item.username ?? '',
          pwd,
          item.category.name,
        ]);
      }

      final csvStr = CsvEncoder().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cipherowl_export.csv');
      await file.writeAsString(csvStr, encoding: utf8);

      if (mounted) {
        setState(() => _exporting = false);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          subject: 'CipherOwl Export',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _exporting = false; _errorMsg = 'خطأ أثناء التصدير: $e'; });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text('استيراد / تصدير',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Import Section ────────────────────────────────────────
          _SectionHeader(
            icon: Icons.upload_file,
            title: 'استيراد كلمات المرور',
            color: AppConstants.primaryCyan,
          ),
          const SizedBox(height: 8),
          _InfoCard(
            text: 'يدعم: Chrome، Firefox، Bitwarden (CSV)\n'
                'تُشفَّر جميع كلمات المرور بـ AES-256-GCM قبل الحفظ',
          ),
          const SizedBox(height: 12),

          // Pick file button
          _ActionButton(
            icon: Icons.folder_open,
            label: 'اختر ملف CSV',
            color: AppConstants.primaryCyan,
            onPressed: _importing ? null : _pickAndParse,
          ),

          // Preview
          if (_preview != null) ...[
            const SizedBox(height: 16),
            _PreviewCard(
              entries: _preview!,
              onConfirm: _importing ? null : _confirmImport,
              isLoading: _importing,
            ),
          ],

          const SizedBox(height: 28),
          const Divider(color: AppConstants.borderDark),
          const SizedBox(height: 28),

          // ── Export Section ────────────────────────────────────────
          _SectionHeader(
            icon: Icons.download,
            title: 'تصدير كلمات المرور',
            color: AppConstants.accentGold,
          ),
          const SizedBox(height: 8),
          _InfoCard(
            text: 'يُصدَّر ملف CSV متوافق مع Chrome وBitwarden\n'
                '⚠️  الملف يحتوي كلمات مرور بنص واضح — احفظه بأمان',
            isWarning: true,
          ),
          const SizedBox(height: 12),

          _ActionButton(
            icon: Icons.share,
            label: _exporting ? 'جارٍ التصدير...' : 'تصدير وإرسال',
            color: AppConstants.accentGold,
            onPressed: _exporting ? null : _exportCsv,
            isLoading: _exporting,
          ),

          // Error
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppConstants.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppConstants.errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppConstants.errorRed, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ParsedEntry {
  final String title;
  final String username;
  final String password;
  final String url;
  final bool isSecureNote;
  const _ParsedEntry({
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.isSecureNote,
  });
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(width: 8),
    Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
  ]);
}

class _InfoCard extends StatelessWidget {
  final String text;
  final bool isWarning;
  const _InfoCard({required this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppConstants.warningAmber : Colors.white38;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, height: 1.6)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton.icon(
      icon: isLoading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryCyan))
          : Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: onPressed == null ? Colors.white38 : color, fontSize: 15, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: onPressed == null ? AppConstants.borderDark : color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  final List<_ParsedEntry> entries;
  final VoidCallback? onConfirm;
  final bool isLoading;
  const _PreviewCard({required this.entries, this.onConfirm, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryCyan.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.list_alt, color: AppConstants.primaryCyan, size: 16),
          const SizedBox(width: 6),
          Text('تم اكتشاف ${entries.length} حساب',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        // Show first 5 as preview
        ...entries.take(5).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(e.isSecureNote ? Icons.note : Icons.key,
                color: Colors.white38, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(e.title,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis)),
            Text(e.username,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ]),
        )),
        if (entries.length > 5)
          Text('+ ${entries.length - 5} أخرى...',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.check, size: 18),
            label: Text(isLoading ? 'جارٍ الاستيراد...' : 'تأكيد الاستيراد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onConfirm,
          ),
        ),
      ]),
    );
  }
}
