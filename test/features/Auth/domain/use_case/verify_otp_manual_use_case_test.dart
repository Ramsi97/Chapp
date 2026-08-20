import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/verify_otp_manual_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late VerifyOtpManualUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = VerifyOtpManualUseCase(repository: mockAuthRepository);
  });

  group('VerifyOtpManualUseCase', () {
    const verificationId = 'vid';
    const smsCode = '123456';
    const user = UserEntity(userId: 'u1', phoneNumber: '+100');

    test('returns UserEntity on success', () async {
      when(
        () => mockAuthRepository.verifyManualOtp(
          verificationId: any(named: 'verificationId'),
          smsCode: any(named: 'smsCode'),
        ),
      ).thenAnswer((_) async => const Right(user));

      final result = await useCase(
        VerifyOtpManualUseCaseParams(
          verificationId: verificationId,
          smsCode: smsCode,
        ),
      );

      expect(result, const Right(user));
      verify(
        () => mockAuthRepository.verifyManualOtp(
          verificationId: verificationId,
          smsCode: smsCode,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('returns a Failure on error', () async {
      final failure = FirebaseFailure('Invalid code');
      when(
        () => mockAuthRepository.verifyManualOtp(
          verificationId: any(named: 'verificationId'),
          smsCode: any(named: 'smsCode'),
        ),
      ).thenAnswer((_) async => Left(failure));

      final result = await useCase(
        VerifyOtpManualUseCaseParams(
          verificationId: verificationId,
          smsCode: smsCode,
        ),
      );

      expect(result, Left(failure));
    });
  });
}
