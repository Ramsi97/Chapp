import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../repository/users_repository.dart';

class UpdatePresenceUseCase extends UseCase<void, UpdatePresenceParams> {
  final UsersRepository repository;
  UpdatePresenceUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdatePresenceParams params) {
    return repository.updatePresence(
      uid: params.uid,
      isOnline: params.isOnline,
    );
  }
}

class UpdatePresenceParams {
  final String uid;
  final bool isOnline;
  UpdatePresenceParams({required this.uid, required this.isOnline});
}
