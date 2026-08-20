import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entity/chat_entity.dart';
import '../entity/message_entity.dart';

abstract class ChatRepository {
  /// Live list of the current user's chats, most-recent first.
  Stream<Either<Failure, List<ChatEntity>>> watchChats(String uid);

  /// Live view of a single chat document (typing, unread, lastRead, members).
  Stream<Either<Failure, ChatEntity>> watchChat(String chatId);

  /// Live message history for a chat, oldest first.
  Stream<Either<Failure, List<MessageEntity>>> watchMessages(String chatId);

  Future<Either<Failure, void>> sendMessage({
    required String chatId,
    required String senderId,
    required List<String> participants,
    required MessageType type,
    String? text,
    String? imagePath,
  });

  /// Returns the existing direct chat between the two users, creating it first
  /// if necessary (deterministic id, so it can never be duplicated).
  Future<Either<Failure, ChatEntity>> getOrCreateDirectChat({
    required String myUid,
    required String otherUid,
  });

  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? imagePath,
  });

  /// Resets the unread counter and stamps `lastRead` for [uid].
  Future<Either<Failure, void>> markChatRead({
    required String chatId,
    required String uid,
  });

  Future<Either<Failure, void>> setTyping({
    required String chatId,
    required String uid,
    required bool isTyping,
  });
}
