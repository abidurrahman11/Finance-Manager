import 'package:drift/drift.dart';

import '../../core/network/api_exception.dart';
import '../local/app_database.dart';
import '../models/income_model.dart';

class IncomeRepository {
  final AppDatabase _db;

  IncomeRepository({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  Future<List<IncomeGroupModel>> getGroups() async {
    final rows = await _db
        .customSelect('SELECT * FROM income_groups ORDER BY created_at DESC')
        .get();
    return rows.map((row) => _groupFromRow(row.data)).toList();
  }

  Future<IncomeGroupModel> createGroup({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO income_groups
        (user_id, title, description, start_date, end_date, role, created_at)
      VALUES (1, ?, ?, ?, ?, 'owner', ?)
      ''',
      variables: [
        Variable.withString(title),
        Variable(description),
        Variable(startDate?.toIso8601String()),
        Variable(endDate?.toIso8601String()),
        Variable.withString(now),
      ],
    );
    return IncomeGroupModel(
      id: id,
      userId: 1,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      role: 'owner',
      createdAt: DateTime.parse(now),
    );
  }

  Future<void> updateGroup(
    int id, {
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _db.customUpdate(
      '''
      UPDATE income_groups
      SET title = ?, description = ?, start_date = ?, end_date = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(title),
        Variable(description),
        Variable(startDate?.toIso8601String()),
        Variable(endDate?.toIso8601String()),
        Variable.withInt(id),
      ],
    );
  }

  Future<void> deleteGroup(int id) async {
    await _db.customUpdate(
      'DELETE FROM income_groups WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<void> addCollaborator(int groupId, String email, String role) async {
    throw ApiException(
      'Income group collaboration requires the backend and is unavailable for local personal groups.',
    );
  }

  Future<List<Map<String, dynamic>>> getCollaborators(int groupId) async {
    return const [];
  }

  Future<void> removeCollaborator(int groupId, int userId) async {
    throw ApiException(
      'Income group collaboration requires the backend and is unavailable for local personal groups.',
    );
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
    final clauses = <String>[];
    final variables = <Variable>[];

    if (category != null) {
      clauses.add('category = ?');
      variables.add(Variable.withString(category));
    }
    if (startDate != null) {
      clauses.add('date(income_date) >= date(?)');
      variables.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      clauses.add('date(income_date) <= date(?)');
      variables.add(Variable.withString(endDate));
    }
    if (incomeGroupId != null) {
      clauses.add('income_group_id = ?');
      variables.add(Variable.withInt(incomeGroupId));
    }

    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final countRows = await _db
        .customSelect(
          'SELECT COUNT(*) AS total FROM incomes $where',
          variables: variables,
        )
        .get();
    final total = countRows.first.data['total'] as int;
    final totalPages = total == 0 ? 1 : (total / limit).ceil();
    final offset = (page - 1) * limit;
    final direction = order.toLowerCase() == 'asc' ? 'ASC' : 'DESC';
    final orderColumn = sortBy == 'amount' ? 'amount' : 'income_date';

    final rows = await _db.customSelect(
      '''
          SELECT * FROM incomes
          $where
          ORDER BY $orderColumn $direction, created_at DESC
          LIMIT ? OFFSET ?
          ''',
      variables: [
        ...variables,
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
    ).get();

    return PaginatedIncomes(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      data: rows.map((row) => _incomeFromRow(row.data)).toList(),
    );
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
    final now = DateTime.now().toIso8601String();
    final date = (incomeDate ?? DateTime.now()).toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO incomes
        (user_id, title, amount, category, income_date, notes, image_url,
         income_group_id, created_at, updated_at)
      VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(title),
        Variable.withReal(amount),
        Variable.withString(category),
        Variable.withString(date),
        Variable(notes),
        Variable(imagePath),
        Variable(incomeGroupId),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    return _getIncomeById(id);
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
    final now = DateTime.now().toIso8601String();
    await _db.customUpdate(
      '''
      UPDATE incomes
      SET title = ?, amount = ?, category = ?, income_date = ?, notes = ?,
          image_url = COALESCE(?, image_url), income_group_id = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(title),
        Variable.withReal(amount),
        Variable.withString(category),
        Variable.withString((incomeDate ?? DateTime.now()).toIso8601String()),
        Variable(notes),
        Variable(imagePath),
        Variable(incomeGroupId),
        Variable.withString(now),
        Variable.withInt(id),
      ],
    );
    return _getIncomeById(id);
  }

  Future<void> deleteIncome(int id) async {
    await _db.customUpdate(
      'DELETE FROM incomes WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<IncomeModel> _getIncomeById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM incomes WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    return _incomeFromRow(rows.first.data);
  }

  IncomeModel _incomeFromRow(Map<String, Object?> row) {
    return IncomeModel(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      incomeDate: DateTime.parse(row['income_date'] as String),
      notes: row['notes'] as String?,
      imageUrl: row['image_url'] as String?,
      incomeGroupId: row['income_group_id'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  IncomeGroupModel _groupFromRow(Map<String, Object?> row) {
    return IncomeGroupModel(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
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
}
