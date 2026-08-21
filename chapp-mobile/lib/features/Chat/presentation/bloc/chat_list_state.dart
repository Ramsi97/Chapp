part of 'chat_list_bloc.dart';

enum ChatListStatus { initial, loading, loaded, error }

class ChatListState extends Equatable {
  final ChatListStatus status;
  final List<ChatEntity> chats;
  final String? error;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.chats = const [],
    this.error,
  });

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatEntity>? chats,
    String? error,
    bool clearError = false,
  }) {
    return ChatListState(
      status: status ?? this.status,
      chats: chats ?? this.chats,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, chats, error];
}
