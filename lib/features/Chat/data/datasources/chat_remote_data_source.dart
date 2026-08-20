import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/error/exception.dart';
import '../../domain/entity/chat_entity.dart';
import '../../domain/entity/message_entity.dart';
import '../model/chat_model.dart';
import '../model/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> watchChats(String uid);
  Stream<ChatModel> watchChat(String chatId);
  Stream<List<MessageModel>> watchMessages(String chatId);
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required List<String> participants,
    required MessageType type,
    String? text,
    String? imagePath,
  });
  Future<ChatModel> getOrCreateDirectChat({
    required String myUid,
    required String otherUid,
  });
  Future<ChatModel> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? imagePath,
  });
  Future<void> markChatRead({required String chatId, required String uid});
  Future<void> setTyping({
    required String chatId,
    required String uid,
    required bool isTyping,
  });
}

class ChatRemoteDataSourceImpl extends ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ChatRemoteDataSourceImpl({required this.firestore, required this.storage});

  CollectionReference<Map<String, dynamic>> get _chats =>
      firestore.collection('chats');

  static String directChatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Stream<List<ChatModel>> watchChats(String uid) {
    return _chats
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromDoc).toList());
  }

  @override
  Stream<ChatModel> watchChat(String chatId) {
    return _chats.doc(chatId).snapshots().map(ChatModel.fromDoc);
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required List<String> participants,
    required MessageType type,
    String? text,
    String? imagePath,
  }) async {
    try {
      final chatRef = _chats.doc(chatId);
      final msgRef = chatRef.collection('messages').doc();

      String? imageUrl;
      if (type == MessageType.image && imagePath != null) {
        final ref = storage.ref().child('chatMedia/$chatId/${msgRef.id}.jpg');
        await ref.putFile(File(imagePath));
        imageUrl = await ref.getDownloadURL();
      }

      final typeStr = MessageModel.messageTypeToString(type);
      final preview = type == MessageType.image ? '📷 Photo' : (text ?? '');

      final batch = firestore.batch();
      batch.set(msgRef, {
        'chatId': chatId,
        'senderId': senderId,
        'type': typeStr,
        if (text != null && text.isNotEmpty) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'sentAt': FieldValue.serverTimestamp(),
      });

      final chatUpdate = <String, dynamic>{
        'lastMessage': {
          'text': preview,
          'senderId': senderId,
          'type': typeStr,
          'sentAt': FieldValue.serverTimestamp(),
        },
        'lastMessageAt': FieldValue.serverTimestamp(),
      };
      for (final uid in participants) {
        if (uid != senderId) {
          chatUpdate['unreadCounts.$uid'] = FieldValue.increment(1);
        }
      }
      batch.update(chatRef, chatUpdate);

      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to send message');
    } catch (e) {
      throw UnknownException('Failed to send message: $e');
    }
  }

  @override
  Future<ChatModel> getOrCreateDirectChat({
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final id = directChatId(myUid, otherUid);
      final ref = _chats.doc(id);
      final existing = await ref.get();
      if (existing.exists) {
        return ChatModel.fromDoc(existing);
      }

      await ref.set({
        'type': ChatModel.chatTypeToString(ChatType.direct),
        'participants': [myUid, otherUid],
        'createdBy': myUid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts': {myUid: 0, otherUid: 0},
        'lastRead': <String, dynamic>{},
        'typing': <String, dynamic>{},
      });

      final created = await ref.get();
      return ChatModel.fromDoc(created);
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to open chat');
    } catch (e) {
      throw UnknownException('Failed to open chat: $e');
    }
  }

  @override
  Future<ChatModel> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? imagePath,
  }) async {
    try {
      final ref = _chats.doc();

      String? photoUrl;
      if (imagePath != null) {
        final storageRef = storage.ref().child('groupPics/${ref.id}.jpg');
        await storageRef.putFile(File(imagePath));
        photoUrl = await storageRef.getDownloadURL();
      }

      await ref.set({
        'type': ChatModel.chatTypeToString(ChatType.group),
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'participants': participants,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts': {for (final uid in participants) uid: 0},
        'lastRead': <String, dynamic>{},
        'typing': <String, dynamic>{},
      });

      final created = await ref.get();
      return ChatModel.fromDoc(created);
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to create group');
    } catch (e) {
      throw UnknownException('Failed to create group: $e');
    }
  }

  @override
  Future<void> markChatRead({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _chats.doc(chatId).update({
        'unreadCounts.$uid': 0,
        'lastRead.$uid': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to mark read');
    } catch (e) {
      throw UnknownException('Failed to mark read: $e');
    }
  }

  @override
  Future<void> setTyping({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    try {
      await _chats.doc(chatId).update({
        'typing.$uid': isTyping
            ? FieldValue.serverTimestamp()
            : FieldValue.delete(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to update typing');
    } catch (e) {
      throw UnknownException('Failed to update typing: $e');
    }
  }
}
