import '../../domain/entities/meter_reading.dart';

class MeterReadingModel extends MeterReading {
  const MeterReadingModel({
    required super.id,
    required super.roomId,
    required super.tenantId,
    required super.readingMonth,
    required super.waterUnits,
    required super.electricityUnits,
    required super.recordedBy,
    required super.createdAt,
  });

  factory MeterReadingModel.fromJson(Map<String, dynamic> json) {
    return MeterReadingModel(
      id: json['id'],
      roomId: json['room_id'],
      tenantId: json['tenant_id'],
      readingMonth: DateTime.parse(json['reading_month']),
      waterUnits: json['water_units'],
      electricityUnits: json['electricity_units'],
      recordedBy: json['recorded_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'tenant_id': tenantId,
      'reading_month': readingMonth.toIso8601String().split('T')[0],
      'water_units': waterUnits,
      'electricity_units': electricityUnits,
      'recorded_by': recordedBy,
    };
  }
}
