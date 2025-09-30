import 'package:equatable/equatable.dart';

class OtpVerificationData extends Equatable {
  final String? verificationId;
  final int? resendToken;

  const OtpVerificationData({
    required this.verificationId,
    required this.resendToken,
  });

  @override
  List<Object?> get props => [verificationId, resendToken];
}
