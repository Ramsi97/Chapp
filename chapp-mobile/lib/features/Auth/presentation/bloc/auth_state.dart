part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

/// Signed in AND has a completed profile → go to the app.
final class Authenticated extends AuthState {}

/// Signed in via phone but no `users/{uid}` profile yet → show profile setup.
final class ProfileSetupRequired extends AuthState {
  final String userId;
  final String phoneNumber;
  ProfileSetupRequired({required this.userId, required this.phoneNumber});
}

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

final class AuthNoError extends AuthState {}
