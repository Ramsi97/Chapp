import 'package:chapp/features/Auth/domain/entity/otp_verification_data.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:equatable/equatable.dart';

class OtpUserResult extends Equatable {
  final UserEntity? userEntity;
  final OtpVerificationData? otpVerificationData;

  const OtpUserResult({
    required this.userEntity,
    required this.otpVerificationData,
  });

  @override
  List<Object?> get props => [userEntity, otpVerificationData];
}
