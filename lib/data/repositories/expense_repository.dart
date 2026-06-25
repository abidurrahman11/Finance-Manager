import 'package:drift/drift.dart';

import '../../core/network/api_exception.dart';
import '../local/app_database.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepository({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  Future<List<ExpenseGroupModel>> getGroups() async {
    final rows = await _db
        .customSelect('SELECT * FROM expense_groups ORDER BY created_at DESC')
        .get();
    return rows.map((row) => _groupFromRow(row.data)).toList();
  }

  Future<ExpenseGroupModel> createGroup({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO expense_groups
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
    return ExpenseGroupModel(
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
      UPDATE expense_groups
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
      'DELETE FROM expense_groups WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<void> addCollaborator(int groupId, String email, String role) async {
    throw ApiException(
      'Expense group collaboration requires the backend and is unavailable for local personal groups.',
    );
  }

  Future<List<Map<String, dynamic>>> getCollaborators(int groupId) async {
    return const [];
  }

  Future<void> removeCollaborator(int groupId, int userId) async {
    throw ApiException(
      'Expense group collaboration requires the backend and is unavailable for local personal groups.',
    );
  }

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
    final clauses = <String>[];
    final variables = <Variable>[];

    if (category != null) {
      clauses.add('category = ?');
      variables.add(Variable.withString(category));
    }
    if (startDate != null) {
      clauses.add('date(expense_date) >= date(?)');
      variables.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      clauses.add('date(expense_date) <= date(?)');
      variables.add(Variable.withString(endDate));
    }
    if (expenseGroupId != null) {
      clauses.add('expense_group_id = ?');
      variables.add(Variable.withInt(expenseGroupId));
    }

    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final countRows = await _db
        .customSelect(
          'SELECT COUNT(*) AS total FROM expenses $where',
          variables: variables,
        )
        .get();
    final total = countRows.first.data['total'] as int;
    final totalPages = total == 0 ? 1 : (total / limit).ceil();
    final offset = (page - 1) * limit;
    final direction = order.toLowerCase() == 'asc' ? 'ASC' : 'DESC';
    final orderColumn = sortBy == 'amount' ? 'amount' : 'expense_date';

    final rows = await _db.customSelect(
      '''
          SELECT * FROM expenses
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

    return PaginatedExpenses(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      data: rows.map((row) => _expenseFromRow(row.data)).toList(),
    );
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
    final now = DateTime.now().toIso8601String();
    final date = (expenseDate ?? DateTime.now()).toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO expenses
        (user_id, title, amount, category, expense_date, notes, image_url,
         expense_group_id, created_at, updated_at)
      VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(title),
        Variable.withReal(amount),
        Variable.withString(category),
        Variable.withString(date),
        Variable(notes),
        Variable(imagePath),
        Variable(expenseGroupId),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    return _getExpenseById(id);
  }

  /// Updates an expense record.
  ///
  /// [expenseGroupId] uses a sentinel pattern to distinguish between
  /// "caller wants to explicitly set group to null" vs "caller did not
  /// supply a value and the existing group membership should be preserved":
  ///
  ///   • Pass a non-null int  → set expense_group_id to that value.
  ///   • Pass null explicitly → PRESERVE the existing expense_group_id
  ///     (i.e. do NOT overwrite it). This is the safe default so that
  ///     editing title/amount/category/notes never accidentally unlinks
  ///     an expense from its group.
  ///
  /// To explicitly remove a group association, pass [clearGroupId: true].
  Future<ExpenseModel> updateExpense(
    int id, {
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    int? expenseGroupId,
    bool clearGroupId = false,
    String? imagePath,
  }) async {
    final now = DateTime.now().toIso8601String();

    if (clearGroupId || expenseGroupId != null) {
      // Caller explicitly wants to set (or clear) the group association.
      await _db.customUpdate(
        '''
        UPDATE expenses
        SET title = ?, amount = ?, category = ?, expense_date = ?, notes = ?,
            image_url = COALESCE(?, image_url), expense_group_id = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withString(title),
          Variable.withReal(amount),
          Variable.withString(category),
          Variable.withString(
              (expenseDate ?? DateTime.now()).toIso8601String()),
          Variable(notes),
          Variable(imagePath),
          clearGroupId ? const Variable(null) : Variable(expenseGroupId),
          Variable.withString(now),
          Variable.withInt(id),
        ],
      );
    } else {
      // expenseGroupId was not supplied — preserve the existing DB value.
      // Do NOT include expense_group_id in the SET clause at all.
      await _db.customUpdate(
        '''
        UPDATE expenses
        SET title = ?, amount = ?, category = ?, expense_date = ?, notes = ?,
            image_url = COALESCE(?, image_url),
            updated_at = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withString(title),
          Variable.withReal(amount),
          Variable.withString(category),
          Variable.withString(
              (expenseDate ?? DateTime.now()).toIso8601String()),
          Variable(notes),
          Variable(imagePath),
          Variable.withString(now),
          Variable.withInt(id),
        ],
      );
    }

    return _getExpenseById(id);
  }

  Future<void> deleteExpense(int id) async {
    await _db.customUpdate(
      'DELETE FROM expenses WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<ExpenseModel> _getExpenseById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM expenses WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    return _expenseFromRow(rows.first.data);
  }

  ExpenseModel _expenseFromRow(Map<String, Object?> row) {
    return ExpenseModel(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      expenseDate: DateTime.parse(row['expense_date'] as String),
      notes: row['notes'] as String?,
      imageUrl: row['image_url'] as String?,
      expenseGroupId: row['expense_group_id'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  ExpenseGroupModel _groupFromRow(Map<String, Object?> row) {
    return ExpenseGroupModel(
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
