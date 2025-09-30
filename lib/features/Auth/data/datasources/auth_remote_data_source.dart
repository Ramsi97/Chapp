import 'dart:async';

import 'package:chapp/core/error/exception.dart';
import 'package:chapp/features/Auth/data/model/new_user_model.dart';
import 'package:chapp/features/Auth/data/model/otp_user_result_model.dart';
import 'package:chapp/features/Auth/data/model/otp_verifcation_data_model.dart';
import 'package:chapp/features/Auth/data/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthRemoteDataSource {
  Future<OtpUserResultModel> login(String phoneNumber);
  Future<void> logOut();
  Future<UserModel> register(NewUserModel newUser);
  Future<UserModel> verifyManualOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<OtpUserResultModel> resendOtp(
    String phoneNumber, {
    int? forceResendingToken,
  });
}

class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<void> logOut() async {
    try {
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw UnknownException("Logout failed: $e");
    }
  }

  @override
  Future<OtpUserResultModel> login(String phoneNumber) async {
    final completer = Completer<OtpUserResultModel>();
    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!completer.isCompleted) {
            final UserCredential userCredential = await firebaseAuth
                .signInWithCredential(credential);
            completer.complete(
              OtpUserResultModel(
                userModel: UserModel(
                  userId: userCredential.user!.uid,
                  phoneNumber: userCredential.user!.phoneNumber ?? "",
                ),
                otpVerificationDataModel: null,
              ),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.completeError(
            FirebaseAuthException(code: e.code, message: e.message),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              OtpUserResultModel(
                userModel: null,
                otpVerificationDataModel: OtpVerificationDataModel(
                  verificationId: verificationId,
                  resendToken: resendToken,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      return completer.future;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<OtpUserResultModel> resendOtp(
    String phoneNumber, {
    int? forceResendingToken,
  }) async {
    final completer = Completer<OtpUserResultModel>();
    try {
      await firebaseAuth.verifyPhoneNumber(
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!completer.isCompleted) {
            final UserCredential userCredential = await firebaseAuth
                .signInWithCredential(credential);
            completer.complete(
              OtpUserResultModel(
                userModel: UserModel(
                  userId: userCredential.user!.uid,
                  phoneNumber: userCredential.user!.phoneNumber ?? "",
                ),
                otpVerificationDataModel: null,
              ),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.completeError(
            FirebaseAuthException(code: e.code, message: e.message),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              OtpUserResultModel(
                userModel: null,
                otpVerificationDataModel: OtpVerificationDataModel(
                  verificationId: verificationId,
                  resendToken: resendToken,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
      );
      return completer.future;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<UserModel> verifyManualOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final UserCredential userCredential = await firebaseAuth
          .signInWithCredential(credential);
      return UserModel(
        userId: userCredential.user!.uid,
        phoneNumber: userCredential.user!.phoneNumber ?? "",
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw UnknownException("OTP verification failed: $e");
    }
  }

  @override
  Future<UserModel> register(NewUserModel newUser) {
    // TODO: implement register
    throw UnimplementedError();
  }
}
