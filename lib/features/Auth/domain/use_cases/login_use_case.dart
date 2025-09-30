

import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/otp_user_result.dart';
import 'package:chapp/features/Auth/domain/entity/otp_verification_data.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repository/auth_repository.dart';

class LoginUseCase extends UseCase<OtpUserResult, LoginUseCaseParams>{
  final AuthRepository repository;
  LoginUseCase({required this.repository});

  @override
  Future<Either<Failure, OtpUserResult>> call(LoginUseCaseParams params) async {
    return await repository.login(params.phoneNumber);
  }
}

class LoginUseCaseParams {
  final String phoneNumber;
  LoginUseCaseParams({required this.phoneNumber});
}