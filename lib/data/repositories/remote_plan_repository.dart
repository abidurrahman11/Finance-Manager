import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/plan_model.dart';

class RemotePlanRepository {
  final Dio _dio;

  RemotePlanRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await _dio.get('/plans');
      final data = response.data as List;
      return data
          .map((json) => PlanModel.fromJson({
                ...Map<String, dynamic>.from(json as Map),
                'is_remote': true,
              }))
          .toList();
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch shared plans');
    }
  }

  Future<PlanWithItems> getPlan(int id) async {
    try {
      final response = await _dio.get('/plans/$id');
      final data = Map<String, dynamic>.from(response.data as Map);
      final planJson = Map<String, dynamic>.from(data['plan'] as Map);
      final itemsJson = data['items'] as List? ?? const [];
      return PlanWithItems(
        plan: PlanModel.fromJson({...planJson, 'is_remote': true}),
        items: itemsJson
            .map((json) =>
                PlanItemModel.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList(),
      );
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch shared plan');
    }
  }

  Future<PlanModel> createPlan({
    required String title,
    String? description,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.post('/plans', data: {
        'title': title,
        'description': description,
        'target_amount': targetAmount,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
      return PlanModel.fromJson({
        ...Map<String, dynamic>.from(response.data as Map),
        'role': 'owner',
        'is_remote': true,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to create shared plan');
    }
  }

  Future<void> deletePlan(int id) async {
    try {
      await _dio.delete('/plans/$id');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to delete shared plan');
    }
  }

  Future<PlanItemModel> addItem(
    int planId, {
    required String category,
    required double expectedAmount,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/plans/$planId/items', data: {
        'category': category,
        'expected_amount': expectedAmount,
        'notes': notes,
      });
      return PlanItemModel.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to add shared plan item');
    }
  }

  Future<PlanItemModel> updateItem(
    int planId,
    int itemId, {
    required String category,
    required double expectedAmount,
    String? notes,
  }) async {
    try {
      final response = await _dio.put('/plans/$planId/items/$itemId', data: {
        'category': category,
        'expected_amount': expectedAmount,
        'notes': notes,
      });
      return PlanItemModel.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to update shared plan item');
    }
  }

  Future<void> deleteItem(int planId, int itemId) async {
    try {
      await _dio.delete('/plans/$planId/items/$itemId');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to delete shared plan item');
    }
  }

  Future<PlanItemModel> updateSpent(
    int planId,
    int itemId, {
    required double amount,
    required String operation,
  }) async {
    try {
      final response =
          await _dio.post('/plans/$planId/items/$itemId/spent', data: {
        'amount': amount,
        'operation': operation,
      });
      return PlanItemModel.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to update shared plan spending');
    }
  }

  Future<void> addCollaborator(int planId, String email, String role) async {
    try {
      await _dio.post('/plans/$planId/collaborators', data: {
        'user_email': email,
        'role': role,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to add collaborator');
    }
  }

  Future<List<CollaboratorModel>> getCollaborators(int planId) async {
    try {
      final response = await _dio.get('/plans/$planId/collaborators');
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

  Future<void> removeCollaborator(int planId, int userId) async {
    try {
      await _dio.delete('/plans/$planId/collaborators/$userId');
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to remove collaborator');
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
      message = 'Online connection is unavailable. Local data is still usable.';
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
