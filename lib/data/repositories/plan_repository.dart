import 'package:dio/dio.dart';
import '../models/plan_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class PlanRepository {
  final _dio = ApiClient().dio;

  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await _dio.get('/plans');
      return (response.data as List).map((e) => PlanModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load plans');
    }
  }

  Future<PlanWithItems> getPlan(int id) async {
    try {
      final response = await _dio.get('/plans/$id');
      final plan = PlanModel.fromJson(response.data['plan']);
      final items = (response.data['items'] as List)
          .map((e) => PlanItemModel.fromJson(e))
          .toList();
      return PlanWithItems(plan: plan, items: items);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load plan');
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
        if (description != null) 'description': description,
        if (targetAmount != null) 'target_amount': targetAmount,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
      return PlanModel.fromJson({...response.data, 'role': 'owner'});
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to create plan');
    }
  }

  Future<void> updatePlan(
    int id, {
    required String title,
    String? description,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _dio.put('/plans/$id', data: {
        'title': title,
        'description': description,
        'target_amount': targetAmount,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to update plan');
    }
  }

  Future<void> deletePlan(int id) async {
    try {
      await _dio.delete('/plans/$id');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to delete plan');
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
        if (notes != null) 'notes': notes,
      });
      return PlanItemModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to add item');
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
      return PlanItemModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to update item');
    }
  }

  Future<void> deleteItem(int planId, int itemId) async {
    try {
      await _dio.delete('/plans/$planId/items/$itemId');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to delete item');
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
      return PlanItemModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to update spent');
    }
  }

  Future<void> addCollaborator(int planId, String email, String role) async {
    try {
      await _dio.post('/plans/$planId/collaborators',
          data: {'user_email': email, 'role': role});
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to add collaborator');
    }
  }

  Future<List<CollaboratorModel>> getCollaborators(int planId) async {
    try {
      final response = await _dio.get('/plans/$planId/collaborators');
      return (response.data['collaborators'] as List)
          .map((e) => CollaboratorModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to load collaborators');
    }
  }

  Future<void> removeCollaborator(int planId, int userId) async {
    try {
      await _dio.delete('/plans/$planId/collaborators/$userId');
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? 'Failed to remove collaborator');
    }
  }
}
