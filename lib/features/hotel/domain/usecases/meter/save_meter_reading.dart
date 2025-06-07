import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/meter_reading.dart';
import '../../repositories/meter_repository.dart';

class SaveMeterReading
    implements UseCase<MeterReading, SaveMeterReadingParams> {
  final MeterRepository repository;

  SaveMeterReading(this.repository);

  @override
  Future<Either<Failure, MeterReading>> call(
    SaveMeterReadingParams params,
  ) async {
    return await repository.createReading(params.reading);
  }
}

class SaveMeterReadingParams extends Equatable {
  final MeterReading reading;

  const SaveMeterReadingParams({required this.reading});

  @override
  List<Object> get props => [reading];
}
