import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../datasources/tenant_remote_data_source.dart';
import '../models/tenant_model.dart';

class TenantRepositoryImpl implements TenantRepository {
  final TenantRemoteDataSource remoteDataSource;

  TenantRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Tenant>>> getTenants() async {
    try {
      final tenants = await remoteDataSource.getTenants();
      return Right(tenants);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Tenant>> getTenant(String id) async {
    try {
      final tenant = await remoteDataSource.getTenant(id);
      return Right(tenant);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Tenant>> getTenantByRoomId(String roomId) async {
    try {
      final tenant = await remoteDataSource.getTenantByRoomId(roomId);
      if (tenant == null) {
        return Left(ServerFailure('No tenant found for this room'));
      }
      return Right(tenant);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Tenant>> getTenantByUserId(String userId) async {
    try {
      final tenant = await remoteDataSource.getTenantByUserId(userId);
      if (tenant == null) {
        return Left(ServerFailure('No active tenancy found'));
      }
      return Right(tenant);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Tenant>> createTenant(Tenant tenant) async {
    try {
      final tenantModel = TenantModel(
        id: tenant.id,
        roomId: tenant.roomId,
        userId: tenant.userId,
        startDate: tenant.startDate,
        endDate: tenant.endDate,
        depositAmount: tenant.depositAmount,
        depositPaidDate: tenant.depositPaidDate,
        depositReceiver: tenant.depositReceiver,
        contractFile: tenant.contractFile,
        isActive: tenant.isActive,
        createdAt: tenant.createdAt,
        updatedAt: tenant.updatedAt,
      );
      final newTenant = await remoteDataSource.createTenant(tenantModel);
      return Right(newTenant);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Tenant>> updateTenant(Tenant tenant) async {
    try {
      final tenantModel = TenantModel(
        id: tenant.id,
        roomId: tenant.roomId,
        userId: tenant.userId,
        startDate: tenant.startDate,
        endDate: tenant.endDate,
        depositAmount: tenant.depositAmount,
        depositPaidDate: tenant.depositPaidDate,
        depositReceiver: tenant.depositReceiver,
        contractFile: tenant.contractFile,
        isActive: tenant.isActive,
        createdAt: tenant.createdAt,
        updatedAt: tenant.updatedAt,
      );
      final updatedTenant = await remoteDataSource.updateTenant(tenantModel);
      return Right(updatedTenant);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> endTenancy(
    String tenantId,
    DateTime endDate,
  ) async {
    try {
      await remoteDataSource.endTenancy(tenantId, endDate);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Tenant>>> getActiveTenants() async {
    try {
      final tenants = await remoteDataSource.getActiveTenants();
      return Right(tenants);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
