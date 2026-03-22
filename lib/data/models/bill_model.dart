class BillModel {
  final int id;
  final int userId;
  final String title;
  final double amount;
  final int dueDay;
  final String? notes;
  final DateTime createdAt;

  BillModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.dueDay,
    this.notes,
    required this.createdAt,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      dueDay: json['due_day'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BillPaymentStatus {
  final int billId;
  final String title;
  final double expectedAmount;
  final int dueDay;
  final String? billNotes;
  final int? paymentId;
  final String status;
  final double? paidAmount;
  final String? paymentNotes;
  final DateTime? updatedAt;

  BillPaymentStatus({
    required this.billId,
    required this.title,
    required this.expectedAmount,
    required this.dueDay,
    this.billNotes,
    this.paymentId,
    required this.status,
    this.paidAmount,
    this.paymentNotes,
    this.updatedAt,
  });

  bool get isPaid => status == 'paid';

  factory BillPaymentStatus.fromJson(Map<String, dynamic> json) {
    return BillPaymentStatus(
      billId: json['bill_id'],
      title: json['title'],
      expectedAmount: double.parse(json['expected_amount'].toString()),
      dueDay: json['due_day'],
      billNotes: json['bill_notes'],
      paymentId: json['payment_id'],
      status: json['status'] ?? 'pending',
      paidAmount: json['paid_amount'] != null
          ? double.parse(json['paid_amount'].toString())
          : null,
      paymentNotes: json['payment_notes'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}
