import 'package:equatable/equatable.dart';

class NewUserEntity extends Equatable{
  final String userId;
  final String phoneNumber;
  final String fullName;
  final String profilePic;
  final String bio;
  final bool isOnline;
  final DateTime createdAt;

  NewUserEntity({
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    this.profilePic = '',
    this.bio = '',
    this.isOnline = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  List<Object?> get props => [userId, phoneNumber, fullName, profilePic, bio, isOnline, createdAt];
}
