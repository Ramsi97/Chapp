import 'package:chapp/features/Auth/domain/entity/new_user_entity.dart';
import 'package:chapp/features/Auth/domain/entity/otp_user_result.dart';
import 'package:chapp/features/Auth/domain/entity/otp_verification_data.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, OtpUserResult>> login(String phoneNumber);
  Future<Either<Failure, void>> logOut();
  Future<Either<Failure, UserEntity>> register(NewUserEntity newUser);
  Future<Either<Failure, UserEntity>> verifyManualOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<Either<Failure, OtpUserResult>> resendOtp(String phoneNumber, int? forceResendingToken);
  Future<Either<Failure, bool>> checkAuthenticated();
}
