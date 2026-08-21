import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/chat_entity.dart';
import '../../domain/entity/message_entity.dart';
import '../../domain/use_cases/mark_chat_read_use_case.dart';
import '../../domain/use_cases/send_message_use_case.dart';
import '../../domain/use_cases/set_typing_use_case.dart';
import '../../domain/use_cases/watch_chat_use_case.dart';
import '../../domain/use_cases/watch_messages_use_case.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final WatchMessagesUseCase watchMessagesUseCase;
  final WatchChatUseCase watchChatUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final SetTypingUseCase setTypingUseCase;
  final MarkChatReadUseCase markChatReadUseCase;

  StreamSubscription<Either<Failure, List<MessageEntity>>>? _messagesSub;
  StreamSubscription<Either<Failure, ChatEntity>>? _chatSub;

  String _chatId = '';
  String _myUid = '';
  List<String> _participants = const [];

  MessagingBloc({
    required this.watchMessagesUseCase,
    required this.watchChatUseCase,
    required this.sendMessageUseCase,
    required this.setTypingUseCase,
    required this.markChatReadUseCase,
  }) : super(const MessagingState()) {
    on<MessagingStarted>(_onStarted);
    on<MessagingMessageSent>(_onMessageSent);
    on<MessagingTypingChanged>(_onTypingChanged);
    on<MessagingMarkReadRequested>(_onMarkRead);
    on<MessagingMessagesUpdated>(_onMessagesUpdated);
    on<MessagingChatUpdated>(_onChatUpdated);
  }

  void _onStarted(MessagingStarted event, Emitter<MessagingState> emit) {
    _chatId = event.chatId;
    _myUid = event.myUid;
    _participants = event.participants;
    emit(state.copyWith(status: MessagingStatus.loading));

    _messagesSub?.cancel();
    _messagesSub = watchMessagesUseCase(WatchMessagesParams(chatId: _chatId))
        .listen((either) => add(MessagingMessagesUpdated(either)));

    _chatSub?.cancel();
    _chatSub = watchChatUseCase(WatchChatParams(chatId: _chatId))
        .listen((either) => add(MessagingChatUpdated(either)));

    // Reading it as soon as it's opened.
    markChatReadUseCase(MarkChatReadParams(chatId: _chatId, uid: _myUid));
  }

  void _onMessagesUpdated(
    MessagingMessagesUpdated event,
    Emitter<MessagingState> emit,
  ) {
    event.result.fold(
      (failure) => emit(
        state.copyWith(status: MessagingStatus.error, error: failure.message),
      ),
      (messages) {
        emit(
          state.copyWith(
            status: MessagingStatus.loaded,
            messages: messages,
            clearError: true,
          ),
        );
        // New messages while the screen is open → keep them marked read.
        markChatReadUseCase(MarkChatReadParams(chatId: _chatId, uid: _myUid));
      },
    );
  }

  void _onChatUpdated(
    MessagingChatUpdated event,
    Emitter<MessagingState> emit,
  ) {
    event.result.fold(
      // Chat-doc errors are non-fatal; the message list still works.
      (_) {},
      (chat) {
        if (chat.participants.isNotEmpty) _participants = chat.participants;
        emit(state.copyWith(chat: chat));
      },
    );
  }

  Future<void> _onMessageSent(
    MessagingMessageSent event,
    Emitter<MessagingState> emit,
  ) async {
    final text = event.text?.trim();
    if (event.type == MessageType.text && (text == null || text.isEmpty)) {
      return;
    }

    emit(state.copyWith(isSending: true, clearError: true));
    final result = await sendMessageUseCase(
      SendMessageParams(
        chatId: _chatId,
        senderId: _myUid,
        participants: _participants,
        type: event.type,
        text: text,
        imagePath: event.imagePath,
      ),
    );

    // Whatever happens, we're no longer "typing".
    setTypingUseCase(
      SetTypingParams(chatId: _chatId, uid: _myUid, isTyping: false),
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isSending: false, error: failure.message)),
      (_) => emit(state.copyWith(isSending: false, clearError: true)),
    );
  }

  Future<void> _onTypingChanged(
    MessagingTypingChanged event,
    Emitter<MessagingState> emit,
  ) async {
    if (_chatId.isEmpty) return;
    await setTypingUseCase(
      SetTypingParams(
        chatId: _chatId,
        uid: _myUid,
        isTyping: event.isTyping,
      ),
    );
  }

  Future<void> _onMarkRead(
    MessagingMarkReadRequested event,
    Emitter<MessagingState> emit,
  ) async {
    if (_chatId.isEmpty) return;
    await markChatReadUseCase(
      MarkChatReadParams(chatId: _chatId, uid: _myUid),
    );
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    _chatSub?.cancel();
    return super.close();
  }
}
