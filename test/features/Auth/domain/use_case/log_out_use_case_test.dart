import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/log_out_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeVerifyParam extends Fake implements VerifyParam {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late VerifyUseCase verifyUseCase;

  setUpAll(() {
    registerFallbackValue(FakeVerifyParam());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    verifyUseCase = VerifyUseCase(repository: mockAuthRepository);
  });

  group('VerifyUseCase', () {
    final userEntity = UserEntity(
      userId: "123",
      name: "Tester",
      username: "testuser",
      phoneNumber: "9876543210",
      profilePic: "profile.png",
      bio: "Bio",
      isOnline: true,
      lastActiveAt: DateTime.now(),
      contacts: const [],
      blockedUsers: const [],
      settings: const {},
      createdAt: DateTime.now(),
    );

    test(
      'should return UserEntity when verification succeeds and user exists',
      () async {
        // arrange
        when(
          () => mockAuthRepository.verify(any()),
        ).thenAnswer((_) async => Right(userEntity));

        // act
        final result = await verifyUseCase(VerifyParam(otp: "123456"));

        // assert
        expect(result, Right(userEntity));
        verify(() => mockAuthRepository.verify("123456")).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test(
      'should return null when verification succeeds but user is not registered',
      () async {
        // arrange
        when(
          () => mockAuthRepository.verify(any()),
        ).thenAnswer((_) async => const Right(null));

        // act
        final result = await verifyUseCase(VerifyParam(otp: "654321"));

        // assert
        expect(result, const Right(null));
        verify(() => mockAuthRepository.verify("654321")).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test('should return Failure when verification fails', () async {
      // arrange
      final failure = ServerFailure("Invalid OTP");
      when(
        () => mockAuthRepository.verify(any()),
      ).thenAnswer((_) async => Left(failure));

      // act
      final result = await verifyUseCase(VerifyParam(otp: "000000"));

      // assert
      expect(result, Left(failure));
      verify(() => mockAuthRepository.verify("000000")).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
