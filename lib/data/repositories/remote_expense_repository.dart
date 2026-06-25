import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/expense_model.dart';
import '../models/plan_model.dart';

class RemoteExpenseRepository {
  final Dio _dio;

  RemoteExpenseRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<ExpenseGroupModel>> getGroups() async {
    try {
      final response = await _dio.get('/expenses/groups');
      final data = response.data as List;
      return data
          .map((json) => ExpenseGroupModel.fromJson({
                ...Map<String, dynamic>.from(json as Map),
                'is_remote': true,
              }))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch shared expense groups');
    }
  }

  Future<ExpenseGroupModel> createGroup({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.post('/expenses/groups', data: {
        'title': title,
        'description': description,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
      return ExpenseGroupModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'role': 'owner',
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to create shared expense group');
    }
  }

  Future<void> updateGroup(
    int id, {
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _dio.put('/expenses/groups/$id', data: {
        'title': title,
        'description': description,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to update shared expense group');
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _dio.delete('/expenses/groups/$id');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to delete shared expense group');
    }
  }

  Future<void> addCollaborator(int groupId, String email, String role) async {
    try {
      await _dio.post('/expenses/groups/$groupId/collaborators', data: {
        'user_email': email,
        'role': role,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to add collaborator');
    }
  }

  Future<List<CollaboratorModel>> getCollaborators(int groupId) async {
    try {
      final response = await _dio.get('/expenses/groups/$groupId/collaborators');
      final data = Map<String, dynamic>.from(response.data as Map);
      final collaborators = data['collaborators'] as List? ?? const [];
      return collaborators
          .map((json) => CollaboratorModel.fromJson(
              Map<String, dynamic>.from(json as Map)))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch collaborators');
    }
  }

  Future<void> removeCollaborator(int groupId, int userId) async {
    try {
      await _dio.delete('/expenses/groups/$groupId/collaborators/$userId');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to remove collaborator');
    }
  }

  Future<PaginatedExpenses> getExpenses({
    String? category,
    int? expenseGroupId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/expenses', queryParameters: {
        if (category != null) 'category': category,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId,
        'page': page,
      });
      return PaginatedExpenses.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch shared expenses');
    }
  }

  Future<ExpenseModel> createExpense({
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    int? expenseGroupId,
  }) async {
    try {
      final response = await _dio.post('/expenses', data: {
        'title': title,
        'amount': amount,
        'category': category,
        'expense_date': expenseDate?.toIso8601String(),
        'notes': notes,
        'expense_group_id': expenseGroupId,
      });
      return ExpenseModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to create shared expense');
    }
  }

  Future<ExpenseModel> updateExpense(
    int id, {
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    int? expenseGroupId,
  }) async {
    try {
      final response = await _dio.put('/expenses/$id', data: {
        'title': title,
        'amount': amount,
        'category': category,
        'expense_date': expenseDate?.toIso8601String(),
        'notes': notes,
        'expense_group_id': expenseGroupId,
      });
      return ExpenseModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to update shared expense');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _dio.delete('/expenses/$id');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to delete shared expense');
    }
  }

  ApiException _apiException(DioException e, String fallback) {
    final data = e.response?.data;
    String message = fallback;
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Online connection is unavailable.';
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
