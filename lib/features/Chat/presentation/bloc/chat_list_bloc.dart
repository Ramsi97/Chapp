import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entity/chat_entity.dart';
import '../../domain/use_cases/watch_chats_use_case.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final WatchChatsUseCase watchChatsUseCase;

  ChatListBloc({required this.watchChatsUseCase})
    : super(const ChatListState()) {
    on<ChatListSubscriptionRequested>(_onSubscriptionRequested);
  }

  Future<void> _onSubscriptionRequested(
    ChatListSubscriptionRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading));
    await emit.forEach(
      watchChatsUseCase(WatchChatsParams(uid: event.myUid)),
      onData: (either) => either.fold(
        (failure) =>
            state.copyWith(status: ChatListStatus.error, error: failure.message),
        (chats) => state.copyWith(
          status: ChatListStatus.loaded,
          chats: chats,
          clearError: true,
        ),
      ),
    );
  }
}
