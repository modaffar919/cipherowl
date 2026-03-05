import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/vault/domain/entities/vault_entry.dart';
import 'package:cipherowl/features/vault/presentation/bloc/vault_bloc.dart';

/// Vault List â€” shows all password entries from the local Drift database.
class VaultListScreen extends StatefulWidget {
  const VaultListScreen({super.key});
  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen> {
  final _searchCtrl = TextEditingController();

  static const _categories = [
    ('all', 'ط§ظ„ظƒظ„', Icons.grid_view),
    ('login', 'ط¯ط®ظˆظ„', Icons.key),
    ('card', 'ط¨ط·ط§ظ‚ط©', Icons.credit_card),
    ('secureNote', 'ظ…ظ„ط§ط­ط¸ط§طھ', Icons.note),
    ('identity', 'ظ‡ظˆظٹط©', Icons.badge),
    ('totp', 'TOTP', Icons.lock_clock),
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthDuressAuthenticated) {
      context.read<VaultBloc>().add(const VaultDuressActivated());
    } else {
      final userId =
          authState is AuthAuthenticated ? authState.userId : 'local_user';
      context.read<VaultBloc>().add(VaultStarted(userId));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VaultBloc, VaultState>(
      listener: (context, state) {
        if (state is VaultLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: state.isError
                  ? AppConstants.errorRed
                  : AppConstants.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<VaultBloc>().add(const VaultMessageDismissed());
        }
      },
      builder: (context, state) {
        final isLoaded = state is VaultLoaded;
        final items = isLoaded ? state.filteredItems : <VaultEntry>[];
        final totalCount = isLoaded ? state.allItems.length : 0;
        final securityScore = isLoaded ? state.securityScore : 0;
        final selectedCategory = isLoaded ? state.categoryFilter : null;
        final isOperating = isLoaded ? state.isOperating : false;

        return Scaffold(
          backgroundColor: AppConstants.backgroundDark,
          body: CustomScrollView(
            slivers: [
              // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverAppBar(
                backgroundColor: AppConstants.backgroundDark,
                floating: true,
                pinned: false,
                title: const Text(
                  'ط®ط²ظ†طھظٹ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                centerTitle: false,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _scoreColor(securityScore).withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _scoreColor(securityScore).withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield,
                            color: _scoreColor(securityScore), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$securityScore',
                          style: TextStyle(
                            color: _scoreColor(securityScore),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOperating)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConstants.primaryCyan),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: AppConstants.surfaceDark,
                    onSelected: (val) {
                      if (val == 'import_export') {
                        context.push(AppConstants.routeImportExport);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'import_export',
                        child: Row(children: [
                          Icon(Icons.import_export, color: AppConstants.primaryCyan, size: 18),
                          SizedBox(width: 10),
                          Text('استيراد / تصدير', style: TextStyle(color: Colors.white)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),

              // â”€â”€ Search + Category Chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _searchCtrl,
                        onChanged: (v) => context
                            .read<VaultBloc>()
                            .add(VaultSearchChanged(v)),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'ط§ط¨ط­ط« ط¹ظ† ط­ط³ط§ط¨...',
                          prefixIcon: Icon(Icons.search,
                              color: Colors.white38, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((c) {
                            final catKey = c.$1 == 'all' ? null : c.$1;
                            final isAllChip = c.$1 == 'all';
                            final effectiveSelected = isAllChip
                                ? selectedCategory == null
                                : selectedCategory == catKey;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(c.$2),
                                selected: effectiveSelected,
                                onSelected: (_) => context
                                    .read<VaultBloc>()
                                    .add(VaultCategoryChanged(catKey)),
                                avatar: Icon(c.$3, size: 14),
                                selectedColor:
                                    AppConstants.primaryCyan.withAlpha(51),
                                backgroundColor: AppConstants.surfaceDark,
                                labelStyle: TextStyle(
                                  color: effectiveSelected
                                      ? AppConstants.primaryCyan
                                      : Colors.white60,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: effectiveSelected
                                      ? AppConstants.primaryCyan.withAlpha(128)
                                      : AppConstants.borderDark,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (state is VaultLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppConstants.primaryCyan),
                  ),
                )
              else if (state is VaultError)
                SliverFillRemaining(
                  child: Center(
                    child: Text('ط®ط·ط£: ${state.message}',
                        style: const TextStyle(
                            color: AppConstants.errorRed)),
                  ),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  child: _EmptyPlaceholder(
                    hasFilter: isLoaded &&
                        ((state as VaultLoaded).searchQuery.isNotEmpty ||
                            (state).categoryFilter != null),
                    totalCount: totalCount,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final item = items[i];
                        return _VaultCard(
                          entry: item,
                          onTap: () => context.go('/vault/${item.id}'),
                          onDelete: () => context
                              .read<VaultBloc>()
                              .add(VaultItemDeleted(item.id)),
                          onFavorite: () => context
                              .read<VaultBloc>()
                              .add(VaultFavoriteToggled(item.id,
                                  isFavorite: !item.isFavorite)),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go(AppConstants.routeAddItem),
            backgroundColor: AppConstants.primaryCyan,
            foregroundColor: AppConstants.backgroundDark,
            icon: const Icon(Icons.add),
            label: const Text('ط¥ط¶ط§ظپط©',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Color _scoreColor(int score) => score >= 80
      ? AppConstants.successGreen
      : score >= 50
          ? AppConstants.warningAmber
          : AppConstants.errorRed;
}

// â”€â”€â”€ Vault Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VaultCard extends StatelessWidget {
  final VaultEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  const _VaultCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.onFavorite,
  });

  Color get _strengthColor {
    if (entry.strengthScore < 0) return Colors.white24;
    final pct = entry.strengthScore / 4;
    if (pct >= 0.75) return AppConstants.successGreen;
    if (pct >= 0.5) return AppConstants.warningAmber;
    return AppConstants.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppConstants.errorRed.withAlpha(51),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppConstants.errorRed, size: 28),
      ),
      confirmDismiss: (_) async => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppConstants.surfaceDark,
          title: const Text('ط­ط°ظپطں',
              style: TextStyle(color: Colors.white)),
          content: Text('ظ‡ظ„ طھط±ظٹط¯ ط­ط°ظپ "${entry.title}"طں',
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ط¥ظ„ط؛ط§ط،')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ط­ط°ظپ',
                    style:
                        TextStyle(color: AppConstants.errorRed))),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppConstants.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppConstants.borderDark, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppConstants.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(entry.category.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(entry.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              )),
                        ),
                        GestureDetector(
                          onTap: onFavorite,
                          child: Icon(
                            entry.isFavorite
                                ? Icons.star
                                : Icons.star_outline,
                            color: entry.isFavorite
                                ? AppConstants.accentGold
                                : Colors.white24,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    if (entry.username != null) ...[
                      const SizedBox(height: 2),
                      Text(entry.username!,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: entry.strengthScore >= 0
                                ? entry.strengthScore / 4.0
                                : 0,
                            backgroundColor: AppConstants.borderDark,
                            color: _strengthColor,
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        if (entry.strengthScore >= 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${(entry.strengthScore / 4 * 100).round()}%',
                            style: TextStyle(
                              color: _strengthColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Empty placeholder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyPlaceholder extends StatelessWidget {
  final bool hasFilter;
  final int totalCount;
  const _EmptyPlaceholder(
      {required this.hasFilter, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasFilter ? 'ًں”چ' : 'ًں”’',
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'ظ„ط§ طھظˆط¬ط¯ ظ†طھط§ط¦ط¬' : 'ط®ط²ظ†طھظƒ ظپط§ط±ط؛ط©',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'ط¬ط±ظ‘ط¨ ط¨ط­ط«ط§ظ‹ ظ…ط®طھظ„ظپط§ظ‹ ط£ظˆ ط؛ظٹظ‘ط± ط§ظ„ظپط¦ط©'
                  : 'ط§ط¶ط؛ط· + ظ„ط¥ط¶ط§ظپط© ط£ظˆظ„ ظƒظ„ظ…ط© ظ…ط±ظˆط±',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

