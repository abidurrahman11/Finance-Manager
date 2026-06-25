import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/analytics_model.dart';

class RemoteAnalyticsRepository {
  final Dio _dio;

  RemoteAnalyticsRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<AnalyticsSummary> getSummary({
    String? startDate,
    String? endDate,
    int? expenseGroupId,
  }) async {
    try {
      final response = await _dio.get('/analytics/summary', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId,
      });
      final data = response.data;
      return AnalyticsSummary(
        expenseCount: data['expense_count'] as int,
        totalSpent: (data['total_spent'] as num).toDouble(),
        averageAmount: (data['average_amount'] as num).toDouble(),
      );
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch remote summary');
    }
  }

  Future<List<CategoryAnalytics>> getByCategory({
    String? startDate,
    String? endDate,
    int? expenseGroupId,
  }) async {
    try {
      final response = await _dio.get('/analytics/by-category', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId,
      });
      final data = response.data as List;
      return data
          .map((json) => CategoryAnalytics(
                category: json['category'] as String,
                expenseCount: json['expense_count'] as int,
                totalSpent: (json['total_spent'] as num).toDouble(),
              ))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch remote category analytics');
    }
  }

  Future<List<MonthlyTrend>> getMonthlyTrends({
    String? startDate,
    String? endDate,
    int? expenseGroupId,
  }) async {
    try {
      final response = await _dio.get('/analytics/monthly-trends', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId,
      });
      final data = response.data as List;
      return data
          .map((json) => MonthlyTrend(
                month: DateTime.parse(json['month'] as String),
                expenseCount: json['expense_count'] as int,
                totalSpent: (json['total_spent'] as num).toDouble(),
              ))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch remote monthly trends');
    }
  }

  Future<CashFlow> getCashFlow({String? startDate, String? endDate}) async {
    try {
      final response = await _dio.get('/analytics/cash-flow', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      final data = response.data;
      return CashFlow(
        totalIncome: (data['total_income'] as num).toDouble(),
        totalExpenses: (data['total_expenses'] as num).toDouble(),
        totalPaidBills: (data['total_paid_bills'] as num).toDouble(),
        cashFlow: (data['cash_flow'] as num).toDouble(),
      );
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch remote cash flow');
    }
  }

  ApiException _apiException(DioException e, String fallback) {
    final data = e.response?.data;
    String message = fallback;
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
