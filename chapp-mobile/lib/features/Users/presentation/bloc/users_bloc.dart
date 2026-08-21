import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../domain/use_cases/get_users_use_case.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final GetUsersUseCase getUsersUseCase;

  UsersBloc({required this.getUsersUseCase}) : super(const UsersInitial()) {
    on<UsersLoadRequested>(_onLoadRequested);
    on<UsersSearchChanged>(_onSearchChanged);
  }

  Future<void> _onLoadRequested(
    UsersLoadRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(const UsersLoading());
    final result = await getUsersUseCase(
      GetUsersParams(excludeUid: event.excludeUid),
    );
    result.fold(
      (failure) => emit(UsersError(failure.message)),
      (users) => emit(UsersLoaded(all: users, filtered: users)),
    );
  }

  void _onSearchChanged(UsersSearchChanged event, Emitter<UsersState> emit) {
    final current = state;
    if (current is! UsersLoaded) return;

    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(current.copyWith(filtered: current.all, query: ''));
      return;
    }

    final filtered = current.all.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();

    emit(current.copyWith(filtered: filtered, query: event.query));
  }
}
