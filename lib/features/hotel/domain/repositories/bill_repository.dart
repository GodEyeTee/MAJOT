import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bill.dart';

abstract class BillRepository {
  Future<Either<Failure, List<Bill>>> getBills();
  Future<Either<Failure, Bill>> getBill(String id);
  Future<Either<Failure, List<Bill>>> getBillsByTenant(String tenantId);
  Future<Either<Failure, List<Bill>>> getBillsByRoom(String roomId);
  Future<Either<Failure, Bill>> createBill(Bill bill);
  Future<Either<Failure, Bill>> updateBill(Bill bill);
  Future<Either<Failure, List<Bill>>> getUnpaidBills();
  Future<Either<Failure, List<Bill>>> getOverdueBills();
  Future<Either<Failure, Map<String, dynamic>>> calculateBill(
    String tenantId,
    DateTime month,
  );
}
