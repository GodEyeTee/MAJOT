import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/bill.dart';
import '../../repositories/bill_repository.dart';

class GetBillsByTenant implements UseCase<List<Bill>, String> {
  final BillRepository repository;

  GetBillsByTenant(this.repository);

  @override
  Future<Either<Failure, List<Bill>>> call(String tenantId) async {
    return await repository.getBillsByTenant(tenantId);
  }
}
