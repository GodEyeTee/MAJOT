import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {}

class CameraLoading extends ScannerState {}

class CameraReady extends ScannerState {
  final CameraController controller;
  final bool isFlashOn;
  final bool isRearCamera;

  const CameraReady({
    required this.controller,
    this.isFlashOn = false,
    this.isRearCamera = true,
  });

  @override
  List<Object> get props => [controller, isFlashOn, isRearCamera];
}

class PictureTaken extends ScannerState {
  final String imagePath;

  const PictureTaken(this.imagePath);

  @override
  List<Object> get props => [imagePath];
}

class ScanProcessing extends ScannerState {}

class ScanCompleted extends ScannerState {
  final String result;

  const ScanCompleted(this.result);

  @override
  List<Object> get props => [result];
}

class ScannerError extends ScannerState {
  final String message;

  const ScannerError(this.message);

  @override
  List<Object> get props => [message];
}
