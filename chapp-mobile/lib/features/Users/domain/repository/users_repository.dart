import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../Auth/domain/entity/registered_user_entity.dart';

abstract class UsersRepository {
  /// Every registered user except [excludeUid] (the current user).
  Future<Either<Failure, List<RegisteredUserEntity>>> getAllUsers(
    String excludeUid,
  );

  Future<Either<Failure, RegisteredUserEntity>> getUser(String uid);

  /// Live view of a single user's profile — used for presence/last-seen.
  Stream<Either<Failure, RegisteredUserEntity>> watchUser(String uid);

  Future<Either<Failure, void>> updatePresence({
    required String uid,
    required bool isOnline,
  });

  Future<Either<Failure, void>> updateProfile({
    required String uid,
    String? name,
    String? bio,
    String? imagePath,
  });
}
