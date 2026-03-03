import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

/// Vault List — main vault screen showing all password entries
class VaultListScreen extends StatefulWidget {
  const VaultListScreen({super.key});
  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = '';
  String _selectedCategory = 'all';

  // TODO: Load from drift database
  static final _demoItems = [
    _VaultItem(id: '1', title: 'Google', username: 'user@gmail.com', category: 'social', icon: '🔵', strength: 95),
    _VaultItem(id: '2', title: 'GitHub', username: 'developer', category: 'work', icon: '⚙️', strength: 88),
    _VaultItem(id: '3', title: 'بنك الراجحي', username: '0501234567', category: 'finance', icon: '🏦', strength: 72),
    _VaultItem(id: '4', title: 'Netflix', username: 'user@email.com', category: 'entertainment', icon: '🎬', strength: 45),
    _VaultItem(id: '5', title: 'Amazon AWS', username: 'admin', category: 'work', icon: '☁️', strength: 90),
  ];

  static const _categories = [
    ('all', 'الكل', Icons.grid_view),
    ('social', 'التواصل', Icons.people),
    ('work', 'العمل', Icons.business),
    ('finance', 'المال', Icons.account_balance),
    ('entertainment', 'الترفيه', Icons.movie),
  ];

  List<_VaultItem> get _filtered => _demoItems
      .where((i) =>
          (_selectedCategory == 'all' || i.category == _selectedCategory) &&
          (i.title.toLowerCase().contains(_filter.toLowerCase()) ||
              i.username.toLowerCase().contains(_filter.toLowerCase())))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────
          SliverAppBar(
            backgroundColor: AppConstants.backgroundDark,
            floating: true,
            pinned: false,
            title: const Text(
              'خزنتي',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            actions: [
              // Security score badge
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.successGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.successGreen.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield, color: AppConstants.successGreen, size: 14),
                    SizedBox(width: 4),
                    Text('87', style: TextStyle(color: AppConstants.successGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: () {}, // TODO: sort options
              ),
            ],
          ),

          // ── Search + Filters ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  // Search bar
                  TextFormField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _filter = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن حساب...',
                      prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((c) {
                        final selected = _selectedCategory == c.$1;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(c.$2),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedCategory = c.$1),
                            avatar: Icon(c.$3, size: 14),
                            selectedColor: AppConstants.primaryCyan.withOpacity(0.2),
                            backgroundColor: AppConstants.surfaceDark,
                            labelStyle: TextStyle(
                              color: selected ? AppConstants.primaryCyan : Colors.white60,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppConstants.primaryCyan.withOpacity(0.5)
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

          // ── Items List ───────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _VaultCard(
                  item: _filtered[i],
                  onTap: () => context.go('/vault/${_filtered[i].id}'),
                ),
                childCount: _filtered.length,
              ),
            ),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppConstants.routeVaultAdd),
        backgroundColor: AppConstants.primaryCyan,
        foregroundColor: AppConstants.backgroundDark,
        icon: const Icon(Icons.add),
        label: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _VaultItem {
  final String id, title, username, category, icon;
  final int strength;
  const _VaultItem({
    required this.id,
    required this.title,
    required this.username,
    required this.category,
    required this.icon,
    required this.strength,
  });
}

class _VaultCard extends StatelessWidget {
  final _VaultItem item;
  final VoidCallback onTap;
  const _VaultCard({required this.item, required this.onTap});

  Color get _strengthColor => item.strength >= 80
      ? AppConstants.successGreen
      : item.strength >= 50
          ? AppConstants.warningAmber
          : AppConstants.errorRed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppConstants.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(item.username, style: const TextStyle(color: Colors.white54, fontSize: 12)),

                  const SizedBox(height: 6),
                  // Strength bar
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: item.strength / 100,
                          backgroundColor: AppConstants.borderDark,
                          color: _strengthColor,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.strength}%',
                        style: TextStyle(color: _strengthColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
