import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';

/// Desktop system tray integration for CipherOwl.
///
/// Provides quick-access tray icon with lock/unlock, password generator,
/// and quit actions on Windows, macOS, and Linux.
class SystemTrayService {
  SystemTrayService({
    required VoidCallback onShowApp,
    required VoidCallback onLockVault,
    required VoidCallback onQuit,
  })  : _onShowApp = onShowApp,
        _onLockVault = onLockVault,
        _onQuit = onQuit;

  final VoidCallback _onShowApp;
  final VoidCallback _onLockVault;
  final VoidCallback _onQuit;

  final SystemTray _systemTray = SystemTray();

  /// Whether the current platform supports system tray.
  static bool get isSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Initialise the tray icon and context menu. No-op on unsupported platforms.
  Future<void> init() async {
    if (!isSupported) return;

    String iconPath;
    if (Platform.isWindows) {
      iconPath = 'windows/runner/resources/app_icon.ico';
    } else {
      iconPath = 'assets/logo/cipherowl_logo.png';
    }

    await _systemTray.initSystemTray(
      title: 'CipherOwl',
      iconPath: iconPath,
      toolTip: 'CipherOwl Password Manager',
    );

    await _systemTray.setContextMenu([
      MenuItem(label: 'فتح CipherOwl', onClicked: _onShowApp),
      MenuSeparator(),
      MenuItem(label: 'قفل الخزينة', onClicked: _onLockVault),
      MenuSeparator(),
      MenuItem(label: 'خروج', onClicked: _onQuit),
    ]);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      _systemTray.popUpContextMenu();
    });
  }

  /// Update the tray tooltip text (e.g. vault status).
  Future<void> updateTooltip(String tooltip) async {
    if (!isSupported) return;
    await _systemTray.setToolTip(tooltip);
  }
}
