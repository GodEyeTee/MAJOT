import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/meter_reading.dart';

abstract class MeterRepository {
  Future<Either<Failure, List<MeterReading>>> getMeterReadings(String roomId);
  Future<Either<Failure, MeterReading>> getLatestReading(String roomId);
  Future<Either<Failure, MeterReading>> createReading(MeterReading reading);
  Future<Either<Failure, List<MeterReading>>> getReadingsByMonth(
    DateTime month,
  );
  Future<Either<Failure, MeterReading?>> getReadingForMonth(
    String roomId,
    DateTime month,
  );
}
