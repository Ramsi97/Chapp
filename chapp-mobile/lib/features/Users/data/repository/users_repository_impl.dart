import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../domain/repository/users_repository.dart';
import '../datasources/users_remote_data_source.dart';

class UsersRepositoryImpl extends UsersRepository {
  final UsersRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UsersRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<RegisteredUserEntity>>> getAllUsers(
    String excludeUid,
  ) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final users = await remoteDataSource.getAllUsers(excludeUid);
      return Right(users);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load users'));
    }
  }

  @override
  Future<Either<Failure, RegisteredUserEntity>> getUser(String uid) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final user = await remoteDataSource.getUser(uid);
      return Right(user);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load user'));
    }
  }

  @override
  Stream<Either<Failure, RegisteredUserEntity>> watchUser(String uid) async* {
    try {
      await for (final user in remoteDataSource.watchUser(uid)) {
        yield Right(user);
      }
    } catch (e) {
      yield Left(FirebaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePresence({
    required String uid,
    required bool isOnline,
  }) async {
    try {
      await remoteDataSource.updatePresence(uid: uid, isOnline: isOnline);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to update presence'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    required String uid,
    String? name,
    String? bio,
    String? imagePath,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.updateProfile(
        uid: uid,
        name: name,
        bio: bio,
        imagePath: imagePath,
      );
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirebaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to update profile'));
    }
  }
}
