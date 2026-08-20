import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../entity/chat_entity.dart';
import '../repository/chat_repository.dart';

class WatchChatUseCase extends StreamUseCase<ChatEntity, WatchChatParams> {
  final ChatRepository repository;
  WatchChatUseCase({required this.repository});

  @override
  Stream<Either<Failure, ChatEntity>> call(WatchChatParams params) {
    return repository.watchChat(params.chatId);
  }
}

class WatchChatParams {
  final String chatId;
  WatchChatParams({required this.chatId});
}
