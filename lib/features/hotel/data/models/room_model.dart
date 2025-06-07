import '../../domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.roomNumber,
    required super.floor,
    required super.roomType,
    super.size,
    required super.monthlyRent,
    required super.status,
    super.description,
    super.amenities,
    super.images,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      roomNumber: json['room_number'],
      floor: json['floor'],
      roomType: json['room_type'],
      size: json['size']?.toDouble(),
      monthlyRent: (json['monthly_rent'] ?? 0).toDouble(),
      status: RoomStatus.fromString(json['status'] ?? 'available'),
      description: json['description'],
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_number': roomNumber,
      'floor': floor,
      'room_type': roomType,
      'size': size,
      'monthly_rent': monthlyRent,
      'status': status.value,
      'description': description,
      'amenities': amenities,
      'images': images,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
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
    return RoomModel(
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
}
