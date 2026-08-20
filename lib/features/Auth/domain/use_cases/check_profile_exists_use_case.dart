import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';

/// Whether a `users/{uid}` profile document exists (i.e. the user finished
/// the profile-setup step after phone verification).
class CheckProfileExistsUseCase extends UseCase<bool, CheckProfileExistsParams> {
  final AuthRepository repository;
  CheckProfileExistsUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call(CheckProfileExistsParams params) {
    return repository.userProfileExists(params.userId);
  }
}

class CheckProfileExistsParams {
  final String userId;
  CheckProfileExistsParams({required this.userId});
}
