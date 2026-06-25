import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/expenses/expense_list_tile.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Root expenses screen at /expenses.
///
/// Layout (top → bottom):
///   1. Two compact group-button cards — Offline Groups / Online Groups.
///   2. Category filter chips for personal (ungrouped, offline) expenses.
///   3. Full personal expense list — same logic as the former PersonalExpensesScreen.
///   4. FAB — Add Expense (no group context).
///
/// No monthly total. No recent strip. No separate personal screen needed.
/// All providers and logic are unchanged — this is a pure UI rearrangement.
class ExpensesHubScreen extends ConsumerStatefulWidget {
  const ExpensesHubScreen({super.key});

  @override
  ConsumerState<ExpensesHubScreen> createState() => _ExpensesHubScreenState();
}

class _ExpensesHubScreenState extends ConsumerState<ExpensesHubScreen> {
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
      ref.read(personalExpensesProvider.notifier).loadMore();
    }
  }

  void _selectCategory(String? category) {
    setState(() => _selectedCategory = category);
    ref
        .read(personalExpensesProvider.notifier)
        .loadInitial(category: category);
  }

  Future<void> _onRefresh() async {
    await ref
        .read(personalExpensesProvider.notifier)
        .loadInitial(category: _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.expense,
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
                        context.push('/expenses/groups/offline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GroupButtonCard(
                    icon: Icons.cloud_outlined,
                    label: 'Online Groups',
                    color: AppTheme.primary,
                    onTap: () =>
                        context.push('/expenses/groups/online'),
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
                ...AppConstants.expenseCategories.map(
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

          // ── 3. Personal expense list ──────────────────────────────
          Expanded(
            child: state.isLoading && state.expenses.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.expenses.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No expenses yet',
                        subtitle:
                            'Tap the button below to record your first expense.',
                        actionLabel: 'Add Expense',
                        onAction: () => context.push('/expenses/new'),
                      )
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: state.expenses.length +
                              (state.hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == state.expenses.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            final exp = state.expenses[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ExpenseListTile(
                                expense: exp,
                                colorIndex: i,
                                onEdit: () => context.push(
                                    '/expenses/edit',
                                    extra: exp),
                                onDelete: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Delete Expense',
                                    message:
                                        'Delete "${exp.title}"? This cannot be undone.',
                                  );
                                  if (ok) {
                                    ref
                                        .read(personalExpensesProvider
                                            .notifier)
                                        .delete(exp.id);
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
              Icon(Icons.chevron_right,
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
                selected ? AppTheme.expense : AppTheme.surfaceVariant,
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
