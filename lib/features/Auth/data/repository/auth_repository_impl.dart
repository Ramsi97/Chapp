import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/data/datasources/auth_local_data_source.dart';
import 'package:chapp/features/Auth/data/datasources/auth_remote_data_source.dart';
import 'package:chapp/features/Auth/domain/entity/new_user_entity.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/network/network_info.dart';
import '../model/new_user_model.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await localDataSource.logOut();
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> login(String phoneNumber) async {
    if (await networkInfo.isConnected) {
      try {
        final verificationId = await remoteDataSource.login(phoneNumber);
        return Right(verificationId);
      } on ServerFailure catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure("Something went wrong"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(NewUserEntity newUser) async {
    if (await networkInfo.isConnected) {
      try {
        final newUserModel = NewUserModel.fromEntity(newUser);
        final user = await remoteDataSource.register(newUserModel);
        return Right(user);
      } on ServerFailure catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure("Something went wrong"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }
}
