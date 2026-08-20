part of 'messaging_bloc.dart';

@immutable
sealed class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

/// Open a conversation: begins watching its messages and chat document.
class MessagingStarted extends MessagingEvent {
  final String chatId;
  final String myUid;
  final List<String> participants;
  const MessagingStarted({
    required this.chatId,
    required this.myUid,
    required this.participants,
  });

  @override
  List<Object?> get props => [chatId, myUid, participants];
}

class MessagingMessageSent extends MessagingEvent {
  final MessageType type;
  final String? text;
  final String? imagePath;
  const MessagingMessageSent({
    this.type = MessageType.text,
    this.text,
    this.imagePath,
  });

  @override
  List<Object?> get props => [type, text, imagePath];
}

class MessagingTypingChanged extends MessagingEvent {
  final bool isTyping;
  const MessagingTypingChanged(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

class MessagingMarkReadRequested extends MessagingEvent {
  const MessagingMarkReadRequested();
}

/// Internal: a new snapshot of the message list arrived.
class MessagingMessagesUpdated extends MessagingEvent {
  final Either<Failure, List<MessageEntity>> result;
  const MessagingMessagesUpdated(this.result);

  @override
  List<Object?> get props => [result];
}

/// Internal: a new snapshot of the chat document arrived.
class MessagingChatUpdated extends MessagingEvent {
  final Either<Failure, ChatEntity> result;
  const MessagingChatUpdated(this.result);

  @override
  List<Object?> get props => [result];
}
