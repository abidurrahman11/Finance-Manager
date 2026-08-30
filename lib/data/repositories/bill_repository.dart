import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/bill_model.dart';

class BillRepository {
  final AppDatabase _db;

  BillRepository({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  Future<List<BillModel>> getBills() async {
    final rows = await _db
        .customSelect('SELECT * FROM bills ORDER BY created_at DESC')
        .get();
    return rows.map((row) => _billFromRow(row.data)).toList();
  }

  Future<BillModel> createBill({
    required String title,
    required double amount,
    required int dueDay,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.customInsert(
      '''
      INSERT INTO bills
        (user_id, title, amount, due_day, notes, created_at, updated_at)
      VALUES (1, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(title),
        Variable.withReal(amount),
        Variable.withInt(dueDay),
        Variable(notes),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    return _getBillById(id);
  }

  Future<BillModel> updateBill(
    int id, {
    required String title,
    required double amount,
    required int dueDay,
    String? notes,
  }) async {
    await _db.customUpdate(
      '''
      UPDATE bills
      SET title = ?, amount = ?, due_day = ?, notes = ?, updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(title),
        Variable.withReal(amount),
        Variable.withInt(dueDay),
        Variable(notes),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withInt(id),
      ],
    );
    return _getBillById(id);
  }

  Future<void> deleteBill(int id) async {
    await _db.customUpdate(
      'DELETE FROM bills WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<List<BillPaymentStatus>> getPaymentsForMonth(String month) async {
    final rows = await _db.customSelect(
      '''
          SELECT
            b.id AS bill_id,
            b.title AS title,
            b.amount AS expected_amount,
            b.due_day AS due_day,
            b.notes AS bill_notes,
            p.id AS payment_id,
            COALESCE(p.status, 'pending') AS status,
            p.paid_amount AS paid_amount,
            p.notes AS payment_notes,
            p.updated_at AS updated_at
          FROM bills b
          LEFT JOIN bill_payments p
            ON p.bill_id = b.id AND p.month = ?
          ORDER BY b.due_day ASC, b.title ASC
          ''',
      variables: [Variable.withString(month)],
    ).get();
    return rows.map((row) => _paymentFromRow(row.data)).toList();
  }

  Future<void> markPayment(
    int billId, {
    required String month,
    required String status,
    double? paidAmount,
    String? notes,
  }) async {
    await _db.customInsert(
      '''
      INSERT INTO bill_payments
        (bill_id, month, status, paid_amount, notes, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(bill_id, month) DO UPDATE SET
        status = excluded.status,
        paid_amount = excluded.paid_amount,
        notes = excluded.notes,
        updated_at = excluded.updated_at
      ''',
      variables: [
        Variable.withInt(billId),
        Variable.withString(month),
        Variable.withString(status),
        Variable(paidAmount),
        Variable(notes),
        Variable.withString(DateTime.now().toIso8601String()),
      ],
    );
  }

  Future<void> resetMonthlyPayments({String? month}) async {
    final selectedMonth = month ?? _currentMonthKey();
    await _db.customUpdate(
      'DELETE FROM bill_payments WHERE month = ?',
      variables: [Variable.withString(selectedMonth)],
    );
  }

  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<BillModel> _getBillById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM bills WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    return _billFromRow(rows.first.data);
  }

  BillModel _billFromRow(Map<String, Object?> row) {
    return BillModel(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      dueDay: row['due_day'] as int,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  BillPaymentStatus _paymentFromRow(Map<String, Object?> row) {
    return BillPaymentStatus(
      billId: row['bill_id'] as int,
      title: row['title'] as String,
      expectedAmount: (row['expected_amount'] as num).toDouble(),
      dueDay: row['due_day'] as int,
      billNotes: row['bill_notes'] as String?,
      paymentId: row['payment_id'] as int?,
      status: row['status'] as String,
      paidAmount: row['paid_amount'] != null
          ? (row['paid_amount'] as num).toDouble()
          : null,
      paymentNotes: row['payment_notes'] as String?,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }
}
