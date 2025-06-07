import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tenant.dart';

abstract class TenantRepository {
  Future<Either<Failure, List<Tenant>>> getTenants();
  Future<Either<Failure, Tenant>> getTenant(String id);
  Future<Either<Failure, Tenant>> getTenantByRoomId(String roomId);
  Future<Either<Failure, Tenant>> getTenantByUserId(String userId);
  Future<Either<Failure, Tenant>> createTenant(Tenant tenant);
  Future<Either<Failure, Tenant>> updateTenant(Tenant tenant);
  Future<Either<Failure, void>> endTenancy(String tenantId, DateTime endDate);
  Future<Either<Failure, List<Tenant>>> getActiveTenants();
}
