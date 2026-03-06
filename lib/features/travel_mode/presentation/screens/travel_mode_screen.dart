import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/travel_mode/presentation/bloc/travel_mode_bloc.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';

/// Settings screen for Travel Mode.
///
/// Travel Mode hides selected vault categories from the list view —
/// useful at border crossings or in high-surveillance environments.
class TravelModeScreen extends StatelessWidget {
  const TravelModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TravelModeBloc, TravelModeState>(
      listener: (context, state) {
        if (state is TravelModeError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppConstants.errorRed,
          ));
        }
      },
      builder: (context, state) {
        final isLoaded = state is TravelModeLoaded;
        final isEnabled = isLoaded && state.isEnabled;
        final hidden = isLoaded ? state.hiddenCategories : <String>{};

        return Scaffold(
          backgroundColor: AppConstants.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppConstants.surfaceDark,
            title: const Text(
              'وضع السفر',
              style: TextStyle(
                color: AppConstants.primaryCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const BackButton(color: AppConstants.textSecondary),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Master toggle ─────────────────────────────────────────────
              _TravelToggleCard(
                isEnabled: isEnabled,
                onToggle: () =>
                    context.read<TravelModeBloc>().add(const TravelModeToggled()),
              ),
              const SizedBox(height: 16),

              // ── How it works ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined,
                        color: AppConstants.primaryCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'عند التفعيل، تُخفى الفئات المحددة أدناه من قائمة الخزنة. '
                        'تبقى البيانات مشفّرة وآمنة — لا يتم حذفها.',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Category selection ────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'الفئات المخفية',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${hidden.length} محددة)',
                    style: const TextStyle(
                        color: AppConstants.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'اختر الفئات التي تريد إخفاءها عند عبور الحدود.',
                style: TextStyle(
                    color: AppConstants.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...VaultCategory.values.map(
                (cat) => _CategoryTile(
                  category: cat,
                  isSelected: hidden.contains(cat.name),
                  enabled: isEnabled,
                  onChanged: (selected) {
                    if (!isLoaded) return;
                    final updated = Set<String>.from(
                        state.hiddenCategories);
                    if (selected) {
                      updated.add(cat.name);
                    } else {
                      updated.remove(cat.name);
                    }
                    context.read<TravelModeBloc>().add(
                          TravelModeHiddenCategoriesUpdated(updated),
                        );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Quick presets ─────────────────────────────────────────────
              const Text(
                'إعدادات سريعة',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _preset(
                    context,
                    label: 'بطاقات وهويات',
                    categories: {'card', 'identity'},
                  ),
                  const SizedBox(width: 8),
                  _preset(
                    context,
                    label: 'إخفاء الكل',
                    categories: VaultCategory.values
                        .map((c) => c.name)
                        .toSet(),
                  ),
                  const SizedBox(width: 8),
                  _preset(
                    context,
                    label: 'إلغاء التحديد',
                    categories: {},
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _preset(BuildContext context, {
    required String label,
    required Set<String> categories,
  }) =>
      Expanded(
        child: OutlinedButton(
          onPressed: () => context.read<TravelModeBloc>().add(
                TravelModeHiddenCategoriesUpdated(categories),
              ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppConstants.borderColor),
            foregroundColor: AppConstants.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
        ),
      );
}

// ── Master toggle card ────────────────────────────────────────────────────────

class _TravelToggleCard extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;

  const _TravelToggleCard({
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? AppConstants.warningOrange.withValues(alpha: 0.5)
              : AppConstants.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppConstants.warningOrange.withValues(alpha: 0.15)
                  : AppConstants.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flight_takeoff_outlined,
              color: isEnabled
                  ? AppConstants.warningOrange
                  : AppConstants.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'وضع السفر',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnabled ? '● مُفعَّل — الفئات المحددة مخفية' : 'غير مُفعَّل',
                  style: TextStyle(
                    color: isEnabled
                        ? AppConstants.warningOrange
                        : AppConstants.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeThumbColor: AppConstants.warningOrange,
          ),
        ],
      ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final VaultCategory category;
  final bool isSelected;
  final bool enabled;
  final void Function(bool selected) onChanged;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppConstants.warningOrange.withValues(alpha: 0.4)
              : AppConstants.borderColor,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: enabled ? (v) => onChanged(v ?? false) : null,
        activeColor: AppConstants.warningOrange, // CheckboxListTile still uses activeColor
        checkColor: AppConstants.backgroundDark,
        title: Text(
          category.labelAr,
          style: TextStyle(
            color: enabled ? AppConstants.textPrimary : AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _subtitle(category),
          style: const TextStyle(
              color: AppConstants.textSecondary, fontSize: 11),
        ),
        secondary: Text(
          category.emoji,
          style: const TextStyle(fontSize: 22),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _subtitle(VaultCategory cat) {
    switch (cat) {
      case VaultCategory.login:
        return 'كلمات المرور وبيانات الدخول';
      case VaultCategory.card:
        return 'بطاقات الائتمان والدفع';
      case VaultCategory.secureNote:
        return 'الملاحظات المشفّرة';
      case VaultCategory.identity:
        return 'جوازات السفر والهويات الرسمية';
      case VaultCategory.totp:
        return 'رموز المصادقة الثنائية';
    }
  }
}
