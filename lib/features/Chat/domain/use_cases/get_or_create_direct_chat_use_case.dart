import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../entity/chat_entity.dart';
import '../repository/chat_repository.dart';

class GetOrCreateDirectChatUseCase
    extends UseCase<ChatEntity, GetOrCreateDirectChatParams> {
  final ChatRepository repository;
  GetOrCreateDirectChatUseCase({required this.repository});

  @override
  Future<Either<Failure, ChatEntity>> call(
    GetOrCreateDirectChatParams params,
  ) {
    return repository.getOrCreateDirectChat(
      myUid: params.myUid,
      otherUid: params.otherUid,
    );
  }
}

class GetOrCreateDirectChatParams {
  final String myUid;
  final String otherUid;
  GetOrCreateDirectChatParams({required this.myUid, required this.otherUid});
}
