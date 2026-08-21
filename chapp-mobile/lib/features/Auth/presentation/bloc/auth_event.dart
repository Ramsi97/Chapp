part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class AuthRequestOtp extends AuthEvent {
  final String phoneNumber;
  AuthRequestOtp(this.phoneNumber);
}

class AuthVerifyOtp extends AuthEvent {
  final String verificationId;
  final String otp;
  AuthVerifyOtp(this.verificationId, this.otp);
}

class AuthResendOtp extends AuthEvent {
  final String phoneNumber;
  final int? forceResendingToken;
  AuthResendOtp(this.phoneNumber, this.forceResendingToken);
}

class AuthCheckStatus extends AuthEvent {}

/// Completes profile setup for a phone-verified user (writes users/{uid}).
class AuthRegister extends AuthEvent {
  final String name;
  final String username;
  final String? bio;
  final String? imagePath;
  AuthRegister({
    required this.name,
    required this.username,
    this.bio,
    this.imagePath,
  });
}

class AuthLogout extends AuthEvent {}

class AuthClearError extends AuthEvent {}
