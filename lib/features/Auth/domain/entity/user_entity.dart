import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String name;
  final String username;
  final String phoneNumber;
  final String profilePic;
  final String bio;
  final bool isOnline;
  final DateTime lastActiveAt;
  final List<String> contacts;
  final List<String> blockedUsers;
  final Map<String, dynamic> settings;
  final DateTime createdAt;

  const UserEntity({
    required this.userId,
    required this.name,
    required this.username,
    required this.phoneNumber,
    required this.profilePic,
    required this.bio,
    required this.isOnline,
    required this.lastActiveAt,
    required this.contacts,
    required this.blockedUsers,
    required this.settings,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    userId,
    name,
    username,
    phoneNumber,
    profilePic,
    bio,
    isOnline,
    lastActiveAt,
    contacts,
    blockedUsers,
    settings,
    createdAt,
  ];
}
