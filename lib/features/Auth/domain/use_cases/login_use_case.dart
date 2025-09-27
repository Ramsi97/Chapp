

import 'package:chapp/core/use_case/use_case.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repository/auth_repository.dart';

class LoginUseCase extends UseCase<String, LoginUseCaseParams>{
  final AuthRepository repository;
  LoginUseCase({required this.repository});

  @override
  Future<Either<Failure, String>> call(LoginUseCaseParams params) async {
    return await repository.login(params.phoneNumber);
  }
}

class LoginUseCaseParams {
  final String phoneNumber;
  LoginUseCaseParams({required this.phoneNumber});
}