import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

class VerifyOtpManualUseCase
    extends UseCase<UserEntity, VerifyOtpManualUseCaseParams> {
  AuthRepository repository;
  VerifyOtpManualUseCase({required this.repository});
  @override
  Future<Either<Failure, UserEntity>> call(
    VerifyOtpManualUseCaseParams params,
  ) {
    return repository.verifyManualOtp(
      verificationId: params.verificationId,
      smsCode: params.smsCode,
    );
  }
}

class VerifyOtpManualUseCaseParams {
  final String verificationId;
  final String smsCode;

  VerifyOtpManualUseCaseParams({
    required this.verificationId,
    required this.smsCode,
  });
}
