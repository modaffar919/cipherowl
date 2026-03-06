import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/autofill/browser_autofill_sync_service.dart';
import 'package:cipherowl/features/settings/data/repositories/settings_repository.dart';
import 'package:cipherowl/features/settings/presentation/bloc/settings_bloc.dart';

/// Settings screen � all toggles persist to SQLCipher via [SettingsRepository].
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Toggles a setting: dispatches to [SettingsBloc] AND updates local state
  /// for immediate UI feedback (optimistic update).
  void _toggle(
    bool current,
    SettingsEvent Function() makeEvent,
    AppSettings Function(bool) update,
  ) {
    final next = !current;
    setState(() => _settings = update(next));
    context.read<SettingsBloc>().add(makeEvent());
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
            title: const Text('���������',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ?? Security ????????????????????????????????????????????
                _SectionTitle('������'),
                _ToggleCard(
                  icon: Icons.face_retouching_natural,
                  iconColor: AppConstants.primaryCyan,
                  title: 'Face-Track Lock',
                  subtitle: '���� ������ ��� �������',
                  value: _settings.faceTrack,
                  onChanged: () => _toggle(
                    _settings.faceTrack,
                    () => const SettingsFaceTrackToggled(),
                    (b) => _settings.copyWith(faceTrack: b),
                  ),
                ),
                _ToggleCard(
                  icon: Icons.fingerprint,
                  iconColor: AppConstants.accentGold,
                  title: '����� ���������',
                  subtitle: '���� ���� / ���� ���',
                  value: _settings.biometric,
                  onChanged: () => _toggle(
                    _settings.biometric,
                    () => const SettingsBiometricToggled(),
                    (b) => _settings.copyWith(biometric: b),
                  ),
                ),
                _ToggleCard(
                  icon: Icons.warning_amber,
                  iconColor: AppConstants.errorRed,
                  title: '���� ������ ���������',
                  subtitle: '���� ���� ����� ��� �������',
                  value: _settings.duressMode,
                  onChanged: () => _toggle(
                    _settings.duressMode,
                    () => const SettingsDuressModeToggled(),
                    (b) => _settings.copyWith(duressMode: b),
                  ),
                ),
                _SelectCard(
                  icon: Icons.timer_outlined,
                  iconColor: Colors.white60,
                  title: '���� ����� ��������',
                  value: '${_settings.lockTimeout} �����',
                  onTap: _showTimeoutPicker,
                ),
                _ActionCard(
                  icon: Icons.location_on_outlined,
                  iconColor: AppConstants.primaryCyan,
                  title: '������ ����������',
                  subtitle: '��� ����� ���� ������� ������',
                  onTap: () => context.go('/geofence'),
                ),
                _ActionCard(
                  icon: Icons.flight_takeoff_outlined,
                  iconColor: AppConstants.warningAmber,
                  title: '��� ������',
                  subtitle: '����� ����� ���� ������ ������',
                  onTap: () => context.go('/travel-mode'),
                ),

                const SizedBox(height: 16),

                // ?? Privacy ??????????????????????????????????????????????
                _SectionTitle('��������'),
                _ToggleCard(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: '������ ����� ������',
                  subtitle: '����� ���� ��� ������ �������',
                  value: _settings.darkWebMonitor,
                  onChanged: () => _toggle(
                    _settings.darkWebMonitor,
                    () => const SettingsDarkWebToggled(),
                    (b) => _settings.copyWith(darkWebMonitor: b),
                  ),
                ),
                _ToggleCard(
                  icon: Icons.auto_fix_high,
                  iconColor: const Color(0xFF06D6A0),
                  title: '����� ��������',
                  subtitle: '���� ������ ������ ��������',
                  value: _settings.autoFill,
                  onChanged: () => _toggle(
                    _settings.autoFill,
                    () => const SettingsAutoFillToggled(),
                    (b) => _settings.copyWith(autoFill: b),
                  ),
                ),

                const SizedBox(height: 16),

                // ?? App ??????????????????????????????????????????????????
                _SectionTitle('�������'),
                _SelectCard(
                  icon: Icons.language,
                  iconColor: Colors.white60,
                  title: '�����',
                  value: _settings.language == 'ar' ? '�������' : 'English',
                  onTap: _toggleLanguage,
                ),
                _ActionCard(
                  icon: Icons.backup_outlined,
                  iconColor: AppConstants.primaryCyan,
                  title: '��� ������� �������',
                  subtitle: 'Supabase Zero-Knowledge',
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.face_outlined,
                  iconColor: AppConstants.accentGold,
                  title: '����� ����� Face-Track',
                  subtitle: '����� ���� �����',
                  onTap: () => context.go(AppConstants.routeFaceSetup),
                ),
                _ActionCard(
                  icon: Icons.key,
                  iconColor: AppConstants.primaryCyan,
                  title: '������ FIDO2 / Passkeys',
                  subtitle: '��� ����� ���� ���',
                  onTap: () => context.go(AppConstants.routeFido2Manage),
                ),
                _ActionCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppConstants.errorRed,
                  title: '���� ����� ������',
                  subtitle: '���� ���������� ������ ������',
                  onTap: _showDuressPasswordDialog,
                ),

                const SizedBox(height: 16),

                // ?? Browser Extension ??????????????????????????????????????????
                _SectionTitle('������ ��������'),
                _ActionCard(
                  icon: Icons.extension_outlined,
                  iconColor: const Color(0xFF06D6A0),
                  title: '��� ������ ��������',
                  subtitle: 'Chrome / Firefox — ��� ���� ������',
                  onTap: _showBrowserExtensionSheet,
                ),

                const SizedBox(height: 16),

                // ?? Advanced ?????????????????????????????????????????????
                _SectionTitle('��������'),
                _ActionCard(
                  icon: Icons.business,
                  iconColor: Colors.white60,
                  title: '��� �������',
                  subtitle: 'LDAP� SSO� ����� ���������',
                  onTap: () => context.go(AppConstants.routeEnterprise),
                ),
                _ActionCard(
                  icon: Icons.delete_forever,
                  iconColor: AppConstants.errorRed,
                  title: '��� �� ��������',
                  subtitle: '�� ���� �������',
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

  void _toggleLanguage() {
    final next = _settings.language == 'ar' ? 'en' : 'ar';
    setState(() => _settings = _settings.copyWith(language: next));
    context.read<SettingsBloc>().add(SettingsLanguageChanged(next));
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
          const Text('���� ����� ��������',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...[1, 2, 5, 10, 30].map((m) => ListTile(
                title: Text('$m �����',
                    style: TextStyle(
                        color: _settings.lockTimeout == m
                            ? AppConstants.primaryCyan
                            : Colors.white70)),
                trailing: _settings.lockTimeout == m
                    ? const Icon(Icons.check, color: AppConstants.primaryCyan)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() =>
                      _settings = _settings.copyWith(lockTimeout: m));
                  context.read<SettingsBloc>().add(SettingsLockTimeoutChanged(m));
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Duress password dialog — prompts for new password (empty = clear)
  Future<void> _showBrowserExtensionSheet() async {
    final browserSync = context.read<BrowserAutofillSyncService>();
    final messenger = ScaffoldMessenger.of(context);
    final keyHex = await browserSync.exportSyncKeyHex();

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppConstants.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.extension_outlined,
                  color: Color(0xFF06D6A0), size: 22),
              const SizedBox(width: 10),
              const Text('ربط امتداد المتصفح',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            if (keyHex == null)
              const Text(
                'لم يتم إنشاء مفتاح المزامنة بعد.\n'
                'افتح الخزينة على الأقل مرة واحدة لتفعيل المزامنة السحابية.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              )
            else ...[
              const Text(
                'انسخ المفتاح أدناه والصقه في امتداد CipherOwl داخل المتصفح.\n'
                'احتفظ به في مكان آمن — من يملكه يستطيع الوصول إلى بيانات الخزينة.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF06D6A0).withAlpha(76)),
                ),
                child: SelectableText(
                  keyHex,
                  style: const TextStyle(
                    color: Color(0xFF06D6A0),
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06D6A0),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('نسخ المفتاح'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: keyHex));
                    Navigator.pop(sheetCtx);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ مفتاح الربط'),
                        backgroundColor: Color(0xFF06D6A0),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDuressPasswordDialog() {
    final ctrl = TextEditingController();
    bool obscure = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          backgroundColor: AppConstants.surfaceDark,
          title: const Text('كلمة مرور الإكراه',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'عند إدخال هذه الكلمة، يُفتح قبو وهمي فارغ دون تنبيه '
                'المهاجم. اتركها فارغة لإزالة الإعداد.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: obscure,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'كلمة مرور الإكراه (أو فارغة للإزالة)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppConstants.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38,
                      size: 18,
                    ),
                    onPressed: () => setLocalState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryCyan,
                  foregroundColor: Colors.black),
              onPressed: () {
                final pw = ctrl.text.trim();
                context.read<AuthBloc>().add(
                  AuthDuressPasswordSet(pw.isEmpty ? null : pw),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(pw.isEmpty
                        ? 'تم إزالة كلمة مرور الإكراه'
                        : 'تم حفظ كلمة مرور الإكراه'),
                    backgroundColor: AppConstants.successGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: const Text('��� �� �������ʿ',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            '���� ��� ���� ������� ������� ���� ������� ���������.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('�����')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () async {
              Navigator.pop(context);
              final authBloc = context.read<AuthBloc>();
              await context.read<SettingsRepository>().loadAll(); // noop, wipe later
              authBloc.add(const AuthVaultLocked());
            },
            child: const Text('��� �������',
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
            activeThumbColor: AppConstants.primaryCyan),
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

