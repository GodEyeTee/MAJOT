import '../../domain/entities/tenant.dart';

class TenantModel extends Tenant {
  const TenantModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.startDate,
    super.endDate,
    required super.depositAmount,
    super.depositPaidDate,
    super.depositReceiver,
    super.contractFile,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'],
      roomId: json['room_id'],
      userId: json['user_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      depositAmount: (json['deposit_amount'] ?? 0).toDouble(),
      depositPaidDate:
          json['deposit_paid_date'] != null
              ? DateTime.parse(json['deposit_paid_date'])
              : null,
      depositReceiver: json['deposit_receiver'],
      contractFile: json['contract_file'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'deposit_amount': depositAmount,
      'deposit_paid_date': depositPaidDate?.toIso8601String(),
      'deposit_receiver': depositReceiver,
      'contract_file': contractFile,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
