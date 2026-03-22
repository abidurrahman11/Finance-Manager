class IncomeModel {
  final int id;
  final int userId;
  final String title;
  final double amount;
  final String category;
  final DateTime incomeDate;
  final String? notes;
  final String? imageUrl;
  final int? incomeGroupId;
  final DateTime createdAt;

  IncomeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.incomeDate,
    this.notes,
    this.imageUrl,
    this.incomeGroupId,
    required this.createdAt,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      incomeDate: DateTime.parse(json['income_date']),
      notes: json['notes'],
      imageUrl: json['image_url'],
      incomeGroupId: json['income_group_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class IncomeGroupModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String role;
  final DateTime createdAt;

  IncomeGroupModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.role,
    required this.createdAt,
  });

  factory IncomeGroupModel.fromJson(Map<String, dynamic> json) {
    return IncomeGroupModel(
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

class PaginatedIncomes {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<IncomeModel> data;

  PaginatedIncomes({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.data,
  });

  factory PaginatedIncomes.fromJson(Map<String, dynamic> json) {
    return PaginatedIncomes(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
      data: (json['data'] as List).map((e) => IncomeModel.fromJson(e)).toList(),
    );
  }
}
