import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/bill_repository.dart';

class CalculateBill
    implements UseCase<Map<String, dynamic>, CalculateBillParams> {
  final BillRepository repository;

  CalculateBill(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    CalculateBillParams params,
  ) async {
    return await repository.calculateBill(params.tenantId, params.month);
  }
}

class CalculateBillParams extends Equatable {
  final String tenantId;
  final DateTime month;

  const CalculateBillParams({required this.tenantId, required this.month});

  @override
  List<Object> get props => [tenantId, month];
}
