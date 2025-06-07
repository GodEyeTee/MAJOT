import 'package:equatable/equatable.dart';

enum RoomStatus {
  available('available', 'พร้อมใช้งาน'),
  maintenanceVacant('maintenance_vacant', 'แจ้งปรับปรุง (ว่าง)'),
  occupied('occupied', 'มีคนเช่า'),
  maintenanceOccupied('maintenance_occupied', 'แจ้งปรับปรุง (มีคนเช่า)'),
  reserved('reserved', 'จอง');

  final String value;
  final String displayName;

  const RoomStatus(this.value, this.displayName);

  static RoomStatus fromString(String value) {
    return RoomStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RoomStatus.available,
    );
  }
}

class Room extends Equatable {
  final String id;
  final String roomNumber;
  final int floor;
  final String roomType;
  final double? size;
  final double monthlyRent;
  final RoomStatus status;
  final String? description;
  final List<String> amenities;
  final List<String> images;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Room({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    this.size,
    required this.monthlyRent,
    required this.status,
    this.description,
    this.amenities = const [],
    this.images = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Room copyWith({
    String? id,
    String? roomNumber,
    int? floor,
    String? roomType,
    double? size,
    double? monthlyRent,
    RoomStatus? status,
    String? description,
    List<String>? amenities,
    List<String>? images,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      size: size ?? this.size,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      status: status ?? this.status,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    roomNumber,
    floor,
    roomType,
    size,
    monthlyRent,
    status,
    description,
    amenities,
    images,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
