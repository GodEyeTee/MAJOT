import 'package:equatable/equatable.dart';

class MeterReading extends Equatable {
  final String id;
  final String roomId;
  final String tenantId;
  final DateTime readingMonth;
  final int waterUnits;
  final int electricityUnits;
  final String recordedBy;
  final DateTime createdAt;

  const MeterReading({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.readingMonth,
    required this.waterUnits,
    required this.electricityUnits,
    required this.recordedBy,
    required this.createdAt,
  });

  @override
  List<Object> get props => [
    id,
    roomId,
    tenantId,
    readingMonth,
    waterUnits,
    electricityUnits,
    recordedBy,
    createdAt,
  ];
}
