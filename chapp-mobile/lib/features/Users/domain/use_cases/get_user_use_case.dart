import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../repository/users_repository.dart';

class GetUserUseCase extends UseCase<RegisteredUserEntity, GetUserParams> {
  final UsersRepository repository;
  GetUserUseCase({required this.repository});

  @override
  Future<Either<Failure, RegisteredUserEntity>> call(GetUserParams params) {
    return repository.getUser(params.uid);
  }
}

class GetUserParams {
  final String uid;
  GetUserParams({required this.uid});
}
