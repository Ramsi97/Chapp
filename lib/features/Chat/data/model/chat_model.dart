import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/chat_entity.dart';
import 'message_model.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.type,
    required super.participants,
    required super.createdBy,
    required super.createdAt,
    super.name,
    super.photoUrl,
    super.lastMessageText,
    super.lastMessageSenderId,
    super.lastMessageType,
    super.lastMessageAt,
    super.unreadCounts,
    super.lastRead,
    super.typing,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    final lastMessage = (map['lastMessage'] as Map?)?.cast<String, dynamic>();
    return ChatModel(
      id: id,
      type: (map['type'] == 'group') ? ChatType.group : ChatType.direct,
      participants: List<String>.from(map['participants'] as List? ?? const []),
      name: map['name'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _toDate(map['createdAt']),
      lastMessageText: lastMessage?['text'] as String?,
      lastMessageSenderId: lastMessage?['senderId'] as String?,
      lastMessageType: lastMessage == null
          ? null
          : MessageModel.messageTypeFromString(lastMessage['type'] as String?),
      lastMessageAt: map['lastMessageAt'] == null
          ? null
          : _toDate(map['lastMessageAt']),
      unreadCounts: _toIntMap(map['unreadCounts']),
      lastRead: _toDateMap(map['lastRead']),
      typing: _toDateMap(map['typing']),
    );
  }

  factory ChatModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ChatModel.fromMap(doc.id, doc.data() ?? const {});
  }

  static String chatTypeToString(ChatType type) {
    return type == ChatType.group ? 'group' : 'direct';
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static Map<String, int> _toIntMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, v) => MapEntry(key.toString(), (v as num?)?.toInt() ?? 0),
      );
    }
    return const {};
  }

  static Map<String, DateTime> _toDateMap(dynamic value) {
    if (value is Map) {
      final result = <String, DateTime>{};
      value.forEach((key, v) {
        if (v is Timestamp) result[key.toString()] = v.toDate();
        if (v is DateTime) result[key.toString()] = v;
      });
      return result;
    }
    return const {};
  }
}
