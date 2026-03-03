import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

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
  String _category = 'social';
  double _strength = 0;
  bool _isSaving = false;

  static const _categories = ['social', 'work', 'finance', 'entertainment', 'other'];
  static const _catIcons = {'social': '👥', 'work': '💼', 'finance': '🏦', 'entertainment': '🎬', 'other': '📁'};
  static const _catLabels = {'social': 'تواصل', 'work': 'عمل', 'finance': 'مالي', 'entertainment': 'ترفيه', 'other': 'أخرى'};

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadItem();
  }

  void _loadItem() {
    // TODO: load from drift
    _titleCtrl.text = 'Google';
    _userCtrl.text = 'user@gmail.com';
    _passCtrl.text = 'SecureP@ss123!';
    _urlCtrl.text = 'https://accounts.google.com';
    _category = 'social';
    _strength = 0.95;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    // TODO: Save to drift + sync Supabase
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: Text(_isEdit ? 'تعديل الحساب' : 'حساب جديد',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ',
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
            _buildField(ctrl: _titleCtrl, label: 'اسم الحساب', hint: 'مثال: Google', validator: _required),
            const SizedBox(height: 12),

            // Username
            _buildField(ctrl: _userCtrl, label: 'اسم المستخدم / البريد', hint: 'user@example.com'),
            const SizedBox(height: 12),

            // Password
            _buildPasswordField(),
            const SizedBox(height: 12),

            // URL
            _buildField(ctrl: _urlCtrl, label: 'الموقع الإلكتروني', hint: 'https://...', keyboard: TextInputType.url),
            const SizedBox(height: 12),

            // TOTP
            _buildField(ctrl: _totpCtrl, label: 'مفتاح TOTP (اختياري)', hint: 'JBSWY3DPEHPK3PXP'),
            const SizedBox(height: 12),

            // Notes
            _buildField(ctrl: _notesCtrl, label: 'ملاحظات', hint: 'أي معلومات إضافية...', maxLines: 3),

            const SizedBox(height: 24),

            // Generate password button
            OutlinedButton.icon(
              onPressed: () => context.go(AppConstants.routeGenerator),
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('توليد كلمة مرور قوية'),
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
        const Text('الفئة', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppConstants.primaryCyan.withOpacity(0.15) : AppConstants.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppConstants.primaryCyan.withOpacity(0.5) : AppConstants.borderDark),
                  ),
                  child: Row(
                    children: [
                      Text(_catIcons[c]!),
                      const SizedBox(width: 6),
                      Text(_catLabels[c]!,
                          style: TextStyle(color: sel ? AppConstants.primaryCyan : Colors.white60, fontSize: 13)),
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
            labelText: 'كلمة المرور',
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
            // TODO: zxcvbn strength
            setState(() => _strength = (v.length / 20).clamp(0.0, 1.0));
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

  String? _required(String? v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null;
}

