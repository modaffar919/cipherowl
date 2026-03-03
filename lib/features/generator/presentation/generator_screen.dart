import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

/// Password & Passphrase Generator
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});
  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مولّد كلمات المرور', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  const Text('اصنع كلمات مرور غير قابلة للكسر', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabs,
                    indicatorColor: AppConstants.primaryCyan,
                    labelColor: AppConstants.primaryCyan,
                    unselectedLabelColor: Colors.white38,
                    tabs: const [Tab(text: 'كلمة مرور'), Tab(text: 'عبارة مرور')],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _PasswordTab(),
                  _PassphraseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordTab extends StatefulWidget {
  const _PasswordTab();
  @override
  State<_PasswordTab> createState() => _PasswordTabState();
}

class _PasswordTabState extends State<_PasswordTab> {
  double _length = 20;
  bool _upper = true;
  bool _lower = true;
  bool _digits = true;
  bool _symbols = true;
  bool _exclude = false;
  String _result = '';
  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    const u = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const l = 'abcdefghijklmnopqrstuvwxyz';
    const d = '0123456789';
    const s = '!@#\$%^&*()-_=+[]{}|;:,.<>?';
    const ambig = 'iIlLoO01';

    var pool = '';
    if (_upper) pool += u;
    if (_lower) pool += l;
    if (_digits) pool += d;
    if (_symbols) pool += s;
    if (_exclude) pool = pool.split('').where((c) => !ambig.contains(c)).join();
    if (pool.isEmpty) pool = l;

    final rng = Random.secure();
    final pwd = List.generate(_length.toInt(), (_) => pool[rng.nextInt(pool.length)]).join();
    final score = _calcStrength(pwd);

    setState(() {
      _result = pwd;
      _strength = score;
    });
  }

  int _calcStrength(String p) {
    int s = 0;
    if (p.length >= 12) s += 20;
    if (p.length >= 20) s += 20;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 15;
    if (RegExp(r'[a-z]').hasMatch(p)) s += 15;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s += 15;
    return s;
  }

  Color get _strengthColor => _strength >= 80
      ? AppConstants.successGreen
      : _strength >= 50
          ? AppConstants.warningAmber
          : AppConstants.errorRed;

  String get _strengthLabel => _strength >= 80 ? 'قوية جداً' : _strength >= 50 ? 'متوسطة' : 'ضعيفة';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Result display
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppConstants.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppConstants.primaryCyan.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                _result,
                style: const TextStyle(
                  color: AppConstants.primaryCyan,
                  fontFamily: 'SpaceMono',
                  fontSize: 15,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: _strengthColor, size: 10),
                      const SizedBox(width: 6),
                      Text(_strengthLabel, style: TextStyle(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      _IconBtn(icon: Icons.refresh, color: AppConstants.primaryCyan, onTap: _generate),
                      const SizedBox(width: 8),
                      _IconBtn(
                        icon: Icons.copy,
                        color: Colors.white,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _result));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ كلمة المرور ✓')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Strength bar
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _strength / 100, backgroundColor: AppConstants.borderDark, color: _strengthColor, minHeight: 4, borderRadius: BorderRadius.circular(2)),

        const SizedBox(height: 24),

        // Options
        _OptionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الطول', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('${_length.toInt()}', style: const TextStyle(color: AppConstants.primaryCyan, fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              Slider(
                value: _length,
                min: 8,
                max: 64,
                divisions: 56,
                activeColor: AppConstants.primaryCyan,
                inactiveColor: AppConstants.borderDark,
                onChanged: (v) { setState(() => _length = v); _generate(); },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        _OptionCard(
          child: Column(
            children: [
              _ToggleTile(label: 'أحرف كبيرة A-Z', value: _upper, onChanged: (v) { setState(() => _upper = v); _generate(); }),
              _ToggleTile(label: 'أحرف صغيرة a-z', value: _lower, onChanged: (v) { setState(() => _lower = v); _generate(); }),
              _ToggleTile(label: 'أرقام 0-9', value: _digits, onChanged: (v) { setState(() => _digits = v); _generate(); }),
              _ToggleTile(label: 'رموز !@#', value: _symbols, onChanged: (v) { setState(() => _symbols = v); _generate(); }),
              _ToggleTile(label: 'استبعاد الأحرف المتشابهة', value: _exclude, onChanged: (v) { setState(() => _exclude = v); _generate(); }),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _PassphraseTab extends StatefulWidget {
  const _PassphraseTab();
  @override
  State<_PassphraseTab> createState() => _PassphraseTabState();
}

class _PassphraseTabState extends State<_PassphraseTab> {
  int _words = 5;
  String _sep = '-';
  bool _capitalize = true;
  String _result = '';

  static const _wordList = ['apple', 'bridge', 'castle', 'dragon', 'eagle', 'forest', 'giant', 'horse', 'island', 'jungle', 'knight', 'lantern', 'mirror', 'needle', 'ocean'];

  @override
  void initState() { super.initState(); _generate(); }

  void _generate() {
    final rng = Random.secure();
    final words = List.generate(_words, (_) {
      final w = _wordList[rng.nextInt(_wordList.length)];
      return _capitalize ? w[0].toUpperCase() + w.substring(1) : w;
    });
    setState(() => _result = words.join(_sep));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppConstants.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppConstants.accentGold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(_result, style: const TextStyle(color: AppConstants.accentGold, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBtn(icon: Icons.refresh, color: AppConstants.accentGold, onTap: _generate),
                  const SizedBox(width: 12),
                  _IconBtn(icon: Icons.copy, color: Colors.white, onTap: () {
                    Clipboard.setData(ClipboardData(text: _result));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ ✓')));
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _OptionCard(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('عدد الكلمات', style: TextStyle(color: Colors.white70)),
            Text('$_words', style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          Slider(value: _words.toDouble(), min: 3, max: 8, divisions: 5, activeColor: AppConstants.accentGold, inactiveColor: AppConstants.borderDark,
            onChanged: (v) { setState(() => _words = v.toInt()); _generate(); }),
          _ToggleTile(label: 'تكبير أول حرف', value: _capitalize, onChanged: (v) { setState(() => _capitalize = v); _generate(); }),
        ])),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final Widget child;
  const _OptionCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppConstants.borderDark)),
    child: child,
  );
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    dense: true, contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    value: value, activeColor: AppConstants.primaryCyan, onChanged: onChanged,
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

