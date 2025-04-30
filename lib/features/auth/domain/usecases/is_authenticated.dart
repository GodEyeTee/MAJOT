import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class IsAuthenticated implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  IsAuthenticated(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isAuthenticated();
  }
}
