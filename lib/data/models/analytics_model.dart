class AnalyticsSummary {
  final int expenseCount;
  final double totalSpent;
  final double averageAmount;

  AnalyticsSummary({
    required this.expenseCount,
    required this.totalSpent,
    required this.averageAmount,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      expenseCount: json['expense_count'],
      totalSpent: double.parse(json['total_spent'].toString()),
      averageAmount: double.parse(json['average_amount'].toString()),
    );
  }
}

class CategoryAnalytics {
  final String category;
  final int expenseCount;
  final double totalSpent;

  CategoryAnalytics({
    required this.category,
    required this.expenseCount,
    required this.totalSpent,
  });

  factory CategoryAnalytics.fromJson(Map<String, dynamic> json) {
    return CategoryAnalytics(
      category: json['category'],
      expenseCount: json['expense_count'],
      totalSpent: double.parse(json['total_spent'].toString()),
    );
  }
}

class MonthlyTrend {
  final DateTime month;
  final int expenseCount;
  final double totalSpent;

  MonthlyTrend({
    required this.month,
    required this.expenseCount,
    required this.totalSpent,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: DateTime.parse(json['month']),
      expenseCount: json['expense_count'],
      totalSpent: double.parse(json['total_spent'].toString()),
    );
  }
}

class CashFlow {
  final double totalIncome;
  final double totalExpenses;
  final double totalPaidBills;
  final double cashFlow;

  CashFlow({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalPaidBills,
    required this.cashFlow,
  });

  factory CashFlow.fromJson(Map<String, dynamic> json) {
    return CashFlow(
      totalIncome: double.parse(json['total_income'].toString()),
      totalExpenses: double.parse(json['total_expenses'].toString()),
      totalPaidBills: double.parse(json['total_paid_bills'].toString()),
      cashFlow: double.parse(json['cash_flow'].toString()),
    );
  }

  bool get isPositive => cashFlow >= 0;
}
