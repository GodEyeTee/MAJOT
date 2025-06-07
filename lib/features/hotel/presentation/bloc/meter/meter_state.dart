part of 'meter_bloc.dart';

abstract class MeterState extends Equatable {
  const MeterState();

  @override
  List<Object?> get props => [];
}

class MeterInitial extends MeterState {}

class MeterLoading extends MeterState {}

class MeterSaving extends MeterState {}

class MeterLoaded extends MeterState {
  final MeterReading? latestReading;

  const MeterLoaded(this.latestReading);

  @override
  List<Object?> get props => [latestReading];
}

class MeterSaved extends MeterState {
  final MeterReading reading;

  const MeterSaved(this.reading);

  @override
  List<Object> get props => [reading];
}

class MeterError extends MeterState {
  final String message;

  const MeterError(this.message);

  @override
  List<Object> get props => [message];
}
