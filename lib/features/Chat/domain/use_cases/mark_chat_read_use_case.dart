import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../repository/chat_repository.dart';

class MarkChatReadUseCase extends UseCase<void, MarkChatReadParams> {
  final ChatRepository repository;
  MarkChatReadUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(MarkChatReadParams params) {
    return repository.markChatRead(chatId: params.chatId, uid: params.uid);
  }
}

class MarkChatReadParams {
  final String chatId;
  final String uid;
  MarkChatReadParams({required this.chatId, required this.uid});
}
