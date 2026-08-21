import 'package:chapp/core/error/failure.dart';
import 'package:chapp/features/Auth/domain/entity/registered_user_entity.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/register_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeRegisteredUserEntity extends Fake implements RegisteredUserEntity {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late RegisterUseCase registerUseCase;

  setUpAll(() {
    registerFallbackValue(FakeRegisteredUserEntity());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    registerUseCase = RegisterUseCase(repository: mockAuthRepository);
  });

  group('RegisterUseCase', () {
    final user = RegisteredUserEntity(
      userId: 'user1',
      name: 'Test User',
      username: 'testuser',
      phoneNumber: '1234567890',
      profilePic: null,
      bio: null,
      isOnline: true,
      lastActiveAt: DateTime(2025, 1, 1),
      contacts: const [],
      blockedUsers: const [],
      settings: const {},
      createdAt: DateTime(2025, 1, 1),
    );

    test('returns the registered user on success', () async {
      when(
        () => mockAuthRepository.register(
          any(),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => Right(user));

      final result = await registerUseCase(RegisterParams(user: user));

      expect(result, Right(user));
      verify(
        () => mockAuthRepository.register(user, imagePath: null),
      ).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('forwards the imagePath to the repository', () async {
      when(
        () => mockAuthRepository.register(
          any(),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => Right(user));

      await registerUseCase(
        RegisterParams(user: user, imagePath: '/tmp/a.jpg'),
      );

      verify(
        () => mockAuthRepository.register(user, imagePath: '/tmp/a.jpg'),
      ).called(1);
    });

    test('returns a Failure when registration fails', () async {
      final failure = ServerFailure('Registration failed');
      when(
        () => mockAuthRepository.register(
          any(),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => Left(failure));

      final result = await registerUseCase(RegisterParams(user: user));

      expect(result, Left(failure));
      verify(
        () => mockAuthRepository.register(user, imagePath: null),
      ).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
