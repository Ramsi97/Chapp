import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../entity/message_entity.dart';
import '../repository/chat_repository.dart';

class SendMessageUseCase extends UseCase<void, SendMessageParams> {
  final ChatRepository repository;
  SendMessageUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) {
    return repository.sendMessage(
      chatId: params.chatId,
      senderId: params.senderId,
      participants: params.participants,
      type: params.type,
      text: params.text,
      imagePath: params.imagePath,
    );
  }
}

class SendMessageParams {
  final String chatId;
  final String senderId;
  final List<String> participants;
  final MessageType type;
  final String? text;
  final String? imagePath;

  SendMessageParams({
    required this.chatId,
    required this.senderId,
    required this.participants,
    required this.type,
    this.text,
    this.imagePath,
  });
}
