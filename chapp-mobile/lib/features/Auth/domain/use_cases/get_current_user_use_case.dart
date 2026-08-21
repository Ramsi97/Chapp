import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

/// Returns the currently signed-in user's identity (uid + phone) or null.
class GetCurrentUserUseCase extends UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;
  GetCurrentUserUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
