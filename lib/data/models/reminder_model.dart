enum ReminderType { expense, income, task, custom }

enum ReminderPriority { low, medium, high }

class ReminderModel {
  final int id;
  final String title;
  final String? notes;
  final ReminderType type;
  final ReminderPriority priority;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.title,
    this.notes,
    required this.type,
    required this.priority,
    required this.isCompleted,
    this.dueDate,
    required this.createdAt,
  });

  ReminderModel copyWith({
    int? id,
    String? title,
    String? notes,
    ReminderType? type,
    ReminderPriority? priority,
    bool? isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static ReminderType typeFromString(String value) {
    switch (value) {
      case 'expense':
        return ReminderType.expense;
      case 'income':
        return ReminderType.income;
      case 'task':
        return ReminderType.task;
      default:
        return ReminderType.custom;
    }
  }

  static String typeToString(ReminderType type) {
    switch (type) {
      case ReminderType.expense:
        return 'expense';
      case ReminderType.income:
        return 'income';
      case ReminderType.task:
        return 'task';
      case ReminderType.custom:
        return 'custom';
    }
  }

  static ReminderPriority priorityFromString(String value) {
    switch (value) {
      case 'high':
        return ReminderPriority.high;
      case 'medium':
        return ReminderPriority.medium;
      default:
        return ReminderPriority.low;
    }
  }

  static String priorityToString(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.high:
        return 'high';
      case ReminderPriority.medium:
        return 'medium';
      case ReminderPriority.low:
        return 'low';
    }
  }
}
