import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.type,
    required super.sentAt,
    super.text,
    super.imageUrl,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      type: messageTypeFromString(map['type'] as String?),
      text: map['text'] as String?,
      imageUrl: map['imageUrl'] as String?,
      sentAt: _toDate(map['sentAt']),
    );
  }

  factory MessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MessageModel.fromMap(doc.id, doc.data() ?? const {});
  }

  static MessageType messageTypeFromString(String? value) {
    return value == 'image' ? MessageType.image : MessageType.text;
  }

  static String messageTypeToString(MessageType type) {
    return type == MessageType.image ? 'image' : 'text';
  }

  /// Firestore returns [Timestamp]; a freshly written serverTimestamp may still
  /// be null on the local echo, so fall back to "now".
  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
