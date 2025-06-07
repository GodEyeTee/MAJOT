import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/tenant_repository.dart';

class EndTenancy implements UseCase<void, EndTenancyParams> {
  final TenantRepository repository;

  EndTenancy(this.repository);

  @override
  Future<Either<Failure, void>> call(EndTenancyParams params) async {
    return await repository.endTenancy(params.tenantId, params.endDate);
  }
}

class EndTenancyParams extends Equatable {
  final String tenantId;
  final DateTime endDate;

  const EndTenancyParams({required this.tenantId, required this.endDate});

  @override
  List<Object> get props => [tenantId, endDate];
}
