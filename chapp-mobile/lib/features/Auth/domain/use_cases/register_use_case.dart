import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/entity/registered_user_entity.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/use_case/use_case.dart';
import '../repository/auth_repository.dart';

class RegisterUseCase extends UseCase<RegisteredUserEntity, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase({required this.repository});

  @override
  Future<Either<Failure, RegisteredUserEntity>> call(RegisterParams params) {
    return repository.register(params.user, imagePath: params.imagePath);
  }
}

class RegisterParams {
  final RegisteredUserEntity user;

  /// Local file path of a picked profile image, uploaded during registration.
  final String? imagePath;

  RegisterParams({required this.user, this.imagePath});
}
