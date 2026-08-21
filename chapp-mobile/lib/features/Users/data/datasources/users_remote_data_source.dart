import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/error/exception.dart';
import '../../../Auth/data/model/registered_user_model.dart';

abstract class UsersRemoteDataSource {
  Future<List<RegisteredUserModel>> getAllUsers(String excludeUid);
  Future<RegisteredUserModel> getUser(String uid);
  Stream<RegisteredUserModel> watchUser(String uid);
  Future<void> updatePresence({required String uid, required bool isOnline});
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? bio,
    String? imagePath,
  });
}

class UsersRemoteDataSourceImpl extends UsersRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  UsersRemoteDataSourceImpl({required this.firestore, required this.storage});

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  @override
  Future<List<RegisteredUserModel>> getAllUsers(String excludeUid) async {
    try {
      final snap = await _users.orderBy('name').get();
      return snap.docs
          .where((doc) => doc.id != excludeUid)
          .map((doc) => RegisteredUserModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to load users');
    } catch (e) {
      throw UnknownException('Failed to load users: $e');
    }
  }

  @override
  Future<RegisteredUserModel> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        throw NotFoundException('User not found');
      }
      return RegisteredUserModel.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to load user');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw UnknownException('Failed to load user: $e');
    }
  }

  @override
  Stream<RegisteredUserModel> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      return RegisteredUserModel.fromJson(doc.data() ?? const {});
    });
  }

  @override
  Future<void> updatePresence({
    required String uid,
    required bool isOnline,
  }) async {
    try {
      await _users.doc(uid).update({
        'isOnline': isOnline,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to update presence');
    } catch (e) {
      throw UnknownException('Failed to update presence: $e');
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? bio,
    String? imagePath,
  }) async {
    try {
      final update = <String, dynamic>{};
      if (name != null) update['name'] = name;
      if (bio != null) update['bio'] = bio;
      if (imagePath != null) {
        final ref = storage.ref().child('profilePics/$uid.jpg');
        await ref.putFile(File(imagePath));
        update['profilePic'] = await ref.getDownloadURL();
      }
      if (update.isNotEmpty) {
        await _users.doc(uid).update(update);
      }
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to update profile');
    } catch (e) {
      throw UnknownException('Failed to update profile: $e');
    }
  }
}
