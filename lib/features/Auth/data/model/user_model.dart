import '../../domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.userId, required super.phoneNumber});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel(userId: json['userId'], phoneNumber: json['phoneNumber']);

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'phoneNumber': phoneNumber,
  };

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(userId: entity.userId, phoneNumber: entity.phoneNumber);
  }
}
