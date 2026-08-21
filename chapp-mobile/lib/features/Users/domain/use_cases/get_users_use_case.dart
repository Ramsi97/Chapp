import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../repository/users_repository.dart';

class GetUsersUseCase
    extends UseCase<List<RegisteredUserEntity>, GetUsersParams> {
  final UsersRepository repository;
  GetUsersUseCase({required this.repository});

  @override
  Future<Either<Failure, List<RegisteredUserEntity>>> call(
    GetUsersParams params,
  ) {
    return repository.getAllUsers(params.excludeUid);
  }
}

class GetUsersParams {
  final String excludeUid;
  GetUsersParams({required this.excludeUid});
}
