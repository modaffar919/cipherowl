import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/settings/data/repositories/settings_repository.dart';

/// Settings screen ó all toggles persist to SQLCipher via [SettingsRepository].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  late AppSettings _settings;
  late SettingsRepository _repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = context.read<SettingsRepository>();
    if (_loading) _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _repo.loadAll();
    if (mounted) setState(() { _settings = s; _loading = false; });
  }

  // ?? Helpers ???????????????????????????????????????????????????????????????

  Future<void> _toggle(
    bool current,
    Future<void> Function(bool) save,
    AppSettings Function(bool) update,
  ) async {
    final next = !current;
    setState(() => _settings = update(next));
    await save(next);
  }

  // ?? Build ?????????????????????????????????????????????????????????????????

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppConstants.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppConstants.primaryCyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppConstants.backgroundDark,
            pinned: true,
            title: const Text('«·≈⁄œ«œ« ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ?? Security ????????????????????????????????????????????
                _SectionTitle('«·√„«‰'),
                _ToggleCard(
                  icon: Icons.face_retouching_natural,
                  iconColor: AppConstants.primaryCyan,
                  title: 'Face-Track Lock',
                  subtitle: 'Ìﬁ›· «·Œ“‰… ⁄‰œ «» ⁄«œﬂ',
                  value: _settings.faceTrack,
                  onChanged: () => _toggle(
                    _settings.faceTrack,
                    _repo.setFaceTrack,
                    (b) => _settings.copyWith(faceTrack: b),
                  ),
                ),
                _ToggleCard(
                  icon: Icons.fingerprint,
                  iconColor: AppConstants.accentGold,
                  title: '«·ﬁ›· «·»ÌÊ„ —Ì',
                  subtitle: '»’„… ≈’»⁄ / »’„… ÊÃÂ',
                  value: _settings.biometric,
                  onChanged: () => _toggle(
                    _settings.biometric,
                    _repo.setBiometric,
                    (b) => _settings.copyWith(biometric: b),
                  ),
                ),
                _ToggleCard(
                  icon: Icons.warning_amber,
                  iconColor: AppConstants.errorRed,
                  title: 'ﬂ·„… «·„—Ê— «·≈ﬂ—«ÂÌ…',
                  subtitle: ' › Õ Œ“‰… ›«—€… ÕÌ‰ «· ÂœÌœ',
                  value: _settings.duressMode,
                  onChanged: () => _toggle(
                    _settings.duressMode,
                    _repo.setDuressMode,
                    (b) => _settings.copyWith(duressMode: b),
                  ),
                ),
                _SelectCard(
                  icon: Icons.timer_outlined,
                  iconColor: Colors.white60,
                  title: '„Â·… «·ﬁ›· «· ·ﬁ«∆Ì',
                  value: '${_settings.lockTimeout} œﬁÌﬁ…',
                  onTap: _showTimeoutPicker,
                ),

                const SizedBox(height: 16),

                // ?? Privacy ??????????????????????????????????????????????
                _SectionTitle('«·Œ’Ê’Ì…'),
                _ToggleCard(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: '„—«ﬁ»… «·ÊÌ» «·„Ÿ·„',
                  subtitle: ' ‰»ÌÂ ›Ê—Ì ≈–« ”ı—¯»  »Ì«‰« ﬂ',
                  value: _settings.darkWebMonitor,
                  onChanged: () => _toggle(
                    _settings.darkWebMonitor,
                    _repo.setDarkWebMonitor,
                    (b) => _settings.copyWith(darkWebMonitor: b),
                  ),
                ),
                _ToggleCard(
                  icon: Icons.auto_fix_high,
                  iconColor: const Color(0xFF06D6A0),
                  title: '«·„·¡ «· ·ﬁ«∆Ì',
                  subtitle: 'Ì„·√ »Ì«‰«  «·œŒÊ·  ·ﬁ«∆Ì«',
                  value: _settings.autoFill,
                  onChanged: () => _toggle(
                    _settings.autoFill,
                    _repo.setAutoFill,
                    (b) => _settings.copyWith(autoFill: b),
                  ),
                ),

                const SizedBox(height: 16),

                // ?? App ??????????????????????????????????????????????????
                _SectionTitle('«· ÿ»Ìﬁ'),
                _SelectCard(
                  icon: Icons.language,
                  iconColor: Colors.white60,
                  title: '«··€…',
                  value: _settings.language == 'ar' ? '«·⁄—»Ì…' : 'English',
                  onTap: _toggleLanguage,
                ),
                _ActionCard(
                  icon: Icons.backup_outlined,
                  iconColor: AppConstants.primaryCyan,
                  title: '‰”Œ «Õ Ì«ÿÌ ··”Õ«»…',
                  subtitle: 'Supabase Zero-Knowledge',
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.face_outlined,
                  iconColor: AppConstants.accentGold,
                  title: '≈⁄«œ… ≈⁄œ«œ Face-Track',
                  subtitle: ' ÕœÌÀ »’„… «·ÊÃÂ',
                  onTap: () => context.go(AppConstants.routeFaceSetup),
                ),

                const SizedBox(height: 16),

                // ?? Advanced ?????????????????????????????????????????????
                _SectionTitle('«·„ ﬁœ„…'),
                _ActionCard(
                  icon: Icons.business,
                  iconColor: Colors.white60,
                  title: 'Ê÷⁄ «·„ƒ””…',
                  subtitle: 'LDAP° SSO° ≈œ«—… «·„Ã„Ê⁄« ',
                  onTap: () => context.go(AppConstants.routeEnterprise),
                ),
                _ActionCard(
                  icon: Icons.delete_forever,
                  iconColor: AppConstants.errorRed,
                  title: 'Õ–› ﬂ· «·»Ì«‰« ',
                  subtitle: '·« Ì„ﬂ‰ «· —«Ã⁄',
                  onTap: _confirmDeleteAll,
                ),

                const SizedBox(height: 32),

                Center(child: Column(children: [
                  const Text('??', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text('CipherOwl Security',
                      style: TextStyle(color: Colors.white60, fontSize: 14)),
                  Text('v${AppConstants.appVersion}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 32),
                ])),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLanguage() async {
    final next = _settings.language == 'ar' ? 'en' : 'ar';
    setState(() => _settings = _settings.copyWith(language: next));
    await _repo.setLanguage(next);
  }

  void _showTimeoutPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('„Â·… «·ﬁ›· «· ·ﬁ«∆Ì',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...[1, 2, 5, 10, 30].map((m) => ListTile(
                title: Text('$m œﬁÌﬁ…',
                    style: TextStyle(
                        color: _settings.lockTimeout == m
                            ? AppConstants.primaryCyan
                            : Colors.white70)),
                trailing: _settings.lockTimeout == m
                    ? const Icon(Icons.check, color: AppConstants.primaryCyan)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  setState(() =>
                      _settings = _settings.copyWith(lockTimeout: m));
                  await _repo.setLockTimeout(m);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: const Text('Õ–› ﬂ· «·»Ì«‰« ø',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            '”Ì „ Õ–› Ã„Ì⁄ »Ì«‰« ﬂ ‰Â«∆Ì« »œÊ‰ ≈„ﬂ«‰Ì… «·«” —œ«œ.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('≈·€«¡')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SettingsRepository>().loadAll(); // noop, wipe later
              context.read<AuthBloc>().add(const AuthVaultLocked());
            },
            child: const Text('Õ–› ‰Â«∆Ì«',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ??? Sub-widgets ?????????????????????????????????????????????????????????????

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
      );
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final VoidCallback onChanged;
  const _ToggleCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => _BaseCard(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        trailing: Switch(
            value: value,
            onChanged: (_) => onChanged(),
            activeColor: AppConstants.primaryCyan),
        onTap: onChanged,
      );
}

class _SelectCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, value;
  final VoidCallback onTap;
  const _SelectCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) => _BaseCard(
        icon: icon,
        iconColor: iconColor,
        title: title,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ]),
        onTap: onTap,
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => _BaseCard(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        trailing:
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        onTap: onTap,
      );
}

class _BaseCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  const _BaseCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      this.subtitle,
      required this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderDark)),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ])),
            trailing,
          ]),
        ),
      );
}

