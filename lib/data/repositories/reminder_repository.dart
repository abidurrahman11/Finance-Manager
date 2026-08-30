import 'package:drift/drift.dart';
import '../local/app_database.dart';
import '../models/reminder_model.dart';

class ReminderRepository {
  final AppDatabase _db;

  ReminderRepository({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  Future<List<ReminderModel>> getReminders() async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM reminders ORDER BY is_completed ASC, created_at DESC',
        )
        .get();
    return rows.map((row) => _fromRow(row.data)).toList();
  }

  Future<ReminderModel> createReminder({
    required String title,
    String? notes,
    required ReminderModel Function(int id) builder,
  }) async {
    // Handled via the direct insert below instead
    throw UnimplementedError('Use createReminderDirect');
  }

  Future<ReminderModel> createReminderDirect({
    required String title,
    String? notes,
    required String type,
    required String priority,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO reminders
        (title, notes, type, priority, is_completed, due_date, created_at, updated_at)
      VALUES (?, ?, ?, ?, 0, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(title),
        Variable(notes),
        Variable.withString(type),
        Variable.withString(priority),
        Variable(dueDate?.toIso8601String()),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    return _getById(id);
  }

  Future<ReminderModel> updateReminder(
    int id, {
    required String title,
    String? notes,
    required String type,
    required String priority,
    required bool isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.customUpdate(
      '''
      UPDATE reminders
      SET title = ?, notes = ?, type = ?, priority = ?,
          is_completed = ?, due_date = ?, updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(title),
        Variable(notes),
        Variable.withString(type),
        Variable.withString(priority),
        Variable.withInt(isCompleted ? 1 : 0),
        clearDueDate ? const Variable(null) : Variable(dueDate?.toIso8601String()),
        Variable.withString(now),
        Variable.withInt(id),
      ],
    );
    return _getById(id);
  }

  Future<void> toggleCompleted(int id, {required bool isCompleted}) async {
    await _db.customUpdate(
      'UPDATE reminders SET is_completed = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable.withInt(isCompleted ? 1 : 0),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withInt(id),
      ],
    );
  }

  Future<void> deleteReminder(int id) async {
    await _db.customUpdate(
      'DELETE FROM reminders WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<ReminderModel> _getById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM reminders WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    return _fromRow(rows.first.data);
  }

  ReminderModel _fromRow(Map<String, Object?> row) {
    return ReminderModel(
      id: row['id'] as int,
      title: row['title'] as String,
      notes: row['notes'] as String?,
      type: ReminderModel.typeFromString(row['type'] as String),
      priority: ReminderModel.priorityFromString(row['priority'] as String),
      isCompleted: (row['is_completed'] as int) == 1,
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
