import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

class LogOutUseCase extends UseCase<void, NoParams> {
  final AuthRepository repository;
  LogOutUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.logOut();
  }
}
