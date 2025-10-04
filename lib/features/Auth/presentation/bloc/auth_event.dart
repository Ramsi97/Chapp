part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class AuthReset extends AuthEvent {}

class AuthRequestOtp extends AuthEvent {
  final String phoneNumber;
  AuthRequestOtp(this.phoneNumber);
}

class AuthVerifyOtp extends AuthEvent {
  final String otp;
  final String verificationId;
  AuthVerifyOtp(this.otp, this.verificationId);
}

class AuthResendOtp extends AuthEvent {
  final String phoneNumber;
  final int? forceResendingToken;
  AuthResendOtp(this.phoneNumber, this.forceResendingToken);
}

class AuthCheckStatus extends AuthEvent {}

class AuthLogout extends AuthEvent {}
