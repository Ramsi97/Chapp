
import 'package:equatable/equatable.dart';

abstract class Failure {
  final String message;
  Failure(this.message);
  @override
  String toString() => message;
}

class NetworkFailure extends Failure with EquatableMixin {
  NetworkFailure([super.message = 'No internet connection']);
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure with EquatableMixin {
  ServerFailure([super.message = 'Server error occurred']);
  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure with EquatableMixin {
  CacheFailure([super.message = 'Cache error']);
  @override
  List<Object?> get props => [message];
}

class NotFoundFailure extends Failure with EquatableMixin {
  NotFoundFailure([super.message = 'Item not found']);
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure with EquatableMixin {
  AuthFailure([super.message = 'Authentication failed']);
  @override
  List<Object?> get props => [message];
}

class ValidationFailure extends Failure with EquatableMixin {
  ValidationFailure([super.message = 'Invalid input']);
  @override
  List<Object?> get props => [message];
}

class PermissionFailure extends Failure with EquatableMixin {
  PermissionFailure([super.message = 'Permission denied']);
  @override
  List<Object?> get props => [message];
}

class UnknownFailure extends Failure with EquatableMixin {
  UnknownFailure([super.message = 'Unknown error occurred']);
  @override
  List<Object?> get props => [message];
}

class FirebaseFailure extends Failure with EquatableMixin {
  FirebaseFailure([super.message = 'Firebase error occurred']);

  @override
  List<Object?> get props => [message];
}
