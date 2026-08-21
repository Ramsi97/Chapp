part of 'users_bloc.dart';

@immutable
sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

/// Load the full directory (everyone except [excludeUid]).
class UsersLoadRequested extends UsersEvent {
  final String excludeUid;
  const UsersLoadRequested(this.excludeUid);

  @override
  List<Object?> get props => [excludeUid];
}

/// Filter the already-loaded directory client-side.
class UsersSearchChanged extends UsersEvent {
  final String query;
  const UsersSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}
