import 'package:dio/dio.dart';
import '../models/income_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class IncomeRepository {
  final _dio = ApiClient().dio;

  Future<List<IncomeGroupModel>> getGroups() async {
    try {
      final response = await _dio.get('/incomes/groups');
      return (response.data as List)
          .map((e) => IncomeGroupModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load groups');
    }
  }

  Future<IncomeGroupModel> createGroup({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.post('/incomes/groups', data: {
        'title': title,
        if (description != null) 'description': description,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
      return IncomeGroupModel.fromJson({...response.data, 'role': 'owner'});
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
      await _dio.put('/incomes/groups/$id', data: {
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
      await _dio.delete('/incomes/groups/$id');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to delete group');
    }
  }

  Future<void> addCollaborator(int groupId, String email, String role) async {
    try {
      await _dio.post('/incomes/groups/$groupId/collaborators',
          data: {'user_email': email, 'role': role});
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to add collaborator');
    }
  }

  Future<List<Map<String, dynamic>>> getCollaborators(int groupId) async {
    try {
      final response = await _dio.get('/incomes/groups/$groupId/collaborators');
      return List<Map<String, dynamic>>.from(response.data['collaborators']);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load collaborators');
    }
  }

  Future<void> removeCollaborator(int groupId, int userId) async {
    try {
      await _dio.delete('/incomes/groups/$groupId/collaborators/$userId');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to remove collaborator');
    }
  }

  Future<PaginatedIncomes> getIncomes({
    String? category,
    String? startDate,
    String? endDate,
    int? incomeGroupId,
    int page = 1,
    int limit = 20,
    String sortBy = 'date',
    String order = 'desc',
  }) async {
    try {
      final response = await _dio.get('/incomes', queryParameters: {
        if (category != null) 'category': category,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (incomeGroupId != null) 'income_group_id': incomeGroupId,
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'order': order,
      });
      return PaginatedIncomes.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load incomes');
    }
  }

  Future<IncomeModel> createIncome({
    required String title,
    required double amount,
    required String category,
    DateTime? incomeDate,
    String? notes,
    int? incomeGroupId,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'amount': amount.toString(),
        'category': category,
        if (incomeDate != null) 'income_date': incomeDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (incomeGroupId != null) 'income_group_id': incomeGroupId.toString(),
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.post('/incomes', data: formData);
      return IncomeModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to create income');
    }
  }

  Future<IncomeModel> updateIncome(
    int id, {
    required String title,
    required double amount,
    required String category,
    DateTime? incomeDate,
    String? notes,
    int? incomeGroupId,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'amount': amount.toString(),
        'category': category,
        if (incomeDate != null) 'income_date': incomeDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (incomeGroupId != null) 'income_group_id': incomeGroupId.toString(),
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.put('/incomes/$id', data: formData);
      return IncomeModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to update income');
    }
  }

  Future<void> deleteIncome(int id) async {
    try {
      await _dio.delete('/incomes/$id');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to delete income');
    }
  }
}
