import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                    const Text('ظ…ظˆظ„ظ‘ط¯ ظƒظ„ظ…ط§طھ ط§ظ„ظ…ط±ظˆط±', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    const Text('ط§طµظ†ط¹ ظƒظ„ظ…ط§طھ ظ…ط±ظˆط± ط؛ظٹط± ظ‚ط§ط¨ظ„ط© ظ„ظ„ظƒط³ط±', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabs,
                      indicatorColor: AppConstants.primaryCyan,
                      labelColor: AppConstants.primaryCyan,
                      unselectedLabelColor: Colors.white38,
                      tabs: const [Tab(text: 'ظƒظ„ظ…ط© ظ…ط±ظˆط±'), Tab(text: 'ط¹ط¨ط§ط±ط© ظ…ط±ظˆط±')],
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
            // â”€â”€ Result display â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppConstants.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConstants.primaryCyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Semantics(
                    label: '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u0645\u064F\u0648\u0644\u0651\u062F\u0629: ${state.password}',
                    child: Text(
                    state.password,
                    style: const TextStyle(
                      color: AppConstants.primaryCyan,
                      fontFamily: 'SpaceMono',
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                                const SnackBar(content: Text('طھظ… ظ†ط³ط® ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط± âœ“')),
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

            // â”€â”€ Animated strength bar (cipherowl-xw9) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

            // â”€â”€ Options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _OptionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ط§ظ„ط·ظˆظ„', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                  _ToggleTile(label: 'ط£ط­ط±ظپ ظƒط¨ظٹط±ط© A-Z', value: state.useUppercase, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useUppercase: v))),
                  _ToggleTile(label: 'ط£ط­ط±ظپ طµط؛ظٹط±ط© a-z', value: state.useLowercase, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useLowercase: v))),
                  _ToggleTile(label: 'ط£ط±ظ‚ط§ظ… 0-9', value: state.useDigits, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useDigits: v))),
                  _ToggleTile(label: 'ط±ظ…ظˆط² !@#', value: state.useSymbols, onChanged: (v) => bloc.add(GeneratorConfigUpdated(useSymbols: v))),
                  _ToggleTile(label: 'ط§ط³طھط¨ط¹ط§ط¯ ط§ظ„ط£ط­ط±ظپ ط§ظ„ظ…طھط´ط§ط¨ظ‡ط©', value: state.excludeAmbiguous, onChanged: (v) => bloc.add(GeneratorConfigUpdated(excludeAmbiguous: v))),
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
  final String _sep = '-';
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
            border: Border.all(color: AppConstants.accentGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(_result, style: const TextStyle(color: AppConstants.accentGold, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1), textAlign: TextAlign.center,
              semanticsLabel: '\u0639\u0628\u0627\u0631\u0629 \u0627\u0644\u0645\u0631\u0648\u0631: $_result'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBtn(icon: Icons.refresh, color: AppConstants.accentGold, onTap: _generate),
                  const SizedBox(width: 12),
                  _IconBtn(icon: Icons.copy, color: Colors.white, onTap: () {
                    Clipboard.setData(ClipboardData(text: _result));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… ط§ظ„ظ†ط³ط® âœ“')));
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _OptionCard(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('ط¹ط¯ط¯ ط§ظ„ظƒظ„ظ…ط§طھ', style: TextStyle(color: Colors.white70)),
            Text('$_words', style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          Slider(value: _words.toDouble(), min: 3, max: 8, divisions: 5, activeColor: AppConstants.accentGold, inactiveColor: AppConstants.borderDark,
            onChanged: (v) { setState(() => _words = v.toInt()); _generate(); }),
          _ToggleTile(label: 'طھظƒط¨ظٹط± ط£ظˆظ„ ط­ط±ظپ', value: _capitalize, onChanged: (v) { setState(() => _capitalize = v); _generate(); }),
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
    value: value, activeThumbColor: AppConstants.primaryCyan, onChanged: onChanged,
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    label: icon == Icons.refresh ? '\u062A\u062D\u062F\u064A\u062B' : (icon == Icons.copy ? '\u0646\u0633\u062E' : ''),
    button: true,
    child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 18),
    ),
  ),
  );
}

