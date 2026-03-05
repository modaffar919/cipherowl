import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:meta/meta.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/generator/presentation/bloc/generator_bloc.dart';

/// Password & Passphrase Generator
class GeneratorScreen extends StatefulWidget {
  /// Optionally override the [GeneratorBloc] factory for testing.
  /// When non-null, the real Rust-backed bloc is NOT created.
  @visibleForTesting
  final GeneratorBloc Function()? createBloc;

  const GeneratorScreen({super.key, this.createBloc});
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
    return BlocProvider<GeneratorBloc>(
      create: (_) => widget.createBloc?.call() ?? GeneratorBloc(),
      child: Scaffold(
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
      ),
    );
  }
}

class _PasswordTab extends StatelessWidget {
  const _PasswordTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneratorBloc, GeneratorState>(
      builder: (context, state) {
        final bloc = context.read<GeneratorBloc>();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Result display ───────────────────────────────────────────
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
                    state.password,
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
                      // Strength label
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: state.strengthColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              state.strengthLabel,
                              key: ValueKey(state.strengthLabel),
                              style: TextStyle(color: state.strengthColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _IconBtn(
                            icon: Icons.refresh,
                            color: AppConstants.primaryCyan,
                            onTap: () => bloc.add(const GeneratorRefreshRequested()),
                          ),
                          const SizedBox(width: 8),
                          _IconBtn(
                            icon: Icons.copy,
                            color: Colors.white,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: state.password));
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

            // ── Animated strength bar (cipherowl-xw9) ───────────────────
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: state.strengthScore / 4.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, value, __) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppConstants.borderDark,
                  valueColor: AlwaysStoppedAnimation<Color>(state.strengthColor),
                  minHeight: 6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Options ──────────────────────────────────────────────────
            _OptionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الطول', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('${state.length.toInt()}', style: const TextStyle(color: AppConstants.primaryCyan, fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: state.length,
                    min: 8,
                    max: 64,
                    divisions: 56,
                    activeColor: AppConstants.primaryCyan,
                    inactiveColor: AppConstants.borderDark,
                    onChanged: (v) => bloc.add(GeneratorConfigUpdated(length: v)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _OptionCard(
              child: Column(
                children: [
                  _ToggleTile(label: 'أحرف كبيرة A-Z', value: state.useUppercase, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useUppercase: v))),
                  _ToggleTile(label: 'أحرف صغيرة a-z', value: state.useLowercase, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useLowercase: v))),
                  _ToggleTile(label: 'أرقام 0-9', value: state.useDigits, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useDigits: v))),
                  _ToggleTile(label: 'رموز !@#', value: state.useSymbols, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useSymbols: v))),
                  _ToggleTile(label: 'استبعاد الأحرف المتشابهة', value: state.excludeAmbiguous, onChanged: (v) => bloc.add(GeneratorConfigUpdated(excludeAmbiguous: v))),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        );
      },
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

