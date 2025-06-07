import 'package:equatable/equatable.dart';

class HotelSettings extends Equatable {
  final double waterRate;
  final double electricityRate;
  final double commonFee;
  final double lateFeePerDay;
  final int paymentDueDay;

  const HotelSettings({
    required this.waterRate,
    required this.electricityRate,
    required this.commonFee,
    required this.lateFeePerDay,
    required this.paymentDueDay,
  });

  @override
  List<Object> get props => [
    waterRate,
    electricityRate,
    commonFee,
    lateFeePerDay,
    paymentDueDay,
  ];
}
