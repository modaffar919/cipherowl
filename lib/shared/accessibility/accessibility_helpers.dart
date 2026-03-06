import 'package:flutter/material.dart';

/// WCAG 2.1 AA accessibility helpers for CipherOwl.
///
/// Provides semantic wrappers and accessibility utilities used across
/// the app to ensure screen reader compatibility (TalkBack/VoiceOver).
class AccessibilityHelpers {
  const AccessibilityHelpers._();

  // ── Minimum touch targets (WCAG 2.5.5 — Target Size) ─────────────────

  /// Minimum tappable size per WCAG 2.1 AA guidelines (44×44 dp).
  static const double minTouchTarget = 44.0;

  // ── Contrast ratios (WCAG 1.4.3 — Contrast Minimum) ──────────────────

  /// Check if two colors meet AA contrast ratio (4.5:1 for normal text).
  static bool meetsContrastAA(Color foreground, Color background) {
    return _contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if two colors meet AA contrast for large text (3:1).
  static bool meetsLargeTextContrastAA(Color foreground, Color background) {
    return _contrastRatio(foreground, background) >= 3.0;
  }

  static double _contrastRatio(Color a, Color b) {
    final lumA = a.computeLuminance();
    final lumB = b.computeLuminance();
    final lighter = lumA > lumB ? lumA : lumB;
    final darker = lumA > lumB ? lumB : lumA;
    return (lighter + 0.05) / (darker + 0.05);
  }

  // ── Text scaling ──────────────────────────────────────────────────────

  /// Returns the effective text scale factor, clamped between 1.0 and
  /// [maxScale] to prevent layouts from breaking with very large settings.
  static double clampedTextScale(BuildContext context,
      {double maxScale = 2.0}) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return scale.clamp(1.0, maxScale);
  }
}

/// Wraps a widget with [Semantics] for screen readers.
///
/// Use this for custom-painted or non-standard widgets that don't
/// natively expose accessibility information.
class SemanticLabel extends StatelessWidget {
  final String label;
  final String? hint;
  final bool isButton;
  final bool isHeader;
  final Widget child;

  const SemanticLabel({
    super.key,
    required this.label,
    this.hint,
    this.isButton = false,
    this.isHeader = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      child: child,
    );
  }
}

/// A semantic wrapper that marks content as a live region.
///
/// Screen readers will announce changes to this region automatically.
/// Use for dynamic content like sync status, timers, or notifications.
class SemanticsLiveRegion extends StatelessWidget {
  final String label;
  final Widget child;

  const SemanticsLiveRegion({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }
}

/// Ensures a tappable widget meets the minimum 44×44 touch target.
///
/// Wraps [child] with sufficient padding to meet WCAG 2.5.5.
class MinTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const MinTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AccessibilityHelpers.minTouchTarget,
            minHeight: AccessibilityHelpers.minTouchTarget,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
