import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/tenant.dart';
import '../../repositories/tenant_repository.dart';

class GetTenantByUser implements UseCase<Tenant?, String> {
  final TenantRepository repository;

  GetTenantByUser(this.repository);

  @override
  Future<Either<Failure, Tenant?>> call(String userId) async {
    final result = await repository.getTenantByUserId(userId);
    return result.fold((failure) {
      // If no tenant found, return success with null
      if (failure.message.contains('No active tenancy')) {
        return const Right(null);
      }
      return Left(failure);
    }, (tenant) => Right(tenant));
  }
}
