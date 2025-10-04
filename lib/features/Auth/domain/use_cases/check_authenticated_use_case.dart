import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

class CheckAuthenticatedUseCase extends UseCase<bool, NoParams> {
  final AuthRepository repository;
  CheckAuthenticatedUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.checkAuthenticated();
  }
}
