import 'package:equatable/equatable.dart';

import 'message_entity.dart';

enum ChatType { direct, group }

/// A conversation document under the top-level `chats` collection. Works for
/// both 1-1 (`direct`) and `group` chats.
class ChatEntity extends Equatable {
  final String id;
  final ChatType type;
  final List<String> participants;

  /// Group-only metadata (null for direct chats).
  final String? name;
  final String? photoUrl;

  final String createdBy;
  final DateTime createdAt;

  // Denormalized last-message preview for the chat list.
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final MessageType? lastMessageType;
  final DateTime? lastMessageAt;

  /// uid → number of unread messages for that participant.
  final Map<String, int> unreadCounts;

  /// uid → the time that participant last opened the chat (for read receipts).
  final Map<String, DateTime> lastRead;

  /// uid → the last time that participant was typing (freshness-windowed).
  final Map<String, DateTime> typing;

  const ChatEntity({
    required this.id,
    required this.type,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.name,
    this.photoUrl,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCounts = const {},
    this.lastRead = const {},
    this.typing = const {},
  });

  bool get isGroup => type == ChatType.group;

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  /// The other participant in a direct chat (empty string if not applicable).
  String otherParticipant(String myUid) => participants.firstWhere(
    (id) => id != myUid,
    orElse: () => '',
  );

  @override
  List<Object?> get props => [
    id,
    type,
    participants,
    name,
    photoUrl,
    createdBy,
    createdAt,
    lastMessageText,
    lastMessageSenderId,
    lastMessageType,
    lastMessageAt,
    unreadCounts,
    lastRead,
    typing,
  ];
}
