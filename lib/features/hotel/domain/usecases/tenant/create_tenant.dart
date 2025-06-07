import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/tenant.dart';
import '../../repositories/tenant_repository.dart';

class CreateTenant implements UseCase<Tenant, CreateTenantParams> {
  final TenantRepository repository;

  CreateTenant(this.repository);

  @override
  Future<Either<Failure, Tenant>> call(CreateTenantParams params) async {
    return await repository.createTenant(params.tenant);
  }
}

class CreateTenantParams extends Equatable {
  final Tenant tenant;

  const CreateTenantParams({required this.tenant});

  @override
  List<Object> get props => [tenant];
}
