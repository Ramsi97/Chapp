import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failure.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// For use cases backed by a realtime stream (e.g. Firestore snapshots).
/// Emits [Right] on each successful snapshot and [Left] on error.
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
