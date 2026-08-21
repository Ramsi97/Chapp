import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../entity/message_entity.dart';
import '../repository/chat_repository.dart';

class WatchMessagesUseCase
    extends StreamUseCase<List<MessageEntity>, WatchMessagesParams> {
  final ChatRepository repository;
  WatchMessagesUseCase({required this.repository});

  @override
  Stream<Either<Failure, List<MessageEntity>>> call(
    WatchMessagesParams params,
  ) {
    return repository.watchMessages(params.chatId);
  }
}

class WatchMessagesParams {
  final String chatId;
  WatchMessagesParams({required this.chatId});
}
