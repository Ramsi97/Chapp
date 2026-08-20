part of 'chat_list_bloc.dart';

@immutable
sealed class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

/// Start (or restart) watching the current user's chats.
class ChatListSubscriptionRequested extends ChatListEvent {
  final String myUid;
  const ChatListSubscriptionRequested(this.myUid);

  @override
  List<Object?> get props => [myUid];
}
