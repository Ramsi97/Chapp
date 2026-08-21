import 'package:chapp/features/Auth/domain/entity/registered_user_entity.dart';
import 'package:chapp/features/Auth/domain/entity/otp_user_result.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, OtpUserResult>> login(String phoneNumber);
  Future<Either<Failure, void>> logOut();
  Future<Either<Failure, RegisteredUserEntity>> register(
    RegisteredUserEntity user, {
    String? imagePath,
  });
  Future<Either<Failure, UserEntity>> verifyManualOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<Either<Failure, OtpUserResult>> resendOtp(String phoneNumber, int? forceResendingToken);
  Future<Either<Failure, bool>> checkAuthenticated();
  Future<Either<Failure, bool>> userProfileExists(String userId);
  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
