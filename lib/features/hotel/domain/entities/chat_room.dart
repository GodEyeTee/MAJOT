import 'package:equatable/equatable.dart';

class ChatRoom extends Equatable {
  final String id;
  final String? name;
  final List<String> participants;
  final bool isSupport;
  final String? roomId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoom({
    required this.id,
    this.name,
    required this.participants,
    required this.isSupport,
    this.roomId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    participants,
    isSupport,
    roomId,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
