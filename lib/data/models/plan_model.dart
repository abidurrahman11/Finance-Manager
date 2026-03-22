class PlanModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final double? targetAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String role;
  final DateTime createdAt;

  PlanModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.targetAmount,
    this.startDate,
    this.endDate,
    required this.role,
    required this.createdAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      targetAmount: json['target_amount'] != null
          ? double.parse(json['target_amount'].toString())
          : null,
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

class PlanItemModel {
  final int id;
  final int planId;
  final String category;
  final double expectedAmount;
  final double spentAmount;
  final String? notes;
  final DateTime createdAt;

  PlanItemModel({
    required this.id,
    required this.planId,
    required this.category,
    required this.expectedAmount,
    required this.spentAmount,
    this.notes,
    required this.createdAt,
  });

  factory PlanItemModel.fromJson(Map<String, dynamic> json) {
    return PlanItemModel(
      id: json['id'],
      planId: json['plan_id'],
      category: json['category'],
      expectedAmount: double.parse(json['expected_amount'].toString()),
      spentAmount: double.parse(json['spent_amount'].toString()),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  double get progressPercent =>
      expectedAmount > 0 ? (spentAmount / expectedAmount).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spentAmount > expectedAmount;
  double get remaining => expectedAmount - spentAmount;
}

class PlanWithItems {
  final PlanModel plan;
  final List<PlanItemModel> items;

  PlanWithItems({required this.plan, required this.items});

  double get totalExpected =>
      items.fold(0, (sum, item) => sum + item.expectedAmount);
  double get totalSpent =>
      items.fold(0, (sum, item) => sum + item.spentAmount);
  /// Raw ratio — may exceed 1.0 when over budget. clamp at call site for widgets.
  double get overallProgress =>
      totalExpected > 0 ? totalSpent / totalExpected : 0.0;
}

class CollaboratorModel {
  final int userId;
  final String name;
  final String email;
  final String role;

  CollaboratorModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory CollaboratorModel.fromJson(Map<String, dynamic> json) {
    return CollaboratorModel(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
}
