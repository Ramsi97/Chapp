import '../../domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.name,
    required super.username,
    required super.phoneNumber,
    required super.profilePic,
    required super.bio,
    required super.isOnline,
    required super.lastActiveAt,
    required super.contacts,
    required super.blockedUsers,
    required super.settings,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['userId'],
    name: json['name'],
    username: json['username'],
    phoneNumber: json['phoneNumber'],
    profilePic: json['profilePic'],
    bio: json['bio'],
    isOnline: json['isOnline'],
    lastActiveAt: DateTime.parse(json['lastActiveAt']),
    contacts: List<String>.from(json['contacts']),
    blockedUsers: List<String>.from(json['blockedUsers']),
    settings: json['settings'], // depends on your type
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'username': username,
    'phoneNumber': phoneNumber,
    'profilePic': profilePic,
    'bio': bio,
    'isOnline': isOnline,
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'contacts': contacts,
    'blockedUsers': blockedUsers,
    'settings': settings,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      userId: entity.userId,
      name: entity.name,
      username: entity.username,
      phoneNumber: entity.phoneNumber,
      profilePic: entity.profilePic,
      bio: entity.bio,
      isOnline: entity.isOnline,
      lastActiveAt: entity.lastActiveAt,
      contacts: entity.contacts,
      blockedUsers: entity.blockedUsers,
      settings: entity.settings,
      createdAt: entity.createdAt,
    );
  }
}
