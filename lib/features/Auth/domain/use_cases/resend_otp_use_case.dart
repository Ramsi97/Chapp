import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/otp_user_result.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

class ResendOtpUseCase extends UseCase<OtpUserResult, ResendOtpUseCaseParams> {
  AuthRepository repository;
  ResendOtpUseCase({required this.repository});
  @override
  Future<Either<Failure, OtpUserResult>> call(ResendOtpUseCaseParams params) {
    return repository.resendOtp(params.phoneNumber, params.forceResendingToken);
  }
}

class ResendOtpUseCaseParams {
  final String phoneNumber;
  final int? forceResendingToken;
  ResendOtpUseCaseParams({
    required this.phoneNumber,
    required this.forceResendingToken,
  });
}
