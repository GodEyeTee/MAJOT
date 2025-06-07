import 'package:equatable/equatable.dart';

enum ReservationStatus {
  pending('pending', 'รอยืนยัน'),
  confirmed('confirmed', 'ยืนยันแล้ว'),
  cancelled('cancelled', 'ยกเลิก');

  final String value;
  final String displayName;

  const ReservationStatus(this.value, this.displayName);

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReservationStatus.pending,
    );
  }
}

class Reservation extends Equatable {
  final String id;
  final String roomId;
  final String userId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final ReservationStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reservation({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    userId,
    checkInDate,
    checkOutDate,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
}
