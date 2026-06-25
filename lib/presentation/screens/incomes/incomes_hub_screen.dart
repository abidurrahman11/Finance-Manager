import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/incomes/income_list_tile.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Root incomes screen at /incomes.
///
/// Layout (top → bottom):
///   1. Two compact group-button cards — Offline Groups / Online Groups.
///   2. Category filter chips for personal (ungrouped, offline) incomes.
///   3. Full personal income list — local only, no group.
///   4. FAB — Add Income (no group context).
///
/// This directly mirrors [ExpensesHubScreen] — same layout, same patterns,
/// same offline/online split. Users coming from the expense screen immediately
/// understand the income screen.
class IncomesHubScreen extends ConsumerStatefulWidget {
  const IncomesHubScreen({super.key});

  @override
  ConsumerState<IncomesHubScreen> createState() => _IncomesHubScreenState();
}

class _IncomesHubScreenState extends ConsumerState<IncomesHubScreen> {
  String? _selectedCategory;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(personalIncomesProvider.notifier).loadMore();
    }
  }

  void _selectCategory(String? category) {
    setState(() => _selectedCategory = category);
    ref
        .read(personalIncomesProvider.notifier)
        .loadInitial(category: category);
  }

  Future<void> _onRefresh() async {
    await ref
        .read(personalIncomesProvider.notifier)
        .loadInitial(category: _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalIncomesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/incomes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
        backgroundColor: AppTheme.income,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Group button cards ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _GroupButtonCard(
                    icon: Icons.folder_outlined,
                    label: 'Offline Groups',
                    color: AppTheme.secondary,
                    onTap: () =>
                        context.push('/incomes/groups/offline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GroupButtonCard(
                    icon: Icons.cloud_outlined,
                    label: 'Online Groups',
                    color: AppTheme.primary,
                    onTap: () =>
                        context.push('/incomes/groups/online'),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Category filter chips ──────────────────────────────
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => _selectCategory(null),
                ),
                ...AppConstants.incomeCategories.map(
                  (cat) => _FilterChip(
                    label: cat,
                    selected: _selectedCategory == cat,
                    onTap: () => _selectCategory(cat),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── 3. Personal income list ───────────────────────────────
          Expanded(
            child: state.isLoading && state.incomes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.incomes.isEmpty
                    ? EmptyState(
                        icon: Icons.savings_outlined,
                        title: 'No income recorded yet',
                        subtitle:
                            'Tap the button below to record your first income.',
                        actionLabel: 'Add Income',
                        onAction: () => context.push('/incomes/new'),
                      )
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: state.incomes.length +
                              (state.hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == state.incomes.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            final inc = state.incomes[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: IncomeListTile(
                                income: inc,
                                colorIndex: i,
                                onEdit: () => context.push(
                                    '/incomes/edit',
                                    extra: inc),
                                onDelete: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Delete Income',
                                    message:
                                        'Delete "${inc.title}"? This cannot be undone.',
                                  );
                                  if (ok) {
                                    ref
                                        .read(personalIncomesProvider
                                            .notifier)
                                        .delete(inc.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Compact group button card ────────────────────────────────────────────────

class _GroupButtonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GroupButtonCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category filter chip ─────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color:
                selected ? AppTheme.income : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
