import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/use_case/use_case.dart';
import '../entity/chat_entity.dart';
import '../repository/chat_repository.dart';

class CreateGroupChatUseCase
    extends UseCase<ChatEntity, CreateGroupChatParams> {
  final ChatRepository repository;
  CreateGroupChatUseCase({required this.repository});

  @override
  Future<Either<Failure, ChatEntity>> call(CreateGroupChatParams params) {
    return repository.createGroupChat(
      name: params.name,
      createdBy: params.createdBy,
      participants: params.participants,
      imagePath: params.imagePath,
    );
  }
}

class CreateGroupChatParams {
  final String name;
  final String createdBy;
  final List<String> participants;
  final String? imagePath;

  CreateGroupChatParams({
    required this.name,
    required this.createdBy,
    required this.participants,
    this.imagePath,
  });
}
