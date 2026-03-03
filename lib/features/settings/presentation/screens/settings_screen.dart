import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';

/// Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _faceTrack = true;
  bool _biometric = true;
  bool _darkWeb = true;
  bool _autoFill = true;
  bool _duressMode = false;
  int _lockTimeout = 5;
  String _lang = 'ar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppConstants.backgroundDark,
            pinned: true,
            title: const Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            centerTitle: false,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Security Section
                _SectionTitle('الأمان'),
                _ToggleCard(
                  icon: Icons.face_retouching_natural, iconColor: AppConstants.primaryCyan,
                  title: 'Face-Track Lock', subtitle: 'يقفل الخزنة عند ابتعادك',
                  value: _faceTrack, onChanged: (v) => setState(() => _faceTrack = v),
                ),
                _ToggleCard(
                  icon: Icons.fingerprint, iconColor: AppConstants.accentGold,
                  title: 'القفل البيومتري', subtitle: 'بصمة إصبع / بصمة وجه',
                  value: _biometric, onChanged: (v) => setState(() => _biometric = v),
                ),
                _ToggleCard(
                  icon: Icons.warning_amber, iconColor: AppConstants.errorRed,
                  title: 'كلمة المرور الإكراهية', subtitle: 'تفتح خزنة فارغة حين التهديد',
                  value: _duressMode, onChanged: (v) => setState(() => _duressMode = v),
                ),
                _SelectCard(
                  icon: Icons.timer_outlined, iconColor: Colors.white60,
                  title: 'مهلة القفل التلقائي',
                  value: '$_lockTimeout دقيقة',
                  onTap: () => _showTimeoutPicker(),
                ),

                const SizedBox(height: 16),
                _SectionTitle('الخصوصية'),
                _ToggleCard(
                  icon: Icons.dark_mode_outlined, iconColor: Color(0xFF8B5CF6),
                  title: 'مراقبة الويب المظلم', subtitle: 'تنبيه فوري إذا سُرّبت بياناتك',
                  value: _darkWeb, onChanged: (v) => setState(() => _darkWeb = v),
                ),
                _ToggleCard(
                  icon: Icons.auto_fix_high, iconColor: Color(0xFF06D6A0),
                  title: 'الملء التلقائي', subtitle: 'يملأ بيانات الدخول تلقائياً',
                  value: _autoFill, onChanged: (v) => setState(() => _autoFill = v),
                ),

                const SizedBox(height: 16),
                _SectionTitle('التطبيق'),
                _SelectCard(
                  icon: Icons.language, iconColor: Colors.white60,
                  title: 'اللغة',
                  value: _lang == 'ar' ? 'العربية' : 'English',
                  onTap: () => setState(() => _lang = _lang == 'ar' ? 'en' : 'ar'),
                ),
                _ActionCard(
                  icon: Icons.backup_outlined, iconColor: AppConstants.primaryCyan,
                  title: 'نسخ احتياطي للسحابة', subtitle: 'Supabase Zero-Knowledge',
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.face_outlined, iconColor: AppConstants.accentGold,
                  title: 'إعادة إعداد Face-Track', subtitle: 'تحديث بصمة الوجه',
                  onTap: () => context.go(AppConstants.routeFaceSetup),
                ),

                const SizedBox(height: 16),
                _SectionTitle('المتقدمة'),
                _ActionCard(
                  icon: Icons.business, iconColor: Colors.white60,
                  title: 'وضع المؤسسة', subtitle: 'LDAP، SSO، إدارة المجموعات',
                  onTap: () => context.go(AppConstants.routeEnterprise),
                ),
                _ActionCard(
                  icon: Icons.delete_forever, iconColor: AppConstants.errorRed,
                  title: 'حذف كل البيانات', subtitle: 'لا يمكن التراجع',
                  onTap: () => _confirmDelete(),
                ),

                const SizedBox(height: 32),

                // App info
                Center(
                  child: Column(children: [
                    const Text('🦉', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Text('CipherOwl Security', style: TextStyle(color: Colors.white60, fontSize: 14)),
                    Text('v${AppConstants.appVersion}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 32),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeoutPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('مهلة القفل التلقائي', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...[1, 2, 5, 10, 30].map((m) => ListTile(
            title: Text('$m دقيقة', style: TextStyle(color: _lockTimeout == m ? AppConstants.primaryCyan : Colors.white70)),
            trailing: _lockTimeout == m ? const Icon(Icons.check, color: AppConstants.primaryCyan) : null,
            onTap: () { setState(() => _lockTimeout = m); Navigator.pop(context); },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: const Text('حذف كل البيانات؟', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم حذف جميع بياناتك نهائياً بدون إمكانية الاسترداد.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
            onPressed: () {},
            child: const Text('حذف نهائياً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);      
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );
}

class _ToggleCard extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title, subtitle;
  final bool value; final ValueChanged<bool> onChanged;
  const _ToggleCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => _BaseCard(
    icon: icon, iconColor: iconColor, title: title, subtitle: subtitle,
    trailing: Switch(value: value, onChanged: onChanged, activeColor: AppConstants.primaryCyan),
    onTap: () => onChanged(!value),
  );
}

class _SelectCard extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title, value; final VoidCallback onTap;
  const _SelectCard({required this.icon, required this.iconColor, required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => _BaseCard(
    icon: icon, iconColor: iconColor, title: title,
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
    ]),
    onTap: onTap,
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title, subtitle; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => _BaseCard(
    icon: icon, iconColor: iconColor, title: title, subtitle: subtitle,
    trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
    onTap: onTap,
  );
}

class _BaseCard extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title; final String? subtitle;
  final Widget trailing; final VoidCallback onTap;
  const _BaseCard({required this.icon, required this.iconColor, required this.title, this.subtitle, required this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(  
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConstants.borderDark)),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: const TextStyle(color: Colors.white38, fontSize: 12))],
        ])),
        trailing,
      ]),
    ),
  );
}

