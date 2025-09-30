import 'package:chapp/features/Auth/domain/entity/otp_verification_data.dart';

class OtpVerificationDataModel extends OtpVerificationData {
  const OtpVerificationDataModel({
    required super.verificationId,
    required super.resendToken,
  });

  factory OtpVerificationDataModel.fromJson(Map<String, dynamic> map) {
    return OtpVerificationDataModel(
      verificationId: map['verificationId'] as String,
      resendToken: map['resendToken'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {"verificationId": verificationId, "resendToken": resendToken};
  }

  factory OtpVerificationDataModel.fromEntity(OtpVerificationData entity) {
    return OtpVerificationDataModel(
      verificationId: entity.verificationId,
      resendToken: entity.resendToken,
    );
  }

  OtpVerificationData toEntity() {
    return OtpVerificationData(
      verificationId: verificationId,
      resendToken: resendToken,
    );
  }
}
