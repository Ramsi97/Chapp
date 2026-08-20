part of 'users_bloc.dart';

@immutable
sealed class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {
  const UsersInitial();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  /// The full directory, unfiltered.
  final List<RegisteredUserEntity> all;

  /// The subset matching the current [query].
  final List<RegisteredUserEntity> filtered;
  final String query;

  const UsersLoaded({
    required this.all,
    required this.filtered,
    this.query = '',
  });

  UsersLoaded copyWith({
    List<RegisteredUserEntity>? all,
    List<RegisteredUserEntity>? filtered,
    String? query,
  }) {
    return UsersLoaded(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [all, filtered, query];
}

class UsersError extends UsersState {
  final String message;
  const UsersError(this.message);

  @override
  List<Object?> get props => [message];
}
