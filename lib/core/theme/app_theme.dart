import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppConstants.backgroundDark,
    primaryColor: AppConstants.primaryCyan,

    colorScheme: const ColorScheme.dark(
      background:   AppConstants.backgroundDark,
      surface:      AppConstants.surfaceDark,
      primary:      AppConstants.primaryCyan,
      secondary:    AppConstants.accentGold,
      error:        AppConstants.errorRed,
      onBackground: Colors.white,
      onSurface:    Colors.white,
      onPrimary:    AppConstants.backgroundDark,
    ),

    // ── AppBar ──────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.backgroundDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),

    // ── Cards ───────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppConstants.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppConstants.borderDark, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Input Fields ────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.primaryCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.errorRed),
      ),
      labelStyle: const TextStyle(color: AppConstants.silver),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
    ),

    // ── Elevated Buttons ────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryCyan,
        foregroundColor: AppConstants.backgroundDark,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // ── Outlined Buttons ────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primaryCyan,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppConstants.primaryCyan, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Text Buttons ────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppConstants.primaryCyan,
      ),
    ),

    // ── Bottom Navigation ────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppConstants.surfaceDark,
      indicatorColor: AppConstants.primaryCyan.withOpacity(0.15),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppConstants.primaryCyan, size: 24);
        }
        return IconThemeData(color: Colors.white.withOpacity(0.5), size: 24);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            color: AppConstants.primaryCyan,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
        );
      }),
    ),

    // ── Divider ──────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppConstants.borderDark,
      thickness: 1,
    ),

    // ── Chips ────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.surfaceDark,
      selectedColor: AppConstants.primaryCyan.withOpacity(0.2),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      side: const BorderSide(color: AppConstants.borderDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // ── Switch ───────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppConstants.backgroundDark;
        }
        return AppConstants.silver;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppConstants.primaryCyan;
        }
        return AppConstants.borderDark;
      }),
    ),

    // ── Typography ───────────────────────────────────────────
    textTheme: _buildTextTheme(),
  );

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Display
      displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w300, color: Colors.white),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w300, color: Colors.white),
      displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: Colors.white),
      // Headline
      headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
      headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      // Title
      titleLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.15),
      titleSmall:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.1),
      // Body
      bodyLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white, height: 1.5),
      bodySmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70, height: 1.4),
      // Label
      labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
      labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5),
    );
  }
}

// ── Color Extensions ──────────────────────────────────────────
extension ColorExtension on Color {
  Color withLuminance(double luminance) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness(luminance.clamp(0.0, 1.0)).toColor();
  }
}
