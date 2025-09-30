import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/entity/new_user_entity.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/register_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeNewUserEntity extends Fake implements NewUserEntity {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late RegisterUseCase registerUseCase;

  setUpAll(() {
    registerFallbackValue(FakeNewUserEntity());
  });
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    registerUseCase = RegisterUseCase(repository: mockAuthRepository);
  });

  group('Register Use Case Testing', () {
    // Dummy data for testing
    final userEntity = UserEntity(
      userId: "123",
      phoneNumber: "9876543210",
    );

    final newUser = NewUserEntity(
      userId: 'user1',
      phoneNumber: '1234567890',
      fullName: 'Test User',
    );

    test(
      'Should return UserEntity when the registration is successful',
      () async {
        // Arrange
        when(
          () => mockAuthRepository.register(any()),
        ).thenAnswer((_) async => Right(userEntity));

        // Act
        final result = await registerUseCase(newUser);

        // Assert
        expect(result, Right(userEntity));
        verify(() => mockAuthRepository.register(newUser)).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test('Should return Failure when registration fails', () async {
      // Arrange
      final failure = ServerFailure("Registration failed");
      when(
        () => mockAuthRepository.register(any()),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await registerUseCase(newUser);

      // Assert
      expect(result, Left(failure));
      verify(() => mockAuthRepository.register(newUser)).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
