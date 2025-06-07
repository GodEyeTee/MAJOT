import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/meter_reading.dart';
import '../../domain/repositories/meter_repository.dart';
import '../datasources/meter_remote_data_source.dart';
import '../models/meter_reading_model.dart';

class MeterRepositoryImpl implements MeterRepository {
  final MeterRemoteDataSource remoteDataSource;

  MeterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MeterReading>>> getMeterReadings(
    String roomId,
  ) async {
    try {
      final readings = await remoteDataSource.getMeterReadings(roomId);
      return Right(readings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, MeterReading>> getLatestReading(String roomId) async {
    try {
      final reading = await remoteDataSource.getLatestReading(roomId);
      return Right(reading!);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, MeterReading>> createReading(
    MeterReading reading,
  ) async {
    try {
      final readingModel = MeterReadingModel(
        id: reading.id,
        roomId: reading.roomId,
        tenantId: reading.tenantId,
        readingMonth: reading.readingMonth,
        waterUnits: reading.waterUnits,
        electricityUnits: reading.electricityUnits,
        recordedBy: reading.recordedBy,
        createdAt: reading.createdAt,
      );
      final newReading = await remoteDataSource.createReading(readingModel);
      return Right(newReading);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<MeterReading>>> getReadingsByMonth(
    DateTime month,
  ) async {
    try {
      final readings = await remoteDataSource.getReadingsByMonth(month);
      return Right(readings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, MeterReading?>> getReadingForMonth(
    String roomId,
    DateTime month,
  ) async {
    try {
      final reading = await remoteDataSource.getReadingForMonth(roomId, month);
      return Right(reading);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
