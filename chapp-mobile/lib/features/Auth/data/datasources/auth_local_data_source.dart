import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entity/user_entity.dart';
import '../model/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserEntity user);
  Future<UserEntity?> getCachedUser();
  Future<void> logOut();
  Future<bool> checkAuthenticated();
}

class AuthLocalDataSourceImpl extends AuthLocalDataSource {
  final FirebaseAuth firebaseAuth;
  AuthLocalDataSourceImpl({required this.firebaseAuth});

  @override
  Future<void> cacheUser(UserEntity user) async {
    // Firebase persists the auth session itself; nothing extra to cache.
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return UserModel(
      userId: user.uid,
      phoneNumber: user.phoneNumber ?? '',
    );
  }

  @override
  Future<void> logOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<bool> checkAuthenticated() async {
    try {
      final user = firebaseAuth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }
}