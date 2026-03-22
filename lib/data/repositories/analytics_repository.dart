import 'package:dio/dio.dart';
import '../models/analytics_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class AnalyticsRepository {
  final _dio = ApiClient().dio;

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
      return AnalyticsSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load summary');
    }
  }

  Future<List<CategoryAnalytics>> getByCategory({
    String? startDate,
    String? endDate,
    int? expenseGroupId,
  }) async {
    try {
      final response =
          await _dio.get('/analytics/by-category', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId,
      });
      return (response.data as List)
          .map((e) => CategoryAnalytics.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load category data');
    }
  }

  Future<List<MonthlyTrend>> getMonthlyTrends({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response =
          await _dio.get('/analytics/monthly-trends', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      return (response.data as List)
          .map((e) => MonthlyTrend.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load trends');
    }
  }

  Future<CashFlow> getCashFlow({String? startDate, String? endDate}) async {
    try {
      final response =
          await _dio.get('/analytics/cash-flow', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      return CashFlow.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load cash flow');
    }
  }
}
