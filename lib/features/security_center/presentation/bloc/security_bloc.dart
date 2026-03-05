import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';

part 'security_event.dart';
part 'security_state.dart';

/// BLoC that computes the 6-layer security score and recommendations.
///
/// Scoring (total 100 pts):
///   - Layer 1: Password strength     — up to 40 pts
///   - Layer 2: Two-factor auth (TOTP) — up to 20 pts
///   - Layer 3: Password freshness    — up to 15 pts
///   - Layer 4: AES-256-GCM encryption — fixed 15 pts
///   - Layer 5: Secure sharing        — up to 5 pts
///   - Layer 6: Breach monitoring     — fixed 5 pts
///
/// Recommendations are generated automatically based on the score gaps.
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc() : super(const SecurityInitial()) {
    on<SecurityScoreRequested>(_onScoreRequested);
    on<SecurityVaultUpdated>(_onVaultUpdated);
    on<SecurityRecommendationCompleted>(_onRecommendationCompleted);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onScoreRequested(
      SecurityScoreRequested event, Emitter<SecurityState> emit) async {
    emit(const SecurityCalculating());
    emit(_calculate(event.items));
  }

  Future<void> _onVaultUpdated(
      SecurityVaultUpdated event, Emitter<SecurityState> emit) async {
    emit(_calculate(event.items));
  }

  Future<void> _onRecommendationCompleted(
      SecurityRecommendationCompleted event,
      Emitter<SecurityState> emit) async {
    final current = state;
    if (current is SecurityLoaded) {
      emit(current.withCompleted(event.recommendationId, event.xpReward));
    }
  }

  // ── Calculation ────────────────────────────────────────────────────────────

  SecurityLoaded _calculate(List<VaultEntry> items) {
    final now = DateTime.now();
    final cutoff90 = now.subtract(const Duration(days: 90));
    final total = items.length;

    // ── Layer 1: Password Strength (max 40 pts) ───────────────────────────
    final scored = items.where((i) => i.strengthScore >= 0).toList();
    final strong = scored.where((i) => i.strengthScore >= 3).length;
    final weak = scored.where((i) => i.strengthScore <= 1).length;
    final l1 = scored.isEmpty ? 32 : (strong / scored.length * 40).round();

    // ── Layer 2: Two-Factor Auth (max 20 pts) ─────────────────────────────
    final withTotp = items
        .where((i) =>
            i.category == VaultCategory.totp ||
            i.encryptedTotpSecret != null)
        .length;
    final loginItems = items.where((i) => i.category == VaultCategory.login);
    final loginCount = loginItems.length;
    final noTotp =
        loginCount == 0 ? 0 : loginCount - withTotp.clamp(0, loginCount);
    final l2 = total == 0 ? 10 : (withTotp / total * 20).round();

    // ── Layer 3: Freshness / Updates (max 15 pts) ─────────────────────────
    final fresh = items.where((i) => i.updatedAt.isAfter(cutoff90)).length;
    final stale = total - fresh;
    final l3 = total == 0 ? 15 : (fresh / total * 15).round();

    // ── Layer 4: Encryption (fixed 15 pts) — AES-256-GCM always active ───
    const l4 = 15;

    // ── Layer 5: Secure sharing (max 5 pts) ──────────────────────────────
    // Placeholder: 3/5 until EPIC-12 sharing is implemented.
    const l5 = 3;

    // ── Layer 6: Breach monitoring (fixed 5 pts) ──────────────────────────
    // Always 5 pts: HaveIBeenPwned integration shows it's active.
    const l6 = 5;

    final score = (l1 + l2 + l3 + l4 + l5 + l6).clamp(0, 100);
    final (grade, gradeColor) = _grade(score);

    final layers = [
      SecurityLayer(
        nameAr: 'قوة كلمات المرور',
        maxPoints: 40,
        earnedPoints: l1,
        iconCodePoint: Icons.lock.codePoint,
      ),
      SecurityLayer(
        nameAr: 'المصادقة الثنائية',
        maxPoints: 20,
        earnedPoints: l2,
        iconCodePoint: Icons.security.codePoint,
      ),
      SecurityLayer(
        nameAr: 'تحديث كلمات المرور',
        maxPoints: 15,
        earnedPoints: l3,
        iconCodePoint: Icons.update.codePoint,
      ),
      SecurityLayer(
        nameAr: 'تشفير AES-256',
        maxPoints: 15,
        earnedPoints: l4,
        iconCodePoint: Icons.shield.codePoint,
      ),
      SecurityLayer(
        nameAr: 'المشاركة الآمنة',
        maxPoints: 5,
        earnedPoints: l5,
        iconCodePoint: Icons.share.codePoint,
      ),
      SecurityLayer(
        nameAr: 'مراقبة الاختراقات',
        maxPoints: 5,
        earnedPoints: l6,
        iconCodePoint: Icons.radar.codePoint,
      ),
    ];

    final recs = _buildRecommendations(
      items: items,
      weak: weak,
      noTotp: noTotp,
      stale: stale,
      l1: l1,
      l2: l2,
      l3: l3,
    );

    return SecurityLoaded(
      score: score,
      grade: grade,
      gradeColor: gradeColor,
      layers: layers,
      recommendations: recs,
      weakPasswordCount: weak,
      noTotpCount: noTotp,
      stalePasswordCount: stale,
    );
  }

  // ── Grade helper ───────────────────────────────────────────────────────────

  static (String, int) _grade(int score) {
    if (score >= 90) return ('ممتاز', AppConstants.successGreen.toARGB32());
    if (score >= 75) return ('جيد جداً', 0xFF4CAF50);
    if (score >= 60) return ('جيد', AppConstants.primaryCyan.toARGB32());
    if (score >= 40) return ('مقبول', AppConstants.warningAmber.toARGB32());
    return ('ضعيف', AppConstants.errorRed.toARGB32());
  }

  // ── Recommendations ────────────────────────────────────────────────────────

  static List<SecurityRecommendation> _buildRecommendations({
    required List<VaultEntry> items,
    required int weak,
    required int noTotp,
    required int stale,
    required int l1,
    required int l2,
    required int l3,
  }) {
    final recs = <SecurityRecommendation>[];

    if (weak > 0) {
      recs.add(SecurityRecommendation(
        id: 'weak_passwords',
        titleAr: 'كلمات مرور ضعيفة ($weak)',
        bodyAr: 'استخدم مولّد كلمات المرور لتحسين القوة وحماية حساباتك',
        xpReward: 20 * weak,
        iconCodePoint: Icons.lock_outline.codePoint,
        colorValue: AppConstants.errorRed.toARGB32(),
      ));
    }

    if (noTotp > 0) {
      recs.add(SecurityRecommendation(
        id: 'no_totp',
        titleAr: 'فعّل المصادقة الثنائية ($noTotp حساب)',
        bodyAr: 'أضف TOTP للحسابات المهمة لحماية إضافية ضد الاختراق',
        xpReward: 15 * noTotp,
        iconCodePoint: Icons.security.codePoint,
        colorValue: AppConstants.warningAmber.toARGB32(),
      ));
    }

    if (stale > 0) {
      recs.add(SecurityRecommendation(        id: 'stale_passwords',        titleAr: 'كلمات مرور قديمة ($stale)',
        bodyAr: 'لم تُحدَّث منذ أكثر من 90 يوماً — يُنصح بالتغيير الدوري',
        xpReward: 10 * stale,
        iconCodePoint: Icons.update.codePoint,
        colorValue: AppConstants.primaryCyan.toARGB32(),
      ));
    }

    if (l2 < 10) {
      recs.add(const SecurityRecommendation(
        id: 'enable_hibp',
        titleAr: 'تفعيل HaveIBeenPwned',
        bodyAr: 'فعّل مراقبة الاختراقات من إعدادات الأمان للإشعار الفوري',
        xpReward: 25,
        iconCodePoint: 0xe55b, // Icons.radar
        colorValue: 0xFF9C27B0,
      ));
    }

    if (items.isNotEmpty && items.every((i) => i.encryptedTotpSecret == null)) {
      recs.add(const SecurityRecommendation(
        id: 'setup_recovery',
        titleAr: 'إعداد مفتاح الاسترداد',
        bodyAr: 'أنشئ عبارة BIP39 المكونة من 12 كلمة لاسترداد حسابك عند فقدان كلمة المرور',
        xpReward: 30,
        iconCodePoint: 0xe8b5, // Icons.vpn_key
        colorValue: 0xFF4CAF50,
      ));
    }

    if (recs.isEmpty) {
      recs.add(const SecurityRecommendation(
        id: 'all_good',
        titleAr: 'أمانك ممتاز! 🎉',
        bodyAr: 'استمر في تحديث كلمات المرور والحفاظ على نقاطك',
        xpReward: 50,
        iconCodePoint: 0xe5ca, // Icons.check_circle
        colorValue: 0xFF4CAF50,
      ));
    }

    return recs;
  }
}
