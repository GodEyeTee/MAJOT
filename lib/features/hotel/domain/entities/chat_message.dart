import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String message;
  final List<String> attachments;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.message,
    this.attachments = const [],
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object> get props => [
    id,
    chatRoomId,
    senderId,
    message,
    attachments,
    isRead,
    createdAt,
  ];
}
