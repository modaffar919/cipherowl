import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import 'vault_list_screen.dart';
import '../../../security_center/presentation/screens/security_center_screen.dart';
import '../../../generator/presentation/generator_screen.dart';
import '../../../academy/presentation/screens/academy_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main Dashboard — entry point that shows VaultListScreen by default,
/// with a persistent bottom navigation bar
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    _NavItem(icon: Icons.lock_outline, activeIcon: Icons.lock, labelAr: 'الخزنة', route: AppConstants.routeVault),
    _NavItem(icon: Icons.security_outlined, activeIcon: Icons.security, labelAr: 'الأمان', route: AppConstants.routeSecurityCenter),
    _NavItem(icon: Icons.casino_outlined, activeIcon: Icons.casino, labelAr: 'المولّد', route: AppConstants.routeGenerator),
    _NavItem(icon: Icons.school_outlined, activeIcon: Icons.school, labelAr: 'الأكاديمية', route: AppConstants.routeAcademy),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, labelAr: 'الإعدادات', route: AppConstants.routeSettings),
  ];

  // One persistent screen instance per tab
  static const _screens = [
    VaultListScreen(),
    SecurityCenterScreen(),
    GeneratorScreen(),
    AcademyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _CipherBottomNav(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onTap: (i) {
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelAr;
  final String route;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelAr,
    required this.route,
  });
}

class _CipherBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> destinations;
  final ValueChanged<int> onTap;

  const _CipherBottomNav({
    required this.selectedIndex,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceDark,
        border: Border(top: BorderSide(color: AppConstants.borderDark, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (i) {
              final active = selectedIndex == i;
              final item = destinations[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: active ? AppConstants.primaryCyan.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          active ? item.activeIcon : item.icon,
                          color: active ? AppConstants.primaryCyan : Colors.white38,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.labelAr,
                        style: TextStyle(
                          color: active ? AppConstants.primaryCyan : Colors.white38,
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
