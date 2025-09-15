import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/login_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginUseCase loginUseCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(repository: mockAuthRepository);
  });

  group('Login UseCase Testing', () {
    test('should return a string when login is successful', () async {
      when(
        () => mockAuthRepository.login(any()),
      ).thenAnswer((_) async => Right('success'));
      final result = await loginUseCase(
        LoginUseCaseParams(phoneNumber: '1234567890'),
      );
      expect(result.isRight(), true);
      expect(result.getOrElse(() => ''), 'success');
      verify(() => mockAuthRepository.login(any())).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return a failure when login fails', () async {
      when(
        () => mockAuthRepository.login(any()),
      ).thenAnswer((_) async => Left(ServerFailure()));
      final result = await loginUseCase(
        LoginUseCaseParams(phoneNumber: '1234567890'),
      );

      expect(result.isLeft(), true);
      verify(() => mockAuthRepository.login(any())).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
