import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

class VerifyUseCase extends UseCase<UserEntity?, VerifyParam> {
  final AuthRepository repository;
  VerifyUseCase({required this.repository});
  @override
  Future<Either<Failure, UserEntity?>> call(VerifyParam params) async {
    return await repository.verify(params.otp);
  }
}

class VerifyParam {
  String otp;
  VerifyParam({required this.otp});
}
