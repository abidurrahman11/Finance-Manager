import 'package:drift/drift.dart';

import '../../core/network/api_exception.dart';
import '../local/app_database.dart';
import '../models/plan_model.dart';

class PlanRepository {
  final AppDatabase _db;

  PlanRepository({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  Future<List<PlanModel>> getPlans() async {
    final rows = await _db
        .customSelect('SELECT * FROM plans ORDER BY created_at DESC')
        .get();
    return rows.map((row) => _planFromRow(row.data)).toList();
  }

  Future<PlanWithItems> getPlan(int id) async {
    final plan = await _getPlanById(id);
    final itemRows = await _db.customSelect(
      'SELECT * FROM plan_items WHERE plan_id = ? ORDER BY created_at DESC',
      variables: [Variable.withInt(id)],
    ).get();
    return PlanWithItems(
      plan: plan,
      items: itemRows.map((row) => _itemFromRow(row.data)).toList(),
    );
  }

  Future<PlanModel> createPlan({
    required String title,
    String? description,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO plans
        (user_id, title, description, target_amount, start_date, end_date,
         role, created_at, updated_at)
      VALUES (1, ?, ?, ?, ?, ?, 'owner', ?, ?)
      ''',
      variables: [
        Variable.withString(title),
        Variable(description),
        Variable(targetAmount),
        Variable(startDate?.toIso8601String()),
        Variable(endDate?.toIso8601String()),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    return _getPlanById(id);
  }

  Future<void> updatePlan(
    int id, {
    required String title,
    String? description,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _db.customUpdate(
      '''
      UPDATE plans
      SET title = ?, description = ?, target_amount = ?, start_date = ?,
          end_date = ?, updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(title),
        Variable(description),
        Variable(targetAmount),
        Variable(startDate?.toIso8601String()),
        Variable(endDate?.toIso8601String()),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withInt(id),
      ],
    );
  }

  Future<void> deletePlan(int id) async {
    await _db.customUpdate(
      'DELETE FROM plans WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<PlanItemModel> addItem(
    int planId, {
    required String category,
    required double expectedAmount,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO plan_items
        (plan_id, category, expected_amount, spent_amount, notes, created_at,
         updated_at)
      VALUES (?, ?, ?, 0, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(planId),
        Variable.withString(category),
        Variable.withReal(expectedAmount),
        Variable(notes),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    return _getItemById(id);
  }

  Future<PlanItemModel> updateItem(
    int planId,
    int itemId, {
    required String category,
    required double expectedAmount,
    String? notes,
  }) async {
    await _db.customUpdate(
      '''
      UPDATE plan_items
      SET category = ?, expected_amount = ?, notes = ?, updated_at = ?
      WHERE id = ? AND plan_id = ?
      ''',
      variables: [
        Variable.withString(category),
        Variable.withReal(expectedAmount),
        Variable(notes),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withInt(itemId),
        Variable.withInt(planId),
      ],
    );
    return _getItemById(itemId);
  }

  Future<void> deleteItem(int planId, int itemId) async {
    await _db.customUpdate(
      'DELETE FROM plan_items WHERE id = ? AND plan_id = ?',
      variables: [Variable.withInt(itemId), Variable.withInt(planId)],
    );
  }

  Future<PlanItemModel> updateSpent(
    int planId,
    int itemId, {
    required double amount,
    required String operation,
  }) async {
    final sign = operation == 'subtract' ? '-' : '+';
    await _db.customUpdate(
      '''
      UPDATE plan_items
      SET spent_amount = MAX(0, spent_amount $sign ?),
          updated_at = ?
      WHERE id = ? AND plan_id = ?
      ''',
      variables: [
        Variable.withReal(amount),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withInt(itemId),
        Variable.withInt(planId),
      ],
    );
    return _getItemById(itemId);
  }

  Future<void> addCollaborator(int planId, String email, String role) async {
    throw ApiException(
      'Plan collaboration requires the backend and is unavailable for local personal plans.',
    );
  }

  Future<List<CollaboratorModel>> getCollaborators(int planId) async {
    return const [];
  }

  Future<void> removeCollaborator(int planId, int userId) async {
    throw ApiException(
      'Plan collaboration requires the backend and is unavailable for local personal plans.',
    );
  }

  Future<PlanModel> _getPlanById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM plans WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    return _planFromRow(rows.first.data);
  }

  Future<PlanItemModel> _getItemById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM plan_items WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    return _itemFromRow(rows.first.data);
  }

  PlanModel _planFromRow(Map<String, Object?> row) {
    return PlanModel(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      targetAmount: row['target_amount'] != null
          ? (row['target_amount'] as num).toDouble()
          : null,
      startDate: row['start_date'] != null
          ? DateTime.parse(row['start_date'] as String)
          : null,
      endDate: row['end_date'] != null
          ? DateTime.parse(row['end_date'] as String)
          : null,
      role: row['role'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  PlanItemModel _itemFromRow(Map<String, Object?> row) {
    return PlanItemModel(
      id: row['id'] as int,
      planId: row['plan_id'] as int,
      category: row['category'] as String,
      expectedAmount: (row['expected_amount'] as num).toDouble(),
      spentAmount: (row['spent_amount'] as num).toDouble(),
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
