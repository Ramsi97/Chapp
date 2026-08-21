import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entity/chat_entity.dart';
import '../../domain/entity/message_entity.dart';
import '../../domain/repository/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl extends ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, List<ChatEntity>>> watchChats(String uid) async* {
    try {
      await for (final chats in remoteDataSource.watchChats(uid)) {
        yield Right(chats);
      }
    } catch (e) {
      yield Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, ChatEntity>> watchChat(String chatId) async* {
    try {
      await for (final chat in remoteDataSource.watchChat(chatId)) {
        yield Right(chat);
      }
    } catch (e) {
      yield Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<MessageEntity>>> watchMessages(
    String chatId,
  ) async* {
    try {
      await for (final messages in remoteDataSource.watchMessages(chatId)) {
        yield Right(messages);
      }
    } catch (e) {
      yield Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String chatId,
    required String senderId,
    required List<String> participants,
    required MessageType type,
    String? text,
    String? imagePath,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.sendMessage(
        chatId: chatId,
        senderId: senderId,
        participants: participants,
        type: type,
        text: text,
        imagePath: imagePath,
      );
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to send message'));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> getOrCreateDirectChat({
    required String myUid,
    required String otherUid,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final chat = await remoteDataSource.getOrCreateDirectChat(
        myUid: myUid,
        otherUid: otherUid,
      );
      return Right(chat);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to open chat'));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? imagePath,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final chat = await remoteDataSource.createGroupChat(
        name: name,
        createdBy: createdBy,
        participants: participants,
        imagePath: imagePath,
      );
      return Right(chat);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to create group'));
    }
  }

  @override
  Future<Either<Failure, void>> markChatRead({
    required String chatId,
    required String uid,
  }) async {
    try {
      await remoteDataSource.markChatRead(chatId: chatId, uid: uid);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to mark read'));
    }
  }

  @override
  Future<Either<Failure, void>> setTyping({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    try {
      await remoteDataSource.setTyping(
        chatId: chatId,
        uid: uid,
        isTyping: isTyping,
      );
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to update typing'));
    }
  }
}
