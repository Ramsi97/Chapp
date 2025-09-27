import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/log_out_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late LogOutUseCase logOutUseCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    logOutUseCase = LogOutUseCase(repository: mockAuthRepository);
  });

  group('VerifyUseCase', () {
    test(
      'should return UserEntity when verification succeeds and user exists',
      () async {
        // arrange
        when(
          () => mockAuthRepository.logOut(),
        ).thenAnswer((_) async => Right(null));

        // act
        final result = await logOutUseCase(NoParams());

        // assert
        expect(result, Right(null));
        verify(() => mockAuthRepository.logOut()).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test(
      'should return null when verification succeeds but user is not registered',
      () async {
        // arrange
        when(
          () => mockAuthRepository.logOut(),
        ).thenAnswer((_) async => const Right(null));

        // act
        final result = await logOutUseCase(NoParams());

        // assert
        expect(result, const Right(null));
        verify(() => mockAuthRepository.logOut()).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test('should return Failure when verification fails', () async {
      // arrange
      final failure = ServerFailure("Invalid OTP");
      when(
        () => mockAuthRepository.logOut(),
      ).thenAnswer((_) async => Left(failure));

      // act
      final result = await logOutUseCase(NoParams());

      // assert
      expect(result, Left(failure));
      verify(() => mockAuthRepository.logOut()).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
