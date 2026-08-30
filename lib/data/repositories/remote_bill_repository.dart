import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/bill_model.dart';

class RemoteBillRepository {
  final Dio _dio;

  RemoteBillRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<BillModel>> getBills() async {
    try {
      final response = await _dio.get('/bills');
      final data = response.data as List;
      return data
          .map((json) => BillModel.fromJson({
                ...Map<String, dynamic>.from(json as Map),
                'is_remote': true,
              }))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch remote bills');
    }
  }

  Future<BillModel> createBill({
    required String title,
    required double amount,
    required int dueDay,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/bills', data: {
        'title': title,
        'amount': amount,
        'due_day': dueDay,
        if (notes != null) 'notes': notes,
      });
      return BillModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to create remote bill');
    }
  }

  Future<BillModel> updateBill(
    int id, {
    required String title,
    required double amount,
    required int dueDay,
    String? notes,
  }) async {
    try {
      final response = await _dio.put('/bills/$id', data: {
        'title': title,
        'amount': amount,
        'due_day': dueDay,
        if (notes != null) 'notes': notes,
      });
      return BillModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to update remote bill');
    }
  }

  Future<void> deleteBill(int id) async {
    try {
      await _dio.delete('/bills/$id');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to delete remote bill');
    }
  }

  Future<List<BillPaymentStatus>> getPaymentsForMonth(String month) async {
    try {
      final response =
          await _dio.get('/bills/payments', queryParameters: {'month': month});
      final data = response.data as List;
      return data
          .map((json) => BillPaymentStatus.fromJson({
                ...Map<String, dynamic>.from(json as Map),
                'is_remote': true,
              }))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch remote bill payments');
    }
  }

  Future<void> markAsPaid(int billId, String month, {double? amount, String? notes}) async {
    try {
      await _dio.post('/bills/$billId/payments', data: {
        'month': month,
        'status': 'paid',
        if (amount != null) 'paid_amount': amount,
        if (notes != null) 'notes': notes,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to mark bill as paid');
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
