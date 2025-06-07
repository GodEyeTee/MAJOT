import '../../domain/entities/bill.dart';

class BillModel extends Bill {
  const BillModel({
    required String id,
    required String tenantId,
    required String roomId,
    required DateTime billMonth,
    required double roomRent,
    int? waterUnits,
    double? waterAmount,
    int? electricityUnits,
    double? electricityAmount,
    double? commonFee,
    double lateFee = 0,
    required double totalAmount,
    required PaymentStatus paymentStatus,
    DateTime? paymentDate,
    required DateTime dueDate,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
         id: id,
         tenantId: tenantId,
         roomId: roomId,
         billMonth: billMonth,
         roomRent: roomRent,
         waterUnits: waterUnits,
         waterAmount: waterAmount,
         electricityUnits: electricityUnits,
         electricityAmount: electricityAmount,
         commonFee: commonFee,
         lateFee: lateFee,
         totalAmount: totalAmount,
         paymentStatus: paymentStatus,
         paymentDate: paymentDate,
         dueDate: dueDate,
         notes: notes,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'],
      tenantId: json['tenant_id'],
      roomId: json['room_id'],
      billMonth: DateTime.parse(json['bill_month']),
      roomRent: (json['room_rent'] ?? 0).toDouble(),
      waterUnits: json['water_units'],
      waterAmount: json['water_amount']?.toDouble(),
      electricityUnits: json['electricity_units'],
      electricityAmount: json['electricity_amount']?.toDouble(),
      commonFee: json['common_fee']?.toDouble(),
      lateFee: (json['late_fee'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentStatus: PaymentStatus.fromString(
        json['payment_status'] ?? 'pending',
      ),
      paymentDate:
          json['payment_date'] != null
              ? DateTime.parse(json['payment_date'])
              : null,
      dueDate: DateTime.parse(json['due_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'room_id': roomId,
      'bill_month': billMonth.toIso8601String().split('T')[0],
      'room_rent': roomRent,
      'water_units': waterUnits,
      'water_amount': waterAmount,
      'electricity_units': electricityUnits,
      'electricity_amount': electricityAmount,
      'common_fee': commonFee,
      'late_fee': lateFee,
      'total_amount': totalAmount,
      'payment_status': paymentStatus.value,
      'payment_date': paymentDate?.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }
}
