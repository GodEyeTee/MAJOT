import 'package:equatable/equatable.dart';

class Tenant extends Equatable {
  final String id;
  final String roomId;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final double depositAmount;
  final DateTime? depositPaidDate;
  final String? depositReceiver;
  final String? contractFile;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tenant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.depositAmount,
    this.depositPaidDate,
    this.depositReceiver,
    this.contractFile,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    userId,
    startDate,
    endDate,
    depositAmount,
    depositPaidDate,
    depositReceiver,
    contractFile,
    isActive,
    createdAt,
    updatedAt,
  ];
}
