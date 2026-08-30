import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/analytics_model.dart';

class AnalyticsRepository {
  final AppDatabase _db;

  AnalyticsRepository({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  Future<AnalyticsSummary> getSummary({
    String? startDate,
    String? endDate,
    int? expenseGroupId,
  }) async {
    final filter = _expenseFilter(startDate, endDate, expenseGroupId);
    final rows = await _db.customSelect(
      '''
          SELECT
            COUNT(*) AS expense_count,
            COALESCE(SUM(amount), 0) AS total_spent,
            COALESCE(AVG(amount), 0) AS average_amount
          FROM expenses
          ${filter.where}
          ''',
      variables: filter.variables,
    ).get();
    final row = rows.first.data;
    return AnalyticsSummary(
      expenseCount: row['expense_count'] as int,
      totalSpent: (row['total_spent'] as num).toDouble(),
      averageAmount: (row['average_amount'] as num).toDouble(),
    );
  }

  Future<List<CategoryAnalytics>> getByCategory({
    String? startDate,
    String? endDate,
    int? expenseGroupId,
  }) async {
    final filter = _expenseFilter(startDate, endDate, expenseGroupId);
    final rows = await _db.customSelect(
      '''
          SELECT category, COUNT(*) AS expense_count, COALESCE(SUM(amount), 0) AS total_spent
          FROM expenses
          ${filter.where}
          GROUP BY category
          ORDER BY total_spent DESC
          ''',
      variables: filter.variables,
    ).get();
    return rows
        .map(
          (row) => CategoryAnalytics(
            category: row.data['category'] as String,
            expenseCount: row.data['expense_count'] as int,
            totalSpent: (row.data['total_spent'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<List<MonthlyTrend>> getMonthlyTrends({
    String? startDate,
    String? endDate,
  }) async {
    final filter = _expenseFilter(startDate, endDate, null);
    final rows = await _db.customSelect(
      '''
          SELECT
            strftime('%Y-%m-01', expense_date) AS month,
            COUNT(*) AS expense_count,
            COALESCE(SUM(amount), 0) AS total_spent
          FROM expenses
          ${filter.where}
          GROUP BY month
          ORDER BY month ASC
          ''',
      variables: filter.variables,
    ).get();
    return rows
        .map(
          (row) => MonthlyTrend(
            month: DateTime.parse(row.data['month'] as String),
            expenseCount: row.data['expense_count'] as int,
            totalSpent: (row.data['total_spent'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<CashFlow> getCashFlow({String? startDate, String? endDate}) async {
    final expenses = await _sum(
      table: 'expenses',
      amountColumn: 'amount',
      dateColumn: 'expense_date',
      startDate: startDate,
      endDate: endDate,
    );
    final incomes = await _sum(
      table: 'incomes',
      amountColumn: 'amount',
      dateColumn: 'income_date',
      startDate: startDate,
      endDate: endDate,
    );
    final paidBills =
        await _sumPaidBills(startDate: startDate, endDate: endDate);
    final cashFlow = incomes - expenses - paidBills;
    return CashFlow(
      totalIncome: incomes,
      totalExpenses: expenses,
      totalPaidBills: paidBills,
      cashFlow: cashFlow,
    );
  }

  Future<double> _sum({
    required String table,
    required String amountColumn,
    required String dateColumn,
    String? startDate,
    String? endDate,
  }) async {
    final clauses = <String>[];
    final variables = <Variable>[];
    if (startDate != null) {
      clauses.add('date($dateColumn) >= date(?)');
      variables.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      clauses.add('date($dateColumn) <= date(?)');
      variables.add(Variable.withString(endDate));
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _db
        .customSelect(
          'SELECT COALESCE(SUM($amountColumn), 0) AS total FROM $table $where',
          variables: variables,
        )
        .get();
    return (rows.first.data['total'] as num).toDouble();
  }

  Future<double> _sumPaidBills({String? startDate, String? endDate}) async {
    final clauses = <String>["status = 'paid'"];
    final variables = <Variable>[];
    if (startDate != null) {
      clauses.add("date(month || '-01') >= date(?)");
      variables.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      clauses.add("date(month || '-01') <= date(?)");
      variables.add(Variable.withString(endDate));
    }
    final rows = await _db.customSelect(
      '''
          SELECT COALESCE(SUM(COALESCE(p.paid_amount, b.amount)), 0) AS total
          FROM bill_payments p
          INNER JOIN bills b ON b.id = p.bill_id
          WHERE ${clauses.join(' AND ')}
          ''',
      variables: variables,
    ).get();
    return (rows.first.data['total'] as num).toDouble();
  }

  _SqlFilter _expenseFilter(
    String? startDate,
    String? endDate,
    int? expenseGroupId,
  ) {
    final clauses = <String>[];
    final variables = <Variable>[];
    if (startDate != null) {
      clauses.add('date(expense_date) >= date(?)');
      variables.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      clauses.add('date(expense_date) <= date(?)');
      variables.add(Variable.withString(endDate));
    }
    if (expenseGroupId != null) {
      clauses.add('expense_group_id = ?');
      variables.add(Variable.withInt(expenseGroupId));
    }
    return _SqlFilter(
      where: clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}',
      variables: variables,
    );
  }
}

class _SqlFilter {
  final String where;
  final List<Variable> variables;

  const _SqlFilter({required this.where, required this.variables});
}
