import 'package:chapp/core/error/exception.dart';
import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/data/datasources/auth_local_data_source.dart';
import 'package:chapp/features/Auth/data/datasources/auth_remote_data_source.dart';
import 'package:chapp/features/Auth/domain/entity/registered_user_entity.dart';
import 'package:chapp/features/Auth/domain/entity/otp_user_result.dart';

import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/network_info.dart';
import '../model/registered_user_model.dart';

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
      await remoteDataSource.logOut();
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(CacheFailure(e.message));
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseFailure(e.message ?? "Logout failed"));
    } catch (e) {
      return Left(UnknownFailure("Something went wrong"));
    }
  }

  @override
  Future<Either<Failure, OtpUserResult>> login(String phoneNumber) async {
    if (await networkInfo.isConnected) {
      try {
        final otpUserResultModel = await remoteDataSource.login(phoneNumber);
        return Right(otpUserResultModel.toEntity());
      } on ServerFailure catch (e) {
        return Left(ServerFailure(e.message));
      } on FirebaseAuthException catch (e) {
        return Left(FirebaseFailure(e.message ?? "Login failed"));
      } catch (e) {
        return Left(UnknownFailure("Something went wrong"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, RegisteredUserEntity>> register(
    RegisteredUserEntity user, {
    String? imagePath,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = RegisteredUserModel.fromEntity(user);
        final result = await remoteDataSource.register(
          userModel,
          imagePath: imagePath,
        );
        return Right(result);
      } on FirestoreException catch (e) {
        return Left(FirebaseFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure("Something went wrong"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, OtpUserResult>> resendOtp(
    String phoneNumber,
    int? forceResendingToken,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final otpUserResultModel = await remoteDataSource.resendOtp(
          phoneNumber,
          forceResendingToken: forceResendingToken,
        );
        return Right(otpUserResultModel.toEntity());
      } on FirebaseAuthException catch (e) {
        return Left(FirebaseFailure(e.message ?? "Resend OTP failed"));
      } catch (e) {
        return Left(UnknownFailure("Something went wrong"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyManualOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.verifyManualOtp(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        return Right(result);
      } on FirebaseAuthException catch (e) {
        return Left(FirebaseFailure(e.message ?? "OTP verification failed"));
      } catch (e) {
        return Left(UnknownFailure("OTP verification failed: $e"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> checkAuthenticated() async {
    try {
      final result = await localDataSource.checkAuthenticated();
      return Right(result);
    } on CacheFailure catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> userProfileExists(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final exists = await remoteDataSource.userProfileExists(userId);
        return Right(exists);
      } on FirestoreException catch (e) {
        return Left(FirebaseFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure("Something went wrong"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user);
    } catch (e) {
      return Left(UnknownFailure());
    }
  }
}
