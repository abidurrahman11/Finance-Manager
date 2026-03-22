class ExpenseModel {
  final int id;
  final int userId;
  final String title;
  final double amount;
  final String category;
  final DateTime expenseDate;
  final String? notes;
  final String? imageUrl;
  final int? expenseGroupId;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.notes,
    this.imageUrl,
    this.expenseGroupId,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      expenseDate: DateTime.parse(json['expense_date']),
      notes: json['notes'],
      imageUrl: json['image_url'],
      expenseGroupId: json['expense_group_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ExpenseGroupModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String role;
  final DateTime createdAt;

  ExpenseGroupModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.role,
    required this.createdAt,
  });

  factory ExpenseGroupModel.fromJson(Map<String, dynamic> json) {
    return ExpenseGroupModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      startDate:
          json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      role: json['role'] ?? 'owner',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isOwner => role == 'owner';
  bool get canEdit => role == 'owner' || role == 'editor';
}

class PaginatedExpenses {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<ExpenseModel> data;

  PaginatedExpenses({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.data,
  });

  factory PaginatedExpenses.fromJson(Map<String, dynamic> json) {
    return PaginatedExpenses(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
      data: (json['data'] as List)
          .map((e) => ExpenseModel.fromJson(e))
          .toList(),
    );
  }
}
