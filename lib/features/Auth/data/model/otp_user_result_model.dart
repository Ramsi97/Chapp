import 'package:chapp/features/Auth/data/model/otp_verifcation_data_model.dart';
import 'package:chapp/features/Auth/data/model/user_model.dart';
import 'package:chapp/features/Auth/domain/entity/otp_user_result.dart';

class OtpUserResultModel extends OtpUserResult {
  final UserModel? userModel;
  final OtpVerificationDataModel? otpVerificationDataModel;
  const OtpUserResultModel({
    required this.userModel,
    required this.otpVerificationDataModel,
  }) : super(
         userEntity: userModel,
         otpVerificationData: otpVerificationDataModel,
       );

  factory OtpUserResultModel.fromEntity(OtpUserResult entity) {
    return OtpUserResultModel(
      userModel: UserModel.fromEntity(entity.userEntity!),
      otpVerificationDataModel: OtpVerificationDataModel.fromEntity(
        entity.otpVerificationData!,
      ),
    );
  }

  OtpUserResult toEntity() {
    return OtpUserResult(
      userEntity: userEntity,
      otpVerificationData: otpVerificationData,
    );
  }

  factory OtpUserResultModel.fromJson(Map<String, dynamic> json) {
    return OtpUserResultModel(
      userModel: UserModel.fromJson(json['userEntity']),
      otpVerificationDataModel: OtpVerificationDataModel.fromJson(
        json['otpVerificationData'],
      ),
    );
  }
}
