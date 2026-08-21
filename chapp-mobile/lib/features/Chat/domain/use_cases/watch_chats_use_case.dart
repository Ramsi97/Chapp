import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../entity/chat_entity.dart';
import '../repository/chat_repository.dart';

class WatchChatsUseCase
    extends StreamUseCase<List<ChatEntity>, WatchChatsParams> {
  final ChatRepository repository;
  WatchChatsUseCase({required this.repository});

  @override
  Stream<Either<Failure, List<ChatEntity>>> call(WatchChatsParams params) {
    return repository.watchChats(params.uid);
  }
}

class WatchChatsParams {
  final String uid;
  WatchChatsParams({required this.uid});
}
