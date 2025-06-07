import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String billId;
  final double amount;
  final DateTime paymentDate;
  final String? paymentMethod;
  final String? referenceNumber;
  final String? receiptUrl;
  final String recordedBy;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.billId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.referenceNumber,
    this.receiptUrl,
    required this.recordedBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    billId,
    amount,
    paymentDate,
    paymentMethod,
    referenceNumber,
    receiptUrl,
    recordedBy,
    createdAt,
  ];
}
