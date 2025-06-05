import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/security_settings.dart';
import '../repositories/security_repository.dart';

class GetSecuritySettings implements UseCase<SecuritySettings, String> {
  final SecurityRepository repository;

  GetSecuritySettings(this.repository);

  @override
  Future<Either<Failure, SecuritySettings>> call(String userId) async {
    return await repository.getSecuritySettings(userId);
  }
}
