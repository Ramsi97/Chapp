import 'package:equatable/equatable.dart';

enum MessageType { text, image }

/// A single message inside a chat's `messages` subcollection.
class MessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? imageUrl;
  final DateTime sentAt;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.sentAt,
    this.text,
    this.imageUrl,
  });

  bool get isImage => type == MessageType.image;

  @override
  List<Object?> get props => [
    id,
    chatId,
    senderId,
    type,
    text,
    imageUrl,
    sentAt,
  ];
}
