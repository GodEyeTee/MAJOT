import '../../domain/entities/hotel_settings.dart';

class HotelSettingsModel extends HotelSettings {
  const HotelSettingsModel({
    required super.waterRate,
    required super.electricityRate,
    required super.commonFee,
    required super.lateFeePerDay,
    required super.paymentDueDay,
  });

  factory HotelSettingsModel.fromMap(Map<String, dynamic> map) {
    return HotelSettingsModel(
      waterRate: double.parse(map['water_rate']?.toString() ?? '11'),
      electricityRate: double.parse(map['electricity_rate']?.toString() ?? '7'),
      commonFee: double.parse(map['common_fee']?.toString() ?? '30'),
      lateFeePerDay: double.parse(map['late_fee_per_day']?.toString() ?? '100'),
      paymentDueDay: int.parse(map['payment_due_day']?.toString() ?? '5'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'water_rate': waterRate.toString(),
      'electricity_rate': electricityRate.toString(),
      'common_fee': commonFee.toString(),
      'late_fee_per_day': lateFeePerDay.toString(),
      'payment_due_day': paymentDueDay.toString(),
    };
  }
}
