import '../../domain/entity/user_entity.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserEntity user);
  Future<UserEntity?> getCachedUser();
  Future<void> logOut();
}

class AuthLocalDataSourceImpl extends AuthLocalDataSource {
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
  
}