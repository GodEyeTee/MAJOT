import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/tenant.dart';
import '../../repositories/tenant_repository.dart';

class GetTenantByRoom implements UseCase<Tenant?, String> {
  final TenantRepository repository;

  GetTenantByRoom(this.repository);

  @override
  Future<Either<Failure, Tenant?>> call(String roomId) async {
    final result = await repository.getTenantByRoomId(roomId);
    return result.fold((failure) {
      // If no tenant found, return success with null
      if (failure.message.contains('No tenant found')) {
        return const Right(null);
      }
      return Left(failure);
    }, (tenant) => Right(tenant));
  }
}
