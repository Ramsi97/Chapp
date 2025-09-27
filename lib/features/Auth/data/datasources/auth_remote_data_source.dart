import 'package:chapp/features/Auth/data/model/new_user_model.dart';
import 'package:chapp/features/Auth/data/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthRemoteDataSource {
  Future<String> login(String phoneNumber);
  Future<void> logOut();
  Future<UserModel> register(NewUserModel newUser);
  Future<String> verifyManualOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<String> resendOtp(String phoneNumber, {int? forceResendingToken});
}

class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  String? _verificationId;
  int? _resendToken;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });
  @override
  Future<void> logOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  @override
  Future<String> login(String phoneNumber) async {
    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(minutes: 1),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {},
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      throw Exception("Login failed: $e");
    }
    return "";
  }

  @override
  Future<UserModel> register(NewUserModel newUser) {
    // TODO: implement register
    throw UnimplementedError();
  }

  @override
  Future<String> resendOtp(String phoneNumber, {int? forceResendingToken}) {
    // TODO: implement resendOtp
    throw UnimplementedError();
  }

  @override
  Future<String> verifyManualOtp({
    required String verificationId,
    required String smsCode,
  }) {
    // TODO: implement verifyManualOtp
    throw UnimplementedError();
  }
}
