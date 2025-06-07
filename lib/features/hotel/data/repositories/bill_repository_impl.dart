import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_data_source.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource remoteDataSource;

  BillRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Bill>>> getBills() async {
    try {
      final bills = await remoteDataSource.getBills();
      return Right(bills);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Bill>> getBill(String id) async {
    try {
      final bill = await remoteDataSource.getBill(id);
      return Right(bill);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByTenant(String tenantId) async {
    try {
      final bills = await remoteDataSource.getBillsByTenant(tenantId);
      return Right(bills);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByRoom(String roomId) async {
    try {
      final bills = await remoteDataSource.getBillsByRoom(roomId);
      return Right(bills);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Bill>> createBill(Bill bill) async {
    try {
      final billModel = BillModel(
        id: bill.id,
        tenantId: bill.tenantId,
        roomId: bill.roomId,
        billMonth: bill.billMonth,
        roomRent: bill.roomRent,
        waterUnits: bill.waterUnits,
        waterAmount: bill.waterAmount,
        electricityUnits: bill.electricityUnits,
        electricityAmount: bill.electricityAmount,
        commonFee: bill.commonFee,
        lateFee: bill.lateFee,
        totalAmount: bill.totalAmount,
        paymentStatus: bill.paymentStatus,
        paymentDate: bill.paymentDate,
        dueDate: bill.dueDate,
        notes: bill.notes,
        createdAt: bill.createdAt,
        updatedAt: bill.updatedAt,
      );
      final newBill = await remoteDataSource.createBill(billModel);
      return Right(newBill);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Bill>> updateBill(Bill bill) async {
    try {
      final billModel = BillModel(
        id: bill.id,
        tenantId: bill.tenantId,
        roomId: bill.roomId,
        billMonth: bill.billMonth,
        roomRent: bill.roomRent,
        waterUnits: bill.waterUnits,
        waterAmount: bill.waterAmount,
        electricityUnits: bill.electricityUnits,
        electricityAmount: bill.electricityAmount,
        commonFee: bill.commonFee,
        lateFee: bill.lateFee,
        totalAmount: bill.totalAmount,
        paymentStatus: bill.paymentStatus,
        paymentDate: bill.paymentDate,
        dueDate: bill.dueDate,
        notes: bill.notes,
        createdAt: bill.createdAt,
        updatedAt: bill.updatedAt,
      );
      final updatedBill = await remoteDataSource.updateBill(billModel);
      return Right(updatedBill);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Bill>>> getUnpaidBills() async {
    try {
      final bills = await remoteDataSource.getUnpaidBills();
      return Right(bills);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Bill>>> getOverdueBills() async {
    try {
      final bills = await remoteDataSource.getOverdueBills();
      return Right(bills);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> calculateBill(
    String tenantId,
    DateTime month,
  ) async {
    try {
      final calculation = await remoteDataSource.calculateBill(tenantId, month);
      return Right(calculation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
