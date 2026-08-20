import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../repository/users_repository.dart';

class UpdateProfileUseCase extends UseCase<void, UpdateProfileParams> {
  final UsersRepository repository;
  UpdateProfileUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      uid: params.uid,
      name: params.name,
      bio: params.bio,
      imagePath: params.imagePath,
    );
  }
}

class UpdateProfileParams {
  final String uid;
  final String? name;
  final String? bio;
  final String? imagePath;
  UpdateProfileParams({
    required this.uid,
    this.name,
    this.bio,
    this.imagePath,
  });
}
