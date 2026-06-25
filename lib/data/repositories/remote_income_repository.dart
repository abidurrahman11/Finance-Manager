import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/income_model.dart';
import '../models/plan_model.dart';

class RemoteIncomeRepository {
  final Dio _dio;

  RemoteIncomeRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<IncomeGroupModel>> getGroups() async {
    try {
      final response = await _dio.get('/incomes/groups');
      final data = response.data as List;
      return data
          .map((json) => IncomeGroupModel.fromJson({
                ...Map<String, dynamic>.from(json as Map),
                'is_remote': true,
              }))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch shared income groups');
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
        'description': description,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
      return IncomeGroupModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'role': 'owner',
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to create shared income group');
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
      await _dio.put('/incomes/groups/$id', data: {
        'title': title,
        'description': description,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to update shared income group');
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _dio.delete('/incomes/groups/$id');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to delete shared income group');
    }
  }

  Future<void> addCollaborator(int groupId, String email, String role) async {
    try {
      await _dio.post('/incomes/groups/$groupId/collaborators', data: {
        'user_email': email,
        'role': role,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to add collaborator');
    }
  }

  Future<List<CollaboratorModel>> getCollaborators(int groupId) async {
    try {
      final response = await _dio.get('/incomes/groups/$groupId/collaborators');
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
      await _dio.delete('/incomes/groups/$groupId/collaborators/$userId');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to remove collaborator');
    }
  }

  Future<PaginatedIncomes> getIncomes({
    String? category,
    int? incomeGroupId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/incomes', queryParameters: {
        if (category != null) 'category': category,
        if (incomeGroupId != null) 'income_group_id': incomeGroupId,
        'page': page,
      });
      return PaginatedIncomes.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch shared incomes');
    }
  }

  Future<IncomeModel> createIncome({
    required String title,
    required double amount,
    required String category,
    DateTime? incomeDate,
    String? notes,
    int? incomeGroupId,
  }) async {
    try {
      final response = await _dio.post('/incomes', data: {
        'title': title,
        'amount': amount,
        'category': category,
        'income_date': incomeDate?.toIso8601String(),
        'notes': notes,
        'income_group_id': incomeGroupId,
      });
      return IncomeModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to create shared income');
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
  }) async {
    try {
      final response = await _dio.put('/incomes/$id', data: {
        'title': title,
        'amount': amount,
        'category': category,
        'income_date': incomeDate?.toIso8601String(),
        'notes': notes,
        'income_group_id': incomeGroupId,
      });
      return IncomeModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to update shared income');
    }
  }

  Future<void> deleteIncome(int id) async {
    try {
      await _dio.delete('/incomes/$id');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to delete shared income');
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
