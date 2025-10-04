import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entity/user_entity.dart';

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
  Future<void> cacheUser(UserEntity user) {
    // TODO: implement cacheUser
    throw UnimplementedError();
  }

  @override
  Future<UserEntity?> getCachedUser() {
    // TODO: implement getCachedUser
    throw UnimplementedError();
  }

  @override
  Future<void> logOut() {
    // TODO: implement logOut
    throw UnimplementedError();
  }

  @override
  Future<bool> checkAuthenticated() async {
    try {
      final user = firebaseAuth.currentUser;
      return user != null;
    } on FirebaseAuthException catch (e) {
      return false;
    } catch (e) {
      return false;
    }
  }


}