import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/entity/otp_user_result.dart';
import 'package:chapp/features/Auth/domain/entity/otp_verification_data.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/resend_otp_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ResendOtpUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = ResendOtpUseCase(repository: mockAuthRepository);
  });

  group('ResendOtpUseCase', () {
    const phone = '+1234567890';
    final otpUserResult = OtpUserResult(
      userEntity: null,
      otpVerificationData: OtpVerificationData(
        verificationId: 'vid',
        resendToken: 42,
      ),
    );

    test('returns OtpUserResult and forwards the resend token', () async {
      when(
        () => mockAuthRepository.resendOtp(any(), any()),
      ).thenAnswer((_) async => Right(otpUserResult));

      final result = await useCase(
        ResendOtpUseCaseParams(phoneNumber: phone, forceResendingToken: 7),
      );

      expect(result, Right(otpUserResult));
      verify(() => mockAuthRepository.resendOtp(phone, 7)).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('returns a Failure on error', () async {
      final failure = FirebaseFailure('Resend failed');
      when(
        () => mockAuthRepository.resendOtp(any(), any()),
      ).thenAnswer((_) async => Left(failure));

      final result = await useCase(
        ResendOtpUseCaseParams(phoneNumber: phone, forceResendingToken: null),
      );

      expect(result, Left(failure));
      verify(() => mockAuthRepository.resendOtp(phone, null)).called(1);
    });
  });
}
