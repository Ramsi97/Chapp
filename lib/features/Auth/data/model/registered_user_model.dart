import 'package:chapp/features/Auth/domain/entity/registered_user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisteredUserModel extends RegisteredUserEntity {
  const RegisteredUserModel({
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

  factory RegisteredUserModel.fromEntity(RegisteredUserEntity user) {
    return RegisteredUserModel(
      userId: user.userId,
      name: user.name,
      username: user.username,
      phoneNumber: user.phoneNumber,
      profilePic: user.profilePic,
      bio: user.bio,
      isOnline: user.isOnline,
      lastActiveAt: user.lastActiveAt,
      contacts: user.contacts,
      blockedUsers: user.blockedUsers,
      settings: user.settings,
      createdAt: user.createdAt,
    );
  }

  factory RegisteredUserModel.fromJson(Map<String, dynamic> json) {
    return RegisteredUserModel(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      profilePic: json['profilePic'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: _toDate(json['lastActiveAt']),
      contacts: List<String>.from(json['contacts'] as List? ?? const []),
      blockedUsers: List<String>.from(json['blockedUsers'] as List? ?? const []),
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
      createdAt: _toDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'username': username,
      'usernameLower': username.toLowerCase(),
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'bio': bio,
      'isOnline': isOnline,
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'contacts': contacts,
      'blockedUsers': blockedUsers,
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Firestore returns [Timestamp]; tolerate [DateTime]/String/null too.
  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
