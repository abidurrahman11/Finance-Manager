import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/analytics_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Cash Flow'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _CashFlowTab(),
          _CategoryTab(),
          _TrendsTab(),
        ],
      ),
    );
  }
}

// ─── Cash Flow Tab ────────────────────────────────────────────────────────────
class _CashFlowTab extends ConsumerWidget {
  const _CashFlowTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(cashFlowProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(cashFlowProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: cashFlowAsync.when(
          data: (cf) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(cf.cashFlow),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color:
                        cf.isPositive ? AppTheme.income : AppTheme.expense,
                  ),
                ),
                Row(children: [
                  Icon(
                    cf.isPositive
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color:
                        cf.isPositive ? AppTheme.income : AppTheme.expense,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cf.isPositive
                        ? 'Positive cash flow this month'
                        : 'Negative cash flow this month',
                    style: TextStyle(
                        color: cf.isPositive
                            ? AppTheme.income
                            : AppTheme.expense,
                        fontSize: 13),
                  ),
                ]),
                const SizedBox(height: 28),

                // Breakdown bar chart
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Breakdown',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: [
                                    cf.totalIncome,
                                    cf.totalExpenses,
                                    cf.totalPaidBills
                                  ].reduce((a, b) => a > b ? a : b) *
                                  1.3,
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final labels = [
                                      'Income',
                                      'Expenses',
                                      'Bills'
                                    ];
                                    return BarTooltipItem(
                                      '${labels[groupIndex]}\n${CurrencyFormatter.format(rod.toY)}',
                                      const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final labels = [
                                        'Income',
                                        'Expenses',
                                        'Bills'
                                      ];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          labels[v.toInt()],
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (v) => FlLine(
                                  color: AppTheme.divider,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                _bar(0, cf.totalIncome, AppTheme.income),
                                _bar(1, cf.totalExpenses, AppTheme.expense),
                                _bar(
                                    2, cf.totalPaidBills, AppTheme.warning),
                              ],
                            ),
                          ),
                        ),
                      ]),
                ),

                const SizedBox(height: 16),

                // Summary cards
                Row(children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Total Income',
                      value: CurrencyFormatter.format(cf.totalIncome),
                      icon: Icons.arrow_downward,
                      color: AppTheme.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Total Expenses',
                      value: CurrencyFormatter.format(cf.totalExpenses),
                      icon: Icons.arrow_upward,
                      color: AppTheme.expense,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Bills Paid',
                      value: CurrencyFormatter.format(cf.totalPaidBills),
                      icon: Icons.receipt_long,
                      color: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Net Cash Flow',
                      value: CurrencyFormatter.format(cf.cashFlow),
                      icon: cf.isPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: cf.isPositive ? AppTheme.income : AppTheme.expense,
                    ),
                  ),
                ]),
              ]),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text(e.toString(),
                  style: const TextStyle(color: AppTheme.error))),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: y * 1.3,
            color: color.withOpacity(0.05),
          ),
        )
      ],
    );
  }
}

// ─── Category Tab ─────────────────────────────────────────────────────────────
class _CategoryTab extends ConsumerWidget {
  const _CategoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catAsync = ref.watch(categoryAnalyticsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(categoryAnalyticsProvider),
      child: catAsync.when(
        data: (cats) {
          if (cats.isEmpty) {
            return const EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No data yet',
              subtitle: 'Add expenses to see category breakdown',
            );
          }
          final total = cats.fold(0.0, (s, c) => s + c.totalSpent);
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Pie chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('Spending by Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 55,
                        sections: cats.asMap().entries.map((e) {
                          final i = e.key;
                          final cat = e.value;
                          final color = AppTheme.categoryColors[
                              i % AppTheme.categoryColors.length];
                          return PieChartSectionData(
                            value: cat.totalSpent,
                            color: color,
                            radius: 60,
                            title: total > 0
                                ? '${(cat.totalSpent / total * 100).toStringAsFixed(0)}%'
                                : '',
                            titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: cats.asMap().entries.take(8).map((e) {
                      final color = AppTheme.categoryColors[
                          e.key % AppTheme.categoryColors.length];
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(e.value.category,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                      ]);
                    }).toList(),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Category list
              ...cats.asMap().entries.map((e) {
                final i = e.key;
                final cat = e.value;
                final color = AppTheme
                    .categoryColors[i % AppTheme.categoryColors.length];
                final pct = total > 0 ? cat.totalSpent / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child:
                            Icon(Icons.circle, color: color, size: 10),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(cat.category,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary)),
                                    Text(
                                        CurrencyFormatter.format(
                                            cat.totalSpent),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary)),
                                  ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: color.withOpacity(0.1),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${cat.expenseCount} transactions • ${(pct * 100).toStringAsFixed(1)}% of total',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11),
                              ),
                            ]),
                      ),
                    ]),
                  ),
                );
              }),
            ]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

// ─── Trends Tab ───────────────────────────────────────────────────────────────
class _TrendsTab extends ConsumerWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(monthlyTrendsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(monthlyTrendsProvider),
      child: trendsAsync.when(
        data: (trends) {
          if (trends.isEmpty) {
            return const EmptyState(
              icon: Icons.show_chart,
              title: 'No trend data',
              subtitle: 'Add expenses over multiple months to see trends',
            );
          }

          // Sort ascending for chart
          final sorted = [...trends]
            ..sort((a, b) => a.month.compareTo(b.month));
          final maxY = sorted.isEmpty
              ? 100.0
              : sorted
                      .map((t) => t.totalSpent)
                      .reduce((a, b) => a > b ? a : b) *
                  1.3;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Line chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('12-Month Spending Trend',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: AppTheme.divider,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: sorted.length > 6
                                      ? (sorted.length / 6).ceilToDouble()
                                      : 1,
                                  getTitlesWidget: (value, _) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= sorted.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        DateFormat('MMM')
                                            .format(sorted[idx].month),
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: sorted
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.totalSpent))
                                    .toList(),
                                isCurved: true,
                                color: AppTheme.primary,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, pct, bar, idx) =>
                                      FlDotCirclePainter(
                                    radius: 4,
                                    color: AppTheme.primary,
                                    strokeWidth: 2,
                                    strokeColor: AppTheme.background,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppTheme.primary.withOpacity(0.3),
                                      AppTheme.primary.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (spots) => spots
                                    .map((s) => LineTooltipItem(
                                          '${DateFormat('MMM yy').format(sorted[s.spotIndex].month)}\n${CurrencyFormatter.format(s.y)}',
                                          const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
              ),

              const SizedBox(height: 16),

              // Month-by-month list (descending)
              ...trends.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('MMM').format(t.month),
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                              Text(
                                DateFormat('yy').format(t.month),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.expenseCount} transactions',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: maxY > 0
                                        ? (t.totalSpent / maxY * 1.3)
                                            .clamp(0.0, 1.0)
                                        : 0,
                                    backgroundColor:
                                        AppTheme.primary.withOpacity(0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppTheme.primary),
                                    minHeight: 4,
                                  ),
                                ),
                              ]),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter.format(t.totalSpent),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontSize: 14),
                        ),
                      ]),
                    ),
                  )),
            ]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
