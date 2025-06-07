import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/meter_reading.dart';
import '../../../domain/usecases/meter/get_latest_reading.dart';
import '../../../domain/usecases/meter/save_meter_reading.dart';

part 'meter_event.dart';
part 'meter_state.dart';

class MeterBloc extends Bloc<MeterEvent, MeterState> {
  final GetLatestReading getLatestReading;
  final SaveMeterReading saveMeterReading;

  MeterBloc({required this.getLatestReading, required this.saveMeterReading})
    : super(MeterInitial()) {
    on<LoadLatestReadingEvent>(_onLoadLatestReading);
    on<SaveMeterReadingEvent>(_onSaveMeterReading);
  }

  Future<void> _onLoadLatestReading(
    LoadLatestReadingEvent event,
    Emitter<MeterState> emit,
  ) async {
    emit(MeterLoading());

    final result = await getLatestReading(event.roomId);

    result.fold(
      (failure) => emit(MeterError(failure.message)),
      (reading) => emit(MeterLoaded(reading)),
    );
  }

  Future<void> _onSaveMeterReading(
    SaveMeterReadingEvent event,
    Emitter<MeterState> emit,
  ) async {
    emit(MeterSaving());

    final result = await saveMeterReading(
      SaveMeterReadingParams(reading: event.reading),
    );

    result.fold(
      (failure) => emit(MeterError(failure.message)),
      (reading) => emit(MeterSaved(reading)),
    );
  }
}
