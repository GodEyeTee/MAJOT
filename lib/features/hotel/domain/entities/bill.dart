import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending('pending', 'รอชำระ'),
  paid('paid', 'ชำระแล้ว'),
  overdue('overdue', 'เกินกำหนด'),
  partial('partial', 'ชำระบางส่วน');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class Bill extends Equatable {
  final String id;
  final String tenantId;
  final String roomId;
  final DateTime billMonth;
  final double roomRent;
  final int? waterUnits;
  final double? waterAmount;
  final int? electricityUnits;
  final double? electricityAmount;
  final double? commonFee;
  final double lateFee;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final DateTime dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Bill({
    required this.id,
    required this.tenantId,
    required this.roomId,
    required this.billMonth,
    required this.roomRent,
    this.waterUnits,
    this.waterAmount,
    this.electricityUnits,
    this.electricityAmount,
    this.commonFee,
    this.lateFee = 0,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentDate,
    required this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    tenantId,
    roomId,
    billMonth,
    roomRent,
    waterUnits,
    waterAmount,
    electricityUnits,
    electricityAmount,
    commonFee,
    lateFee,
    totalAmount,
    paymentStatus,
    paymentDate,
    dueDate,
    notes,
    createdAt,
    updatedAt,
  ];
}
