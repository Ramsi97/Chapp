import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String phoneNumber;

  const UserEntity({required this.userId, required this.phoneNumber});

  @override
  List<Object?> get props => [userId, phoneNumber];
}
