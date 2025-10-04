part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class Authenticated extends AuthState {}

final class Unauthenticated extends AuthState {}

final class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

final class OtpSent extends AuthState {
  final String verificationId;
  final int? resendToken;
  OtpSent(this.verificationId, this.resendToken);
}

final class OtpVerifying extends AuthState {}

final class OtpVerified extends AuthState {}

final class AuthLoggingOut extends AuthState {}
