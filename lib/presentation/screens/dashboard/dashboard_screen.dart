import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final cashFlow = ref.watch(cashFlowProvider);
    final expenses = ref.watch(expensesProvider);
    final categories = ref.watch(categoryAnalyticsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cashFlowProvider);
            ref.invalidate(categoryAnalyticsProvider);
            ref.read(expensesProvider.notifier).loadInitial();
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary),
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(DateTime.now()),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.2),
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cash Flow Banner
              SliverToBoxAdapter(
                child: cashFlow.when(
                  data: (cf) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: cf.isPositive
                              ? [
                                  const Color(0xFF1E3A1E),
                                  const Color(0xFF1B4332)
                                ]
                              : [
                                  const Color(0xFF3A1E1E),
                                  const Color(0xFF4A1515)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(
                              cf.isPositive
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: cf.isPositive
                                  ? AppTheme.income
                                  : AppTheme.expense,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Monthly Cash Flow',
                              style: TextStyle(
                                  color: cf.isPositive
                                      ? AppTheme.income.withOpacity(0.8)
                                      : AppTheme.expense.withOpacity(0.8),
                                  fontSize: 13),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(cf.cashFlow),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: cf.isPositive
                                  ? AppTheme.income
                                  : AppTheme.expense,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _FlowItem(
                                  label: 'Income',
                                  value: cf.totalIncome,
                                  color: AppTheme.income),
                              const SizedBox(width: 16),
                              _FlowItem(
                                  label: 'Expenses',
                                  value: cf.totalExpenses,
                                  color: AppTheme.expense),
                              const SizedBox(width: 16),
                              _FlowItem(
                                  label: 'Bills',
                                  value: cf.totalPaidBills,
                                  color: AppTheme.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ShimmerLoader(height: 140),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle_outline,
                            label: 'Add\nExpense',
                            color: AppTheme.expense,
                            onTap: () => context.push('/expenses/new'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.savings_outlined,
                            label: 'Add\nIncome',
                            color: AppTheme.income,
                            onTap: () => context.push('/incomes/new'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.receipt_long_outlined,
                            label: 'View\nBills',
                            color: AppTheme.warning,
                            onTap: () => context.go('/bills'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.flag_outlined,
                            label: 'New\nPlan',
                            color: AppTheme.primary,
                            onTap: () => context.go('/plans'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Spending by category
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: 'Top Categories (This Month)',
                    actionLabel: 'Analytics',
                    onAction: () => context.go('/analytics'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: categories.when(
                  data: (cats) => cats.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('No expenses this month',
                                style: TextStyle(color: AppTheme.textSecondary),
                                textAlign: TextAlign.center),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: cats.take(5).toList().asMap().entries.map((e) {
                              final idx = e.key;
                              final cat = e.value;
                              final total = cats.fold(
                                  0.0, (s, c) => s + c.totalSpent);
                              final percent = total > 0
                                  ? cat.totalSpent / total
                                  : 0.0;
                              final color = AppTheme.categoryColors[
                                  idx % AppTheme.categoryColors.length];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CategoryRow(
                                    category: cat.category,
                                    amount: cat.totalSpent,
                                    percent: percent,
                                    color: color),
                              );
                            }).toList(),
                          ),
                        ),
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                        children: List.generate(
                            3,
                            (i) => const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: ShimmerLoader(height: 50)))),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Recent Expenses
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: 'Recent Expenses',
                    actionLabel: 'See all',
                    onAction: () => context.go('/expenses'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              expenses.isLoading && expenses.expenses.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                          children: List.generate(
                              3,
                              (i) => const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: ShimmerLoader(height: 60)))),
                    ))
                  : expenses.expenses.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16)),
                            child: const Text('No expenses yet',
                                style:
                                    TextStyle(color: AppTheme.textSecondary),
                                textAlign: TextAlign.center),
                          ),
                        ))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final exp =
                                  expenses.expenses.take(5).toList()[i];
                              final color = AppTheme.categoryColors[
                                  i % AppTheme.categoryColors.length];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.shopping_bag_outlined,
                                          color: color, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(exp.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary,
                                                  fontSize: 14)),
                                          Text(
                                              '${exp.category} • ${DateFormatter.formatDate(exp.expenseDate)}',
                                              style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(exp.amount),
                                      style: const TextStyle(
                                          color: AppTheme.expense,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ]),
                                ),
                              );
                            },
                            childCount:
                                expenses.expenses.take(5).length,
                          ),
                        ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _FlowItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
          Text(CurrencyFormatter.formatCompact(value),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;
  final Color color;
  const _CategoryRow(
      {required this.category,
      required this.amount,
      required this.percent,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.circle, color: color, size: 10),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(category,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
              Text(CurrencyFormatter.format(amount),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
