import 'dart:async';
import 'dart:io';

import 'package:chapp/core/error/exception.dart';
import 'package:chapp/features/Auth/data/model/registered_user_model.dart';
import 'package:chapp/features/Auth/data/model/otp_user_result_model.dart';
import 'package:chapp/features/Auth/data/model/otp_verifcation_data_model.dart';
import 'package:chapp/features/Auth/data/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class AuthRemoteDataSource {
  Future<OtpUserResultModel> login(String phoneNumber);
  Future<void> logOut();
  Future<RegisteredUserModel> register(
    RegisteredUserModel user, {
    String? imagePath,
  });
  Future<RegisteredUserModel?> getUserProfile(String userId);
  Future<bool> userProfileExists(String userId);
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
  final FirebaseStorage storage;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.storage,
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
        timeout: const Duration(seconds: 120),
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
        timeout: const Duration(seconds: 120),
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
  Future<RegisteredUserModel> register(
    RegisteredUserModel user, {
    String? imagePath,
  }) async {
    try {
      String? photoUrl = user.profilePic;
      if (imagePath != null) {
        final ref = storage.ref().child('profilePics/${user.userId}.jpg');
        await ref.putFile(File(imagePath));
        photoUrl = await ref.getDownloadURL();
      }

      final stored = RegisteredUserModel(
        userId: user.userId,
        name: user.name,
        username: user.username,
        phoneNumber: user.phoneNumber,
        profilePic: photoUrl,
        bio: user.bio,
        isOnline: user.isOnline,
        lastActiveAt: user.lastActiveAt,
        contacts: user.contacts,
        blockedUsers: user.blockedUsers,
        settings: user.settings,
        createdAt: user.createdAt,
      );

      await firestore
          .collection('users')
          .doc(user.userId)
          .set(stored.toJson());
      return stored;
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? "Registration failed");
    } catch (e) {
      throw UnknownException("Registration failed: $e");
    }
  }

  @override
  Future<RegisteredUserModel?> getUserProfile(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return RegisteredUserModel.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? "Failed to load profile");
    } catch (e) {
      throw UnknownException("Failed to load profile: $e");
    }
  }

  @override
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? "Failed to check profile");
    } catch (e) {
      throw UnknownException("Failed to check profile: $e");
    }
  }
}
