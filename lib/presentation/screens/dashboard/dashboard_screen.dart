import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/category_utils.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final cashFlow = ref.watch(cashFlowProvider);
    final categories = ref.watch(categoryAnalyticsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cashFlowProvider);
            ref.invalidate(categoryAnalyticsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.name.split(' ').first ?? 'there',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.2),
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Cash-flow hero card ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: cashFlow.when(
                    data: (cf) => _CashFlowCard(cf: cf),
                    loading: () => const ShimmerLoader(height: 148),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // ── Quick actions ─────────────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _QuickActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'Expense',
                        color: AppTheme.expense,
                        onTap: () => context.push('/expenses/new'),
                      ),
                      const SizedBox(width: 10),
                      _QuickActionButton(
                        icon: Icons.savings_outlined,
                        label: 'Income',
                        color: AppTheme.income,
                        onTap: () => context.push('/incomes/new'),
                      ),
                      const SizedBox(width: 10),
                      _QuickActionButton(
                        icon: Icons.notifications_none_outlined,
                        label: 'Reminders',
                        color: AppTheme.warning,
                        onTap: () => context.go('/bills'),
                      ),
                      const SizedBox(width: 10),
                      _QuickActionButton(
                        icon: Icons.flag_outlined,
                        label: 'Plans',
                        color: AppTheme.primary,
                        onTap: () => context.go('/plans'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── This month section header ─────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'This Month',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/analytics'),
                        icon: const Icon(Icons.bar_chart_outlined,
                            size: 15, color: AppTheme.primary),
                        label: const Text(
                          'Full Analytics',
                          style:
                              TextStyle(fontSize: 13, color: AppTheme.primary),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Income / Expense summary row ──────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: cashFlow.when(
                    data: (cf) => Row(children: [
                      Expanded(
                          child: _SummaryTile(
                        label: 'Income',
                        value: cf.totalIncome,
                        icon: Icons.arrow_downward_rounded,
                        color: AppTheme.income,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _SummaryTile(
                        label: 'Expenses',
                        value: cf.totalExpenses,
                        icon: Icons.arrow_upward_rounded,
                        color: AppTheme.expense,
                      )),
                    ]),
                    loading: () => Row(children: [
                      Expanded(child: ShimmerLoader(height: 76)),
                      const SizedBox(width: 12),
                      Expanded(child: ShimmerLoader(height: 76)),
                    ]),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // ── Top spending categories ───────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Top Spending',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                      TextButton(
                        onPressed: () => context.push('/analytics'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'See all',
                          style:
                              TextStyle(fontSize: 13, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: categories.when(
                    data: (cats) {
                      if (cats.isEmpty) {
                        return _EmptyCategories(
                            onAddExpense: () =>
                                context.push('/expenses/new'));
                      }
                      final total =
                          cats.fold(0.0, (s, c) => s + c.totalSpent);
                      // Show top 4 only — just enough to be useful without overwhelming
                      final topCats = cats.take(4).toList();
                      return _CategoryList(
                          cats: topCats, total: total);
                    },
                    loading: () => Column(
                      children: List.generate(
                          3,
                          (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: ShimmerLoader(height: 54),
                              )),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ─── Cash-flow hero card ──────────────────────────────────────────────────────

class _CashFlowCard extends StatelessWidget {
  final dynamic cf; // CashFlow model

  const _CashFlowCard({required this.cf});

  @override
  Widget build(BuildContext context) {
    final isPositive = cf.isPositive as bool;
    final flowColor = isPositive ? AppTheme.income : AppTheme.expense;
    final gradientColors = isPositive
        ? [const Color(0xFF1B3A2E), const Color(0xFF162E24)]
        : [const Color(0xFF3A1B1B), const Color(0xFF2E1616)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: flowColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: flowColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${DateFormat('MMMM yyyy').format(DateTime.now())} · Net Cash Flow',
              style: TextStyle(
                  color: flowColor.withValues(alpha: 0.8), fontSize: 12),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(cf.cashFlow as double),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: flowColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? 'You\'re saving more than you\'re spending.'
                : 'Your expenses exceed your income this month.',
            style: TextStyle(
                color: flowColor.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─── Summary tile (income / expense) ─────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.formatCompact(value),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Category list ────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  final List<dynamic> cats;
  final double total;

  const _CategoryList({required this.cats, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: cats.asMap().entries.map((e) {
          final idx = e.key;
          final cat = e.value;
          final color =
              AppTheme.categoryColors[idx % AppTheme.categoryColors.length];
          final pct = total > 0 ? (cat.totalSpent as double) / total : 0.0;
          final isLast = idx == cats.length - 1;
          final catIcon =
              CategoryUtils.getExpenseIcon(cat.category as String);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(catIcon, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.category as String,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                  cat.totalSpent as double),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor:
                                    color.withValues(alpha: 0.1),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ]),
              ),
              if (!isLast)
                const Divider(
                    height: 1, indent: 62, color: AppTheme.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Empty categories placeholder ────────────────────────────────────────────

class _EmptyCategories extends StatelessWidget {
  final VoidCallback onAddExpense;

  const _EmptyCategories({required this.onAddExpense});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.pie_chart_outline,
              size: 36, color: AppTheme.textSecondary),
          const SizedBox(height: 10),
          const Text(
            'No spending data yet',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add your first expense to see a breakdown here.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
            label: const Text('Add Expense',
                style: TextStyle(color: AppTheme.primary, fontSize: 13)),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick action button ──────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
