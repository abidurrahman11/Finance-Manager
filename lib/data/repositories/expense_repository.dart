import 'package:dio/dio.dart';
import '../models/expense_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class ExpenseRepository {
  final _dio = ApiClient().dio;

  // --- Groups ---
  Future<List<ExpenseGroupModel>> getGroups() async {
    try {
      final response = await _dio.get('/expenses/groups');
      return (response.data as List)
          .map((e) => ExpenseGroupModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load groups');
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
        if (description != null) 'description': description,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
      return ExpenseGroupModel.fromJson({...response.data, 'role': 'owner'});
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to create group');
    }
  }

  Future<void> updateGroup(int id, {
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
      throw ApiException(e.response?.data['message'] ?? 'Failed to update group');
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _dio.delete('/expenses/groups/$id');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to delete group');
    }
  }

  Future<void> addCollaborator(int groupId, String email, String role) async {
    try {
      await _dio.post('/expenses/groups/$groupId/collaborators',
          data: {'user_email': email, 'role': role});
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to add collaborator');
    }
  }

  Future<List<Map<String, dynamic>>> getCollaborators(int groupId) async {
    try {
      final response = await _dio.get('/expenses/groups/$groupId/collaborators');
      return List<Map<String, dynamic>>.from(response.data['collaborators']);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load collaborators');
    }
  }

  Future<void> removeCollaborator(int groupId, int userId) async {
    try {
      await _dio.delete('/expenses/groups/$groupId/collaborators/$userId');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to remove collaborator');
    }
  }

  // --- Expenses ---
  Future<PaginatedExpenses> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int? expenseGroupId,
    int page = 1,
    int limit = 20,
    String sortBy = 'date',
    String order = 'desc',
  }) async {
    try {
      final response = await _dio.get('/expenses', queryParameters: {
        if (category != null) 'category': category,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId,
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'order': order,
      });
      return PaginatedExpenses.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load expenses');
    }
  }

  Future<ExpenseModel> createExpense({
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    int? expenseGroupId,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'amount': amount.toString(),
        'category': category,
        if (expenseDate != null) 'expense_date': expenseDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId.toString(),
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.post('/expenses', data: formData);
      return ExpenseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to create expense');
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
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'amount': amount.toString(),
        'category': category,
        if (expenseDate != null) 'expense_date': expenseDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (expenseGroupId != null) 'expense_group_id': expenseGroupId.toString(),
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.put('/expenses/$id', data: formData);
      return ExpenseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to update expense');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _dio.delete('/expenses/$id');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to delete expense');
    }
  }
}
