import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/meter_reading.dart';
import '../../repositories/meter_repository.dart';

class GetLatestReading implements UseCase<MeterReading?, String> {
  final MeterRepository repository;

  GetLatestReading(this.repository);

  @override
  Future<Either<Failure, MeterReading?>> call(String roomId) async {
    final result = await repository.getLatestReading(roomId);
    return result.fold((failure) => Left(failure), (reading) => Right(reading));
  }
}
