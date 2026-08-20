import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../repository/users_repository.dart';

class WatchUserUseCase
    extends StreamUseCase<RegisteredUserEntity, WatchUserParams> {
  final UsersRepository repository;
  WatchUserUseCase({required this.repository});

  @override
  Stream<Either<Failure, RegisteredUserEntity>> call(WatchUserParams params) {
    return repository.watchUser(params.uid);
  }
}

class WatchUserParams {
  final String uid;
  WatchUserParams({required this.uid});
}
