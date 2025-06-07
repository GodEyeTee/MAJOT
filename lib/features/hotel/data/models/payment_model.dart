import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.billId,
    required super.amount,
    required super.paymentDate,
    super.paymentMethod,
    super.referenceNumber,
    super.receiptUrl,
    required super.recordedBy,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      billId: json['bill_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      paymentMethod: json['payment_method'],
      referenceNumber: json['reference_number'],
      receiptUrl: json['receipt_url'],
      recordedBy: json['recorded_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bill_id': billId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'receipt_url': receiptUrl,
      'recorded_by': recordedBy,
    };
  }
}
