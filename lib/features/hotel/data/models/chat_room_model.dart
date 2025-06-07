import '../../domain/entities/chat_room.dart';

class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    super.name,
    required super.participants,
    required super.isSupport,
    super.roomId,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'],
      name: json['name'],
      participants: List<String>.from(json['participants'] ?? []),
      isSupport: json['is_support'] ?? true,
      roomId: json['room_id'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'participants': participants,
      'is_support': isSupport,
      'room_id': roomId,
      'created_by': createdBy,
    };
  }
}
