import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:zxcvbn/zxcvbn.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/core/crypto/vault_crypto_service.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

/// Add or Edit an existing vault item
class AddEditItemScreen extends StatefulWidget {
  final String? itemId; // null = new item
  const AddEditItemScreen({super.key, this.itemId});
  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  bool get _isEdit => widget.itemId != null;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _totpCtrl = TextEditingController();

  bool _obscurePass = true;
  VaultCategory _category = VaultCategory.login;
  double _strength = 0;
  bool _isSaving = false;

  static final _categories = VaultCategory.values;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadItem();
  }

  void _loadItem() {
    final state = context.read<VaultBloc>().state;
    if (state is VaultLoaded) {
      final found = state.allItems
          .where((i) => i.id == widget.itemId)
          .firstOrNull;
      if (found != null) {
        _titleCtrl.text = found.title;
        _userCtrl.text = found.username ?? '';
        _urlCtrl.text = found.url ?? '';
        _category = found.category;
        _strength =
            found.strengthScore >= 0 ? found.strengthScore / 4.0 : 0;

        // Decrypt stored password for editing
        if (found.encryptedPassword != null &&
            found.encryptedPassword!.isNotEmpty) {
          context
              .read<VaultCryptoService>()
              .decrypt(found.encryptedPassword!)
              .then((decrypted) {
            if (mounted) setState(() => _passCtrl.text = decrypted);
          }).catchError((_) {/* leave blank if decrypt fails */});
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // Capture context-dependent refs BEFORE the first await (lint: use_build_context_synchronously)
    final authState = context.read<AuthBloc>().state;
    final userId =
        authState is AuthAuthenticated ? authState.userId : 'local_user';
    final crypto = context.read<VaultCryptoService>();
    final vaultBloc = context.read<VaultBloc>();

    final now = DateTime.now();

    // Encrypt password with Rust AES-256-GCM
    Uint8List? encryptedPwd;
    if (_passCtrl.text.isNotEmpty) {
      encryptedPwd = await crypto.encrypt(_passCtrl.text.trim());
    }

    if (_isEdit) {
      final existing = (vaultBloc.state as VaultLoaded)
          .allItems
          .firstWhere((i) => i.id == widget.itemId!);
      vaultBloc.add(
            VaultItemUpdated(
              existing.copyWith(
                title: _titleCtrl.text.trim(),
                username:
                    _userCtrl.text.isEmpty ? null : _userCtrl.text.trim(),
                encryptedPassword:
                    encryptedPwd ?? existing.encryptedPassword,
                url: _urlCtrl.text.isEmpty ? null : _urlCtrl.text.trim(),
                category: _category,
                updatedAt: now,
              ),
            ),
          );
    } else {
      vaultBloc.add(
            VaultItemAdded(
              VaultEntry(
                id: const Uuid().v4(),
                userId: userId,
                title: _titleCtrl.text.trim(),
                username:
                    _userCtrl.text.isEmpty ? null : _userCtrl.text.trim(),
                encryptedPassword: encryptedPwd,
                url: _urlCtrl.text.isEmpty ? null : _urlCtrl.text.trim(),
                category: _category,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );
    }
    setState(() => _isSaving = false);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: Text(_isEdit ? 'طھط¹ط¯ظٹظ„ ط§ظ„ط­ط³ط§ط¨' : 'ط­ط³ط§ط¨ ط¬ط¯ظٹط¯',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? 'ط¬ط§ط±ظٹ ط§ظ„ط­ظپط¸...' : 'ط­ظپط¸',
                style: const TextStyle(color: AppConstants.primaryCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category selector
            _buildCategorySelector(),
            const SizedBox(height: 20),

            // Title
            _buildField(ctrl: _titleCtrl, label: 'ط§ط³ظ… ط§ظ„ط­ط³ط§ط¨', hint: 'ظ…ط«ط§ظ„: Google', validator: _required),
            const SizedBox(height: 12),

            // Username
            _buildField(ctrl: _userCtrl, label: 'ط§ط³ظ… ط§ظ„ظ…ط³طھط®ط¯ظ… / ط§ظ„ط¨ط±ظٹط¯', hint: 'user@example.com'),
            const SizedBox(height: 12),

            // Password
            _buildPasswordField(),
            const SizedBox(height: 12),

            // URL
            _buildField(ctrl: _urlCtrl, label: 'ط§ظ„ظ…ظˆظ‚ط¹ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ', hint: 'https://...', keyboard: TextInputType.url),
            const SizedBox(height: 12),

            // TOTP
            _buildField(ctrl: _totpCtrl, label: 'ظ…ظپطھط§ط­ TOTP (ط§ط®طھظٹط§ط±ظٹ)', hint: 'JBSWY3DPEHPK3PXP'),
            const SizedBox(height: 12),

            // Notes
            _buildField(ctrl: _notesCtrl, label: 'ظ…ظ„ط§ط­ط¸ط§طھ', hint: 'ط£ظٹ ظ…ط¹ظ„ظˆظ…ط§طھ ط¥ط¶ط§ظپظٹط©...', maxLines: 3),

            const SizedBox(height: 24),

            // Generate password button
            OutlinedButton.icon(
              onPressed: () => context.go(AppConstants.routeGenerator),
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('طھظˆظ„ظٹط¯ ظƒظ„ظ…ط© ظ…ط±ظˆط± ظ‚ظˆظٹط©'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ط§ظ„ظپط¦ط©',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((c) {
              final sel = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppConstants.primaryCyan.withAlpha(38)
                        : AppConstants.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? AppConstants.primaryCyan.withAlpha(128)
                            : AppConstants.borderDark),
                  ),
                  child: Row(
                    children: [
                      Text(c.emoji),
                      const SizedBox(width: 6),
                      Text(c.labelAr,
                          style: TextStyle(
                              color: sel
                                  ? AppConstants.primaryCyan
                                  : Colors.white60,
                              fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(color: Colors.white, fontFamily: 'SpaceMono'),
          decoration: InputDecoration(
            labelText: 'ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط±',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.white38),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ],
            ),
          ),
          onChanged: (v) {
            final score = v.isEmpty ? 0 : (Zxcvbn().evaluate(v).score ?? 0);
            setState(() => _strength = score / 4.0);
          },
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: _strength,
          backgroundColor: AppConstants.borderDark,
          color: _strength < 0.4 ? AppConstants.errorRed : _strength < 0.7 ? AppConstants.warningAmber : AppConstants.successGreen,
          minHeight: 3,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  TextFormField _buildField({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'ظ‡ط°ط§ ط§ظ„ط­ظ‚ظ„ ظ…ط·ظ„ظˆط¨' : null;
}

