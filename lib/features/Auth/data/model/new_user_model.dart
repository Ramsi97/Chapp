import '../../domain/entity/new_user_entity.dart';

class NewUserModel extends NewUserEntity {
  NewUserModel({
    required super.userId,
    required super.phoneNumber,
    required super.fullName,
    super.profilePic,
    super.bio,
    super.isOnline,
    super.createdAt,
  });

  factory NewUserModel.fromJson(Map<String, dynamic> json) {
    return NewUserModel(
      userId: json['userId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      fullName: json['fullName'] as String,
      profilePic: json['profilePic'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'profilePic': profilePic,
      'bio': bio,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NewUserModel.fromEntity(NewUserEntity entity) {
    return NewUserModel(
      userId: entity.userId,
      phoneNumber: entity.phoneNumber,
      fullName: entity.fullName,
      profilePic: entity.profilePic,
      bio: entity.bio,
      isOnline: entity.isOnline,
      createdAt: entity.createdAt,
    );
  }
}
