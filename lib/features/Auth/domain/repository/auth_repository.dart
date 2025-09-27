

import 'package:chapp/features/Auth/domain/entity/new_user_entity.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> login(String phoneNumber);
  Future<Either<Failure, void>> logOut();
  Future<Either<Failure, UserEntity>> register(NewUserEntity newUser);
}