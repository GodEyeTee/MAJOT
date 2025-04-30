// lib/features/auth/domain/usecases/is_authenticated.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class IsAuthenticated implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  IsAuthenticated(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
