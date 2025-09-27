

import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/entity/new_user_entity.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/use_case/use_case.dart';
import '../repository/auth_repository.dart';

class RegisterUseCase extends UseCase<UserEntity, NewUserEntity>{
  final AuthRepository repository;
  RegisterUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NewUserEntity params) {
    return repository.register(params);
  }


}