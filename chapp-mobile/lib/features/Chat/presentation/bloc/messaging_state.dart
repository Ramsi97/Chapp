part of 'messaging_bloc.dart';

enum MessagingStatus { initial, loading, loaded, error }

class MessagingState extends Equatable {
  final MessagingStatus status;
  final List<MessageEntity> messages;

  /// The live chat document — carries typing, lastRead (receipts) and members.
  final ChatEntity? chat;
  final bool isSending;
  final String? error;

  const MessagingState({
    this.status = MessagingStatus.initial,
    this.messages = const [],
    this.chat,
    this.isSending = false,
    this.error,
  });

  MessagingState copyWith({
    MessagingStatus? status,
    List<MessageEntity>? messages,
    ChatEntity? chat,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return MessagingState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      chat: chat ?? this.chat,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, messages, chat, isSending, error];
}
