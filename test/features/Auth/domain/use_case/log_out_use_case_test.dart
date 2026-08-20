import 'package:chapp/core/error/failure.dart';
import 'package:chapp/core/use_case/use_case.dart';
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

  group('LogOutUseCase', () {
    test('returns Right(null) when logout succeeds', () async {
      when(
        () => mockAuthRepository.logOut(),
      ).thenAnswer((_) async => const Right(null));

      final result = await logOutUseCase(NoParams());

      expect(result, const Right(null));
      verify(() => mockAuthRepository.logOut()).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('returns a Failure when logout fails', () async {
      final failure = FirebaseFailure('Logout failed');
      when(
        () => mockAuthRepository.logOut(),
      ).thenAnswer((_) async => Left(failure));

      final result = await logOutUseCase(NoParams());

      expect(result, Left(failure));
      verify(() => mockAuthRepository.logOut()).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
