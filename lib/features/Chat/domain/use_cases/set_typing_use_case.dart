import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../repository/chat_repository.dart';

class SetTypingUseCase extends UseCase<void, SetTypingParams> {
  final ChatRepository repository;
  SetTypingUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(SetTypingParams params) {
    return repository.setTyping(
      chatId: params.chatId,
      uid: params.uid,
      isTyping: params.isTyping,
    );
  }
}

class SetTypingParams {
  final String chatId;
  final String uid;
  final bool isTyping;
  SetTypingParams({
    required this.chatId,
    required this.uid,
    required this.isTyping,
  });
}
