import 'package:dio/dio.dart';
import '../models/bill_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class BillRepository {
  final _dio = ApiClient().dio;

  Future<List<BillModel>> getBills() async {
    try {
      final response = await _dio.get('/bills');
      return (response.data as List).map((e) => BillModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load bills');
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
      return BillModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to create bill');
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
        'notes': notes,
      });
      return BillModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to update bill');
    }
  }

  Future<void> deleteBill(int id) async {
    try {
      await _dio.delete('/bills/$id');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to delete bill');
    }
  }

  Future<List<BillPaymentStatus>> getPaymentsForMonth(String month) async {
    try {
      final response =
          await _dio.get('/bills/payments', queryParameters: {'month': month});
      return (response.data as List)
          .map((e) => BillPaymentStatus.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load payments');
    }
  }

  Future<void> markPayment(
    int billId, {
    required String month,
    required String status,
    double? paidAmount,
    String? notes,
  }) async {
    try {
      await _dio.post('/bills/$billId/payments', data: {
        'month': month,
        'status': status,
        if (paidAmount != null) 'paid_amount': paidAmount,
        if (notes != null) 'notes': notes,
      });
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to update payment');
    }
  }

  Future<void> resetMonthlyPayments() async {
    try {
      await _dio.post('/bills/reset');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to reset payments');
    }
  }
}
