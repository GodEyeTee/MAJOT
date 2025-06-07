part of 'meter_bloc.dart';

abstract class MeterEvent extends Equatable {
  const MeterEvent();

  @override
  List<Object> get props => [];
}

class LoadLatestReadingEvent extends MeterEvent {
  final String roomId;

  const LoadLatestReadingEvent(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class SaveMeterReadingEvent extends MeterEvent {
  final MeterReading reading;

  const SaveMeterReadingEvent(this.reading);

  @override
  List<Object> get props => [reading];
}
